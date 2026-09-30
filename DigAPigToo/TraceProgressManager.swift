//
//  TraceProgressManager.swift
//  DigAPigToo
//
//  Per-trace practice progress + a "mastered" signal, so traces can contribute to the overall
//  mastery score (they weigh ~22% of the practical). Keyed by the trace TITLE (stable across
//  launches, unlike the runtime UUID). Persists to UserDefaults and mirrors to iCloud, like the
//  other progress managers.
//

import Foundation
import Combine

@MainActor
final class TraceProgressManager: ObservableObject {
    static let shared = TraceProgressManager()

    struct TProgress: Codable {
        var attempts: Int = 0            // total practice runs
        var bestCorrect: Int = 0         // most steps recalled in a single run
        var reps: Int = 0                // consecutive PERFECT runs (all steps correct)
        var lastPracticed: Date = .distantPast

        init() {}
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            attempts = try c.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
            bestCorrect = try c.decodeIfPresent(Int.self, forKey: .bestCorrect) ?? 0
            reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 0
            lastPracticed = try c.decodeIfPresent(Date.self, forKey: .lastPracticed) ?? .distantPast
        }
    }

    @Published private(set) var progress: [String: TProgress] = [:]

    private let masterReps = 2          // two perfect runs → mastered
    private let udKey = "DigAPigToo_TraceProgress"

    private init() {
        load()
        mergeFromCloud()
        CloudSync.observe { [weak self] in Task { @MainActor in self?.mergeFromCloud() } }
    }

    func entry(for title: String) -> TProgress { progress[title] ?? TProgress() }
    func isMastered(_ title: String) -> Bool { (progress[title]?.reps ?? 0) >= masterReps }

    /// Record a completed practice run. A "perfect" run (every step recalled) builds the mastery
    /// streak; any miss resets it.
    func record(title: String, correct: Int, total: Int) {
        var p = progress[title] ?? TProgress()
        p.attempts += 1
        p.bestCorrect = max(p.bestCorrect, correct)
        p.reps = (total > 0 && correct >= total) ? p.reps + 1 : 0
        p.lastPracticed = Date()
        progress[title] = p
        save()
    }

    /// Mastered-trace count over a set of traces, for the mastery score / stats.
    func masteredCount(in traces: [TraceQuestion]) -> Int {
        traces.reduce(0) { $0 + (isMastered($1.title) ? 1 : 0) }
    }

    func reset() {
        progress = [:]
        UserDefaults.standard.removeObject(forKey: udKey)
        CloudSync.set(nil, forKey: udKey)
        CloudSync.flush()
    }

    func syncNow() { mergeFromCloud(); save() }

    // MARK: Persistence (local UserDefaults + iCloud key-value mirror, per-key LWW by lastPracticed)
    private func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: udKey)
        CloudSync.set(data, forKey: udKey)
        CloudSync.flush()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([String: TProgress].self, from: data) else { return }
        progress = decoded
    }

    private func mergeFromCloud() {
        guard let data = CloudSync.data(forKey: udKey),
              let cloud = try? JSONDecoder().decode([String: TProgress].self, from: data) else { return }
        var changed = false
        for (k, remote) in cloud {
            if let local = progress[k] {
                if remote.lastPracticed > local.lastPracticed { progress[k] = remote; changed = true }
            } else {
                progress[k] = remote; changed = true
            }
        }
        var cloudStale = false
        for (k, local) in progress {
            if let remote = cloud[k] { if local.lastPracticed > remote.lastPracticed { cloudStale = true; break } }
            else { cloudStale = true; break }
        }
        if changed || cloudStale { save() }
    }
}
