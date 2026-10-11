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
        // Publish our score breakdown so classmates can view it when they tap our name (independent of
        // the leaderboard submit; best-effort + offline-safe).
        PlayerProfileManager.shared.publishLocalProfile()
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
    /// `foreground` = the user is actually looking (opened a screen, tapped Refresh). Only a FOREGROUND
    /// load may move the point-delta / NEW baseline, so the reference point is always a moment the user
    /// actually saw — a best-effort background fetch they never saw can't silently shift it.
    func loadLeaderboard(foreground: Bool = true) async {
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

            // SINCE-LAST-VISIT point deltas + NEW-player flags, built for people who don't open the app
            // every day. The comparison point ("baseline") for everything you see on a given day is the
            // snapshot of scores from your PREVIOUS visit — so when you come back after a gap you get the
            // whole pile of changes since you were last here (e.g. a big "+40", several "NEW"), not just
            // today's trickle. That baseline is frozen for the day; your next visit on a LATER day promotes
            // what you're seeing now into the new baseline, and the pile starts accumulating again. A
            // player absent from your last-visit snapshot joined since → NEW. Only COMPLETE foreground
            // loads move these — a partial fetch can't poison them (which once tagged all-but-me "new"),
            // and a background load you never saw never moves your reference point.
            var baseline = loadBaseline()
            let lastSeen = loadLastSeen()
            let complete = !loaded.isEmpty && loaded.count >= min(count, 100)
            let lastDate = loadBaselineDate()
            let newDay = lastDate == nil || !Calendar.current.isDate(lastDate!, inSameDayAs: Date())
            if complete && foreground {
                // The whole class (plus you) exactly as it looks right now.
                var seen: [String: Int] = [:]
                for raw in loaded { seen[raw.player.gamePlayerID] = raw.score }
                if let l = local { seen[l.player.gamePlayerID] = l.score }
                // On a new day — or any time we don't yet have a reference — promote your LAST-VISIT scores
                // to be today's baseline, so the ENTIRE pile that built up since you were last here (what's
                // been going on while you were away, e.g. "+40", several "NEW") is already there the moment
                // you open, instead of the app only counting from this open. On a genuine first run there's
                // nothing earlier to diff against, so seed from the current scores and accrue from here.
                if newDay || baseline.isEmpty {
                    baseline = lastSeen.isEmpty ? seen : lastSeen
                    saveBaseline(baseline)
                    saveBaselineDate(Date())
                }
                // Remember what you're seeing now; it becomes the reference on your next new-day visit.
                saveLastSeen(seen)
            }
            // NEW = present now but absent from your last-visit snapshot (→ joined since). Nothing to
            // compare against on a genuine first run (empty baseline) → no deltas, no NEW.
            let hasBaseline = !baseline.isEmpty
            // First-launch / untrustworthy-baseline guard: ONLY if literally EVERY other player on the
            // board would be tagged "NEW" at once (baseline empty, stale, or poisoned to just your own ID)
            // is it bogus — then flag no one. You're always excluded (never "new" to yourself), so the
            // check is over everyone else; a real burst of sign-ups (many, but not all, are new) still
            // shows NEW. Gates ONLY the NEW label; point deltas are unaffected.
            let localID = GKLocalPlayer.local.gamePlayerID
            let others = loaded.filter { $0.player.gamePlayerID != localID }
            let newcomers = others.reduce(0) { $0 + (baseline[$1.player.gamePlayerID] == nil ? 1 : 0) }
            let canFlagNew = hasBaseline && newcomers < others.count
            func decorate(_ e: Entry) -> Entry {
                var e = e
                if let base = baseline[e.id] {
                    e.delta = e.score - base
                    e.isNew = false
                } else {
                    e.delta = nil
                    e.isNew = canFlagNew && !e.isLocalPlayer   // you're never "new" to yourself
                }
                return e
            }
            entries = loaded.map { decorate(Self.makeEntry(from: $0)) }
            localEntry = local.map { decorate(Self.makeEntry(from: $0, forcedLocal: true)) }
            statusMessage = entries.isEmpty ? "No scores yet — be the first!" : nil
        } catch {
            statusMessage = "Couldn't load leaderboard: \(error.localizedDescription)"
        }
    }

    // Persisted locally first (UserDefaults — works offline and with no iCloud account, survives
    // relaunch) and mirrored to the iCloud KVS for cross-device sync + reinstall recovery:
    //  • baseline     — the frozen comparison point for today's deltas/NEW (your last visit's scores)
    //  • baselineDate — the day that baseline belongs to (a new day promotes lastSeen → baseline)
    //  • lastSeen     — the most recent scores you actually saw; becomes the baseline on your next visit
    // _v3 keys discard the earlier daily-reset model's blobs.
    private let baselineKey = "DigAPigToo_LBBaseline_v3"
    private let baselineDateKey = "DigAPigToo_LBBaselineDate_v3"
    private let lastSeenKey = "DigAPigToo_LBLastSeen_v3"
    private let legacyBaselineKey = "DigAPigToo_LBDailyBaseline_v2"   // previous model's score snapshot
    private func decodeSnap(_ d: Data?) -> [String: Int]? {
        guard let d, let m = try? JSONDecoder().decode([String: Int].self, from: d) else { return nil }
        return m
    }
    private func loadBaseline() -> [String: Int] {
        decodeSnap(CloudSync.localData(forKey: baselineKey)) ?? [:]
    }
    private func saveBaseline(_ snap: [String: Int]) {
        CloudSync.setLocal(try? JSONEncoder().encode(snap), forKey: baselineKey); _ = CloudSync.flush()
    }
    private func loadLastSeen() -> [String: Int] {
        // Fall back to the previous build's start-of-day snapshot the first time, so existing testers get
        // a reference (and see deltas) immediately instead of waiting a day for a fresh one to accrue.
        decodeSnap(CloudSync.localData(forKey: lastSeenKey))
            ?? decodeSnap(CloudSync.data(forKey: legacyBaselineKey))
            ?? [:]
    }
    private func saveLastSeen(_ snap: [String: Int]) {
        CloudSync.setLocal(try? JSONEncoder().encode(snap), forKey: lastSeenKey); _ = CloudSync.flush()
    }
    private func loadBaselineDate() -> Date? {
        let t = CloudSync.localDouble(forKey: baselineDateKey)
        return t > 0 ? Date(timeIntervalSinceReferenceDate: t) : nil
    }
    private func saveBaselineDate(_ date: Date) {
        CloudSync.setLocal(date.timeIntervalSinceReferenceDate, forKey: baselineDateKey); _ = CloudSync.flush()
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
