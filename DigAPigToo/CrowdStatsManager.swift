//
//  CrowdStatsManager.swift
//  DigAPigToo
//
//  UWorld-style class crowd stats: per question, how many of the class answered it correctly, so a
//  user can see "you got this — only 38% of the class did." Fully serverless via the SAME CloudKit
//  public database the photo-contribution feature uses (iCloud.cometzfly.DigAPigToo).
//
//  Each answer anonymously bumps ONE aggregate record per question (no user identity stored). Reads
//  come from a LOCAL cache so offline users still see the last-seen numbers; a background refresh
//  updates the cache whenever online. Counts are approximate (CloudKit has no atomic increment, so
//  simultaneous writers can lose an update) — fine for a motivator, not for grading.
//
//  SETUP REQUIRED (only you can do this — like the photo "Contribution" type): deploy a record type
//  "QuestionStat" in the CloudKit Console (icloud.developer.apple.com → your container → Schema) with
//  fields: questionID (String, queryable), correct (Int/Int64), total (Int/Int64). CloudKit
//  auto-creates it in the Development environment on first write; push the schema to Production before
//  release. Until it exists, writes just fail silently and nothing shows.
//

import Foundation
import Combine
import CloudKit
import CryptoKit

@MainActor
final class CrowdStatsManager: ObservableObject {
    static let shared = CrowdStatsManager()
    /// Don't surface a percentage until a question has at least this many recorded answers.
    static let minSample = 5

    struct QStat: Codable {
        var correct: Int
        var total: Int
        var correctPct: Int { total > 0 ? Int((Double(correct) / Double(total) * 100).rounded()) : 0 }
    }

    /// Last-seen class aggregates, cached locally so offline users still see numbers; refreshed online.
    @Published private(set) var cache: [String: QStat] = [:]

    private let db = CKContainer(identifier: "iCloud.cometzfly.DigAPigToo").publicCloudDatabase
    private let recordType = "QuestionStat"
    private let cacheKey = "DigAPigToo_CrowdStatsCache"
    private let contributedKey = "DigAPigToo_CrowdContributed"
    private var inFlight: Set<String> = []   // de-dupe concurrent refreshes per question
    /// Questions this user has already counted toward, so each person is counted ONCE per question —
    /// the aggregate reflects unique students (and first-try accuracy), not how many times anyone drilled
    /// it. Persisted local-first (works offline) and mirrored to iCloud so a reinstall doesn't double-vote.
    private var contributed: Set<String> = []

    private init() { loadCache(); loadContributed() }

    /// The cached class stat for a question, once the sample is big enough to be meaningful. Also kicks
    /// off a background refresh so the cache stays current when online. Returns nil until there's data.
    func stat(for questionID: String) -> QStat? {
        refresh(questionID)
        guard let s = cache[questionID], s.total >= Self.minSample else { return nil }
        return s
    }

    /// Warm the cache for a batch of questions (e.g. a results screen) so their class percentages are
    /// ready to show. Each refresh is best-effort + de-duped; no-ops cleanly offline.
    func prefetch(_ questionIDs: [String]) {
        for id in Set(questionIDs) { refresh(id) }
    }

    /// Record one answer into the public aggregate (anonymous). Best-effort + offline-safe — with no
    /// network it silently no-ops and never blocks studying.
    func recordAnswer(questionID: String, correct: Bool) {
        // One vote per user per question: only your FIRST answer counts, so `total` is the number of
        // DIFFERENT students who've attempted it (and `correct` their first-try success), not raw volume.
        guard !contributed.contains(questionID) else { return }
        contributed.insert(questionID)          // optimistic — blocks a rapid repeat before the save lands
        saveContributed()
        Task { await bump(questionID, correct: correct) }
    }

    // MARK: - CloudKit

    private func recordID(_ questionID: String) -> CKRecord.ID {
        let hex = SHA256.hash(data: Data(questionID.utf8)).map { String(format: "%02x", $0) }.joined()
        return CKRecord.ID(recordName: "q_" + String(hex.prefix(32)))   // deterministic → all devices share one record
    }

    private func bump(_ questionID: String, correct: Bool) async {
        let id = recordID(questionID)
        do {
            let record: CKRecord
            if let existing = try? await db.record(for: id) {
                record = existing
            } else {
                record = CKRecord(recordType: recordType, recordID: id)
                record["questionID"] = questionID as CKRecordValue
            }
            let total = (record["total"] as? Int ?? 0) + 1
            let corr = (record["correct"] as? Int ?? 0) + (correct ? 1 : 0)
            record["total"] = total as CKRecordValue
            record["correct"] = corr as CKRecordValue
            _ = try await db.save(record)
            cache[questionID] = QStat(correct: corr, total: total)
            saveCache()
        } catch {
            // Offline, schema not deployed, or a save conflict: undo the optimistic mark so a later
            // (online) answer can still count this user once. Approximate by design.
            contributed.remove(questionID); saveContributed()
        }
    }

    private func refresh(_ questionID: String) {
        guard !inFlight.contains(questionID) else { return }
        inFlight.insert(questionID)
        Task {
            defer { inFlight.remove(questionID) }
            if let record = try? await db.record(for: recordID(questionID)),
               let total = record["total"] as? Int, let corr = record["correct"] as? Int {
                cache[questionID] = QStat(correct: corr, total: total)
                saveCache()
            }
        }
    }

    // MARK: - Local cache

    private func loadCache() {
        guard let d = UserDefaults.standard.data(forKey: cacheKey),
              let m = try? JSONDecoder().decode([String: QStat].self, from: d) else { return }
        cache = m
    }
    private func saveCache() {
        if let d = try? JSONEncoder().encode(cache) { UserDefaults.standard.set(d, forKey: cacheKey) }
    }

    private func loadContributed() {
        guard let d = CloudSync.localData(forKey: contributedKey),
              let a = try? JSONDecoder().decode([String].self, from: d) else { return }
        contributed = Set(a)
    }
    private func saveContributed() {
        if let d = try? JSONEncoder().encode(Array(contributed)) {
            CloudSync.setLocal(d, forKey: contributedKey); _ = CloudSync.flush()
        }
    }
}
