//
//  OfflineImageStore.swift
//  DigAPigToo
//
//  Opt-in offline image downloads. 100% client-side, no backend: fetches the
//  app's R2 photos/slides to a local folder so the app works without Wi-Fi.
//
//  Design:
//  - Files live in Application Support/OfflineImages (NOT Caches, so iOS won't
//    purge them under storage pressure) and are excluded from iCloud/iTunes backup.
//  - The on-disk file set IS the manifest: a filename present on disk = downloaded.
//    R2 filenames are globally unique (flat bucket), so lastPathComponent is a safe
//    local name with no collisions.
//  - `loadURL(for:)` is a drop-in for `URL(string: source)` at every image load
//    site: it returns the local file when present, else the remote URL. So with
//    nothing downloaded the app behaves exactly as before (pure streaming).
//  - Opt-in and default OFF to keep the install tiny; "download all" is an explicit
//    user action. Once enabled, newly-added images are picked up on launch.
//

import Foundation
import Combine

@MainActor
final class OfflineImageStore: ObservableObject {
    static let shared = OfflineImageStore()

    // MARK: - Published UI state
    @Published private(set) var isDownloading = false
    @Published private(set) var progress: Double = 0     // 0...1 for the active run
    @Published private(set) var savedCount = 0           // image files currently on disk
    @Published private(set) var totalCount = 0           // total remote images known to the app
    @Published private(set) var bytesOnDisk: Int64 = 0
    @Published private(set) var lastRunFailures = 0      // images that failed in the last run
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey) }
    }

    private static let enabledKey = "DigAPigToo_OfflineImagesEnabled"
    private let dir: URL
    private var downloadTask: Task<Void, Never>?

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        dir = base.appendingPathComponent("OfflineImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        excludeFromBackup()
        refreshUsage()
    }

    // MARK: - Path resolution (used by the image views)

    private func filename(for source: String) -> String {
        URL(string: source)?.lastPathComponent ?? source
    }

    /// The on-disk file for `source`, or nil if it hasn't been downloaded.
    func localURL(for source: String) -> URL? {
        let url = dir.appendingPathComponent(filename(for: source))
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Drop-in replacement for `URL(string: source)`: the downloaded file when it
    /// exists, otherwise the original remote URL.
    func loadURL(for source: String) -> URL? {
        localURL(for: source) ?? URL(string: source)
    }

    func hasLocal(_ source: String) -> Bool { localURL(for: source) != nil }

    // MARK: - Enumerate every remote image the app references

    func allRemoteSources() -> [String] {
        let dm = AnatomyDataManager.shared
        var set = Set<String>()
        for s in dm.structures { for img in s.images where img.isRemote { set.insert(img.source) } }
        for g in dm.diagramGroups { for img in g.images where img.isRemote { set.insert(img.source) } }
        return Array(set)
    }

    // MARK: - Download control

    /// Explicit user action: opt in and fetch everything not already on disk.
    func downloadAll() {
        isEnabled = true
        startDownload(sources: allRemoteSources())
    }

    /// Launch-time staleness refresh: if the user opted in, quietly fetch any
    /// newly-added images that aren't on disk yet.
    func fetchMissingIfEnabled() {
        guard isEnabled, !isDownloading else { return }
        startDownload(sources: allRemoteSources())
    }

    func cancelDownload() { downloadTask?.cancel() }

    private func startDownload(sources: [String]) {
        guard !isDownloading else { return }
        totalCount = sources.count
        let missing = sources.filter { !hasLocal($0) }
        lastRunFailures = 0
        guard !missing.isEmpty else { refreshUsage(); return }
        isDownloading = true
        progress = 0
        let dir = self.dir
        downloadTask = Task { [weak self] in
            await self?.run(missing: missing, dir: dir)
        }
    }

    private func run(missing: [String], dir: URL) async {
        let total = missing.count
        var processed = 0
        var failures = 0
        let maxConcurrent = 5
        var i = 0
        while i < total {
            if Task.isCancelled { break }
            let batch = Array(missing[i..<min(i + maxConcurrent, total)])
            i += batch.count
            // Fetch this batch concurrently. The group body only returns results —
            // it never touches actor state — so isolation stays simple.
            let results: [Bool] = await withTaskGroup(of: Bool.self) { group -> [Bool] in
                for src in batch { group.addTask { await Self.fetch(src, into: dir) } }
                var out: [Bool] = []
                for await r in group { out.append(r) }
                return out
            }
            processed += results.count
            failures += results.filter { !$0 }.count
            progress = Double(processed) / Double(total)
            if (i / maxConcurrent) % 5 == 0 { refreshUsage() }
        }
        lastRunFailures = failures
        isDownloading = false
        progress = 0
        refreshUsage()
    }

    /// Downloads one image to `dir`. Runs off the main actor (nonisolated) and
    /// touches no shared state, so it's safe to run many at once.
    nonisolated private static func fetch(_ source: String, into dir: URL) async -> Bool {
        guard let remote = URL(string: source) else { return false }
        let dest = dir.appendingPathComponent(remote.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) { return true }
        do {
            let (tmp, response) = try await URLSession.shared.download(from: remote)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                try? FileManager.default.removeItem(at: tmp)
                return false
            }
            if FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.moveItem(at: tmp, to: dest)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Delete + usage

    func deleteAll() {
        cancelDownload()
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        excludeFromBackup()
        isEnabled = false
        refreshUsage()
    }

    func refreshUsage() {
        let fm = FileManager.default
        var count = 0
        var bytes: Int64 = 0
        if let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey]) {
            for item in items {
                count += 1
                if let size = try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    bytes += Int64(size)
                }
            }
        }
        savedCount = count
        bytesOnDisk = bytes
        if totalCount == 0 { totalCount = allRemoteSources().count }
    }

    private func excludeFromBackup() {
        var url = dir
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }
}
