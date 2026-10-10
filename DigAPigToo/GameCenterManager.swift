//
//  GameCenterManager.swift
//  DigAPigToo
//
//  Uses Game Center purely as a serverless backend for a custom, in-app leaderboard: it signs the
//  player in, submits their mastery score, and loads other players' entries — which the app renders
//  in its own UI (LeaderboardView). Players never have to touch the Game Center overlay.
//
//  SETUP REQUIRED (only you can do these — see the notes in LeaderboardView / the chat):
//   1. Xcode → target → Signing & Capabilities → + Capability → Game Center.
//   2. App Store Connect → your app → Services → Game Center → add a Leaderboard.
//      • Type: Classic. • Score format: Integer. • Sort: High to Low.
//      • Submission: "Most Recent Score" (so rank reflects CURRENT mastery, which can move).
//      • Copy its Leaderboard ID into `leaderboardID` below.
//   3. Build on a device/simulator signed into Game Center.
//

import Foundation
import Combine
import GameKit
import UIKit

@MainActor
final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    /// MUST match the Leaderboard ID you create in App Store Connect.
    static let leaderboardID = "cometzfly.DigAPigToo.mastery"

    struct Entry: Identifiable {
        let id: String          // gamePlayerID (stable per player, per game)
        let rank: Int
        let displayName: String
        let score: Int
        let isLocalPlayer: Bool
        var delta: Int? = nil   // points changed since this device last loaded the board (nil = new/unknown)
        var isNew: Bool = false // joined the class leaderboard since today's start-of-day snapshot
    }

    /// Achievement IDs — create matching achievements in App Store Connect (see setup notes below).
    /// Half achievements complete at 50% mastery of a domain; "All" at 100%.
    enum Achievement: String, CaseIterable {
        case firstMastery = "cometzfly.DigAPigToo.ach.firstmastery"
        case idsHalf      = "cometzfly.DigAPigToo.ach.ids50"
        case idsAll       = "cometzfly.DigAPigToo.ach.ids100"
        case tracesHalf   = "cometzfly.DigAPigToo.ach.traces50"
        case tracesAll    = "cometzfly.DigAPigToo.ach.traces100"
        case fillsHalf    = "cometzfly.DigAPigToo.ach.fills50"
        case fillsAll     = "cometzfly.DigAPigToo.ach.fills100"
        case contributor  = "cometzfly.DigAPigToo.ach.contributor"
    }

    @Published private(set) var isAuthenticated = false
    @Published private(set) var localAlias = ""
    @Published private(set) var entries: [Entry] = []
    @Published private(set) var localEntry: Entry?
    @Published private(set) var totalPlayers = 0
    @Published private(set) var isLoading = false
    @Published private(set) var statusMessage: String?

    private var didSetHandler = false

    private init() {}

    /// Silent Game Center sign-in; Apple's sheet appears only when the player must act.
    func authenticate() {
        guard !didSetHandler else { return }
        didSetHandler = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    Self.topViewController()?.present(viewController, animated: true)
                    return
                }
                if let error {
                    self.statusMessage = "Game Center: \(error.localizedDescription)"
                    self.isAuthenticated = false
                    return
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.localAlias = GKLocalPlayer.local.alias
                if self.isAuthenticated {
                    self.statusMessage = nil
                    await self.submitCurrentScore()
                    await self.loadLeaderboard()
                }
            }
        }
    }

    /// Push the current local mastery score to Game Center.
    func submitCurrentScore() async {
        guard isAuthenticated else { return }
        let score = MasteryScore.current().score
        do {
            try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                                leaderboardIDs: [Self.leaderboardID])
        } catch {
            statusMessage = "Couldn't submit score: \(error.localizedDescription)"
        }
    }

    /// Refresh: resubmit the latest score, report milestone achievements, reload the ranked entries.
    func refresh() async {
        await submitCurrentScore()
        await reportAchievements()
        await loadLeaderboard()
        // Foreground view: re-baseline the rank so "someone passed you" alerts are measured from
        // what the user just saw (no alert fires here).
        if let me = localEntry {
            NotificationManager.shared.recordRank(me.rank, total: totalPlayers, fromBackground: false)
        }
    }

    /// Report milestone achievements based on current mastery. Game Center keeps the highest
    /// percent ever reported, so achievements never un-earn even if mastery later dips.
    func reportAchievements() async {
        guard isAuthenticated else { return }
        let m = MasteryScore.current()
        var list: [GKAchievement] = []
        func add(_ id: String, percent: Double) {
            guard percent > 0 else { return }
            let a = GKAchievement(identifier: id)
            a.percentComplete = min(100, percent)
            a.showsCompletionBanner = true
            list.append(a)
        }
        let totalMastered = m.idMastered + m.traceMastered + m.fillMastered
        add(Achievement.firstMastery.rawValue, percent: totalMastered > 0 ? 100 : 0)
        add(Achievement.idsHalf.rawValue,    percent: m.idFrac / 0.5 * 100)
        add(Achievement.idsAll.rawValue,     percent: m.idFrac * 100)
        add(Achievement.tracesHalf.rawValue, percent: m.traceFrac / 0.5 * 100)
        add(Achievement.tracesAll.rawValue,  percent: m.traceFrac * 100)
        add(Achievement.fillsHalf.rawValue,  percent: m.fillFrac / 0.5 * 100)
        add(Achievement.fillsAll.rawValue,   percent: m.fillFrac * 100)
        if ContributionManager.hasContributed { add(Achievement.contributor.rawValue, percent: 100) }
        guard !list.isEmpty else { return }
        do { try await GKAchievement.report(list) }
        catch { statusMessage = "Couldn't report achievements: \(error.localizedDescription)" }
    }

    /// Load the top entries + the local player's entry for the in-app leaderboard.
    func loadLeaderboard() async {
        guard isAuthenticated else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID])
            guard let board = boards.first else {
                statusMessage = "Leaderboard not found — check the leaderboard ID in App Store Connect."
                return
            }
            // 100 = Game Center's max per load. Covers the whole class so "N competing" matches the
            // list; if it ever grows past 100, this would need paging.
            let (local, loaded, count) = try await board.loadEntries(
                for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 100))
            totalPlayers = count

            // DAILY point deltas (vs a start-of-day baseline) + NEW-player detection. Both only update
            // from a COMPLETE load — one where we actually fetched the whole class — so a partial Game
            // Center fetch can never poison them (which once tagged all-but-me "new"). On the first
            // complete load of the day we snapshot everyone (no one is new yet, deltas start at 0); on
            // later complete loads, any player NOT in that snapshot joined today → NEW, and anyone's
            // delta = current − their snapshot score. Resets at local midnight.
            var baseline = loadBaseline()
            var newToday = loadNewToday()
            let complete = !loaded.isEmpty && loaded.count >= min(count, 100)
            let lastDate = loadBaselineDate()
            let newDay = lastDate == nil || !Calendar.current.isDate(lastDate!, inSameDayAs: Date())
            if complete {
                let wouldBeNew = loaded.reduce(0) { $0 + (baseline[$1.player.gamePlayerID] == nil ? 1 : 0) }
                // Snapshot everyone and flag NO ONE when there's nothing trustworthy to diff against:
                // a new day, an empty baseline (first launch / after a reinstall), or a suspicious mass
                // of "new" players (a baseline glitch) — never tag the whole class new.
                let freshStart = newDay || baseline.isEmpty || wouldBeNew > max(5, loaded.count / 3)
                if freshStart {
                    baseline = [:]; newToday = []
                    for raw in loaded { baseline[raw.player.gamePlayerID] = raw.score }
                    if let l = local { baseline[l.player.gamePlayerID] = l.score }
                } else {
                    for raw in loaded where baseline[raw.player.gamePlayerID] == nil {
                        newToday.insert(raw.player.gamePlayerID)    // appeared since the morning snapshot → NEW
                        baseline[raw.player.gamePlayerID] = raw.score
                    }
                    if let l = local, baseline[l.player.gamePlayerID] == nil { baseline[l.player.gamePlayerID] = l.score }
                }
                saveBaseline(baseline)
                saveNewToday(newToday)
                saveBaselineDate(Date())
            }
            func decorate(_ e: Entry) -> Entry {
                var e = e
                e.delta = baseline[e.id].map { e.score - $0 }
                e.isNew = newToday.contains(e.id)
                return e
            }
            entries = loaded.map { decorate(Self.makeEntry(from: $0)) }
            localEntry = local.map { decorate(Self.makeEntry(from: $0, forcedLocal: true)) }
            statusMessage = entries.isEmpty ? "No scores yet — be the first!" : nil
        } catch {
            statusMessage = "Couldn't load leaderboard: \(error.localizedDescription)"
        }
    }

    // Start-of-day baseline (daily point deltas) + today's new-player set + the baseline date. Stored
    // in the iCloud key-value store so they survive Xcode rebuilds / reinstalls during development (and
    // stay consistent across the user's devices); resets each day. _v2 keys discard the earlier buggy
    // build's data. (CloudSync degrades to a no-op without iCloud, which is fine.)
    private let baselineKey = "DigAPigToo_LBDailyBaseline_v2"
    private let baselineDateKey = "DigAPigToo_LBDailyBaselineDate_v2"
    private let newTodayKey = "DigAPigToo_LBNewToday_v2"
    private func loadBaseline() -> [String: Int] {
        guard let d = CloudSync.data(forKey: baselineKey),
              let m = try? JSONDecoder().decode([String: Int].self, from: d) else { return [:] }
        return m
    }
    private func saveBaseline(_ snap: [String: Int]) {
        CloudSync.set(try? JSONEncoder().encode(snap), forKey: baselineKey); _ = CloudSync.flush()
    }
    private func loadNewToday() -> Set<String> {
        guard let d = CloudSync.data(forKey: newTodayKey),
              let a = try? JSONDecoder().decode([String].self, from: d) else { return [] }
        return Set(a)
    }
    private func saveNewToday(_ s: Set<String>) {
        CloudSync.set(try? JSONEncoder().encode(Array(s)), forKey: newTodayKey); _ = CloudSync.flush()
    }
    private func loadBaselineDate() -> Date? {
        let t = CloudSync.double(forKey: baselineDateKey)
        return t > 0 ? Date(timeIntervalSinceReferenceDate: t) : nil
    }
    private func saveBaselineDate(_ date: Date) {
        CloudSync.set(date.timeIntervalSinceReferenceDate, forKey: baselineDateKey); _ = CloudSync.flush()
    }

    private static func makeEntry(from e: GKLeaderboard.Entry, forcedLocal: Bool = false) -> Entry {
        let isLocal = forcedLocal || e.player.gamePlayerID == GKLocalPlayer.local.gamePlayerID
        return Entry(id: e.player.gamePlayerID,
                     rank: e.rank,
                     displayName: e.player.displayName,
                     score: e.score,
                     isLocalPlayer: isLocal)
    }

    /// Top-most view controller, used to present the sign-in sheet from SwiftUI.
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
        var top = keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
