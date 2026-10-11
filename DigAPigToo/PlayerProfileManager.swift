//
//  PlayerProfileManager.swift
//  DigAPigToo
//
//  Lets a player tap a name on the leaderboard and see that classmate's score BREAKDOWN (Physical IDs
//  / Traces / Fill-ins / Practice points) plus how long they've been studying. Game Center only hands
//  us another player's name + single total score, so the breakdown can't come from there — instead each
//  player publishes a tiny public "profile" record to the SAME CloudKit public database the crowd stats
//  and photo contributions use (iCloud.cometzfly.DigAPigToo), keyed by a hash of their Game Center ID so
//  there's exactly one record per person. Tapping a name fetches that one record directly (no query).
//
//  `firstSeen` is stamped ONCE and never overwritten, so "member since" is honest going forward (for
//  everyone who joins after this feature ships; existing users read as joining when they first update).
//
//  SETUP REQUIRED (only you can do this — like the QuestionStat type): deploy a record type
//  "PlayerProfile" in the CloudKit Console (your container → Schema) with fields:
//    playerID (String, queryable), displayName (String),
//    score, idPts, tracePts, fillPts, practicePts, idMastered, traceMastered, fillMastered (Int/Int64),
//    firstSeen (Date/Time), lastActive (Date/Time).
//  CloudKit auto-creates it in Development on first write; push to Production before release. Until it
//  exists, writes fail silently and tapping a name just shows "no details yet".
//

import Foundation
import Combine
import CloudKit
import CryptoKit
import GameKit

@MainActor
final class PlayerProfileManager: ObservableObject {
    static let shared = PlayerProfileManager()

    struct Profile: Codable, Identifiable {
        var playerID: String
        var displayName: String
        var score: Int
        var idPts: Int, tracePts: Int, fillPts: Int, practicePts: Int
        var idMastered: Int, traceMastered: Int, fillMastered: Int
        var firstSeen: Date
        var lastActive: Date
        var id: String { playerID }
    }

    /// Last-seen profiles, cached locally so a tapped classmate still shows (last numbers) when offline.
    @Published private(set) var cache: [String: Profile] = [:]
    /// Profiles currently being fetched — drives the loading spinner in the sheet.
    @Published private(set) var fetching: Set<String> = []

    private let db = CKContainer(identifier: "iCloud.cometzfly.DigAPigToo").publicCloudDatabase
    private let recordType = "PlayerProfile"
    private let cacheKey = "DigAPigToo_PlayerProfileCache"
    private let firstSeenKey = "DigAPigToo_ProfileFirstSeen"   // local copy of OUR own firstSeen

    private init() { loadCache() }

    // MARK: - Reads

    /// The profile to show for a leaderboard entry. For YOU it's built instantly from local data (works
    /// offline, always current); for anyone else it's the cached CloudKit copy (nil until fetched).
    func profile(for entry: GameCenterManager.Entry) -> Profile? {
        entry.isLocalPlayer ? localProfile() : cache[entry.id]
    }

    /// Kick off a background fetch of a classmate's profile (no-op for the local player, whose data is
    /// always local). De-duped per player.
    func fetch(_ entry: GameCenterManager.Entry) {
        let id = entry.id
        guard !entry.isLocalPlayer, !fetching.contains(id) else { return }
        fetching.insert(id)
        Task {
            defer { fetching.remove(id) }
            if let rec = try? await db.record(for: recordID(id)), let p = Self.profile(from: rec) {
                cache[id] = p
                saveCache()
            }
        }
    }

    /// Build the local player's profile straight from their mastery score (instant, offline-safe).
    func localProfile() -> Profile {
        let m = MasteryScore.current()
        return Profile(playerID: GKLocalPlayer.local.gamePlayerID,
                       displayName: GKLocalPlayer.local.displayName,
                       score: m.score,
                       idPts: m.idPoints, tracePts: m.tracePoints,
                       fillPts: m.fillPoints, practicePts: m.performancePoints,
                       idMastered: m.idMastered, traceMastered: m.traceMastered, fillMastered: m.fillMastered,
                       firstSeen: ownFirstSeen(), lastActive: Date())
    }

    // MARK: - Publish (our own profile)

    /// Publish the local player's current breakdown to the public DB so classmates can view it. Best-effort
    /// + offline-safe. Call whenever the score is submitted.
    func publishLocalProfile() { Task { await publish() } }

    private func publish() async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let m = MasteryScore.current()
        let id = GKLocalPlayer.local.gamePlayerID
        let name = GKLocalPlayer.local.displayName
        do {
            let record: CKRecord
            if let existing = try? await db.record(for: recordID(id)) {
                record = existing
            } else {
                record = CKRecord(recordType: recordType, recordID: recordID(id))
            }
            // Stamp firstSeen exactly once (preserve whatever's already there).
            let firstSeen = (record["firstSeen"] as? Date) ?? Date()
            record["firstSeen"] = firstSeen as CKRecordValue
            record["playerID"] = id as CKRecordValue
            record["displayName"] = name as CKRecordValue
            record["score"] = m.score as CKRecordValue
            record["idPts"] = m.idPoints as CKRecordValue
            record["tracePts"] = m.tracePoints as CKRecordValue
            record["fillPts"] = m.fillPoints as CKRecordValue
            record["practicePts"] = m.performancePoints as CKRecordValue
            record["idMastered"] = m.idMastered as CKRecordValue
            record["traceMastered"] = m.traceMastered as CKRecordValue
            record["fillMastered"] = m.fillMastered as CKRecordValue
            record["lastActive"] = Date() as CKRecordValue
            _ = try await db.save(record)
            UserDefaults.standard.set(firstSeen.timeIntervalSinceReferenceDate, forKey: firstSeenKey)
            if let p = Self.profile(from: record) { cache[id] = p; saveCache() }
        } catch {
            // Offline, schema not deployed, or a save conflict — ignore (best-effort by design).
        }
    }

    // MARK: - CloudKit plumbing

    private func recordID(_ playerID: String) -> CKRecord.ID {
        let hex = SHA256.hash(data: Data(playerID.utf8)).map { String(format: "%02x", $0) }.joined()
        return CKRecord.ID(recordName: "p_" + String(hex.prefix(32)))   // deterministic → one record per player
    }

    private static func profile(from r: CKRecord) -> Profile? {
        guard let playerID = r["playerID"] as? String else { return nil }
        return Profile(playerID: playerID,
                       displayName: (r["displayName"] as? String) ?? "Player",
                       score: (r["score"] as? Int) ?? 0,
                       idPts: (r["idPts"] as? Int) ?? 0,
                       tracePts: (r["tracePts"] as? Int) ?? 0,
                       fillPts: (r["fillPts"] as? Int) ?? 0,
                       practicePts: (r["practicePts"] as? Int) ?? 0,
                       idMastered: (r["idMastered"] as? Int) ?? 0,
                       traceMastered: (r["traceMastered"] as? Int) ?? 0,
                       fillMastered: (r["fillMastered"] as? Int) ?? 0,
                       firstSeen: (r["firstSeen"] as? Date) ?? Date(),
                       lastActive: (r["lastActive"] as? Date) ?? Date())
    }

    private func ownFirstSeen() -> Date {
        let t = UserDefaults.standard.double(forKey: firstSeenKey)
        return t > 0 ? Date(timeIntervalSinceReferenceDate: t) : Date()
    }

    // MARK: - Local cache

    private func loadCache() {
        guard let d = UserDefaults.standard.data(forKey: cacheKey),
              let m = try? JSONDecoder().decode([String: Profile].self, from: d) else { return }
        cache = m
    }
    private func saveCache() {
        if let d = try? JSONEncoder().encode(cache) { UserDefaults.standard.set(d, forKey: cacheKey) }
    }
}
