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
        // "Half / all mastered" keys off the fully-MASTERED counts (not partial credit), so the badge
        // matches the "X / Y mastered" shown on the Ranking screen.
        add(Achievement.idsHalf.rawValue,    percent: m.idMasteredFrac / 0.5 * 100)
        add(Achievement.idsAll.rawValue,     percent: m.idMasteredFrac * 100)
        add(Achievement.tracesHalf.rawValue, percent: m.traceMasteredFrac / 0.5 * 100)
        add(Achievement.tracesAll.rawValue,  percent: m.traceMasteredFrac * 100)
        add(Achievement.fillsHalf.rawValue,  percent: m.fillMasteredFrac / 0.5 * 100)
        add(Achievement.fillsAll.rawValue,   percent: m.fillMasteredFrac * 100)
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

            // DAILY point deltas (+N/−N) and NEW flags — see the persistence helpers below for storage.
            // NEW works EXACTLY like the deltas, as requested:
            //  • On the FIRST launch (before it knows anyone) it just LEARNS the current roster + scores and
            //    flags nobody / shows no deltas — like a 300-point player reading "300", not "+300".
            //  • After that, any score change shows as +N and any NAME not in the learned roster shows as
            //    NEW. Both ACCUMULATE and persist across refreshes and relaunches within the day.
            //  • At the next day's first open it resets: the delta window re-bases to ≈ the day's start and
            //    the roster folds in your previous login's players, so yesterday's deltas/NEW clear and it
            //    watches for fresh changes. Skip days → you see everything since you were last in.
            //  • Self-heal (your "if EVERYONE would be new, disregard"): if the stored roster is empty or so
            //    stale it would flag EVERY other player (e.g. it ever collapsed to just you), we re-learn the
            //    current roster and flag nobody, instead of tagging the whole class new.
            // The window + roster advance only on a COMPLETE, FOREGROUND load (a partial fetch or a
            // background refresh you never saw can't move the reference point). All of it lives in one
            // atomic-file-backed blob (see loadLBState/saveLBState) so it survives a force-quit.
            // NOTE: the delta/NEW maps are keyed by the player's Game Center NICKNAME (displayName), not
            // gamePlayerID. Game Center can re-provision a player's gamePlayerID on a fresh launch — it's
            // only guaranteed stable WITHIN a session — which made the saved window stop matching after a
            // force-quit, zeroing every delta. A nickname is stable across launches (it's what you see).
            var state = loadLBState()
            var windowStart = state.windowStart         // scores when the current day's window began
            var known = Set(state.known)                // the roster you've already "met" (→ not new)
            let lastSeen = state.lastSeen               // scores at your previous login (≈ that day's end)
            let localName = GKLocalPlayer.local.displayName
            let hasOthers = loaded.contains { $0.player.displayName != localName }
            let complete = !loaded.isEmpty && loaded.count >= min(count, 100) && (count <= 1 || hasOthers)
            let lastDay = state.cycleDay > 0 ? Date(timeIntervalSinceReferenceDate: state.cycleDay) : nil
            let newDay = lastDay == nil || !Calendar.current.isDate(lastDay!, inSameDayAs: Date())
            if complete && foreground {
                var seen: [String: Int] = [:]
                for raw in loaded { seen[raw.player.displayName] = raw.score }
                if let l = local { seen[l.player.displayName] = l.score }
                let seenNames = Set(seen.keys)
                let otherNames = seenNames.subtracting([localName])
                // Learn fresh when there's no window yet (first launch) OR the roster is bogus — empty, or
                // it would flag every single other player (collapsed / left over from an old build). Learn
                // the current roster + scores, flag nobody, and start every delta at 0.
                let rosterBogus = known.isEmpty || (!otherNames.isEmpty && otherNames.subtracting(known).count == otherNames.count)
                if windowStart.isEmpty || rosterBogus {
                    known = seenNames
                    windowStart = seen
                } else if newDay {
                    // Next-day reset: fold your previous login's players into the roster (they stop being
                    // new) and re-base the delta window to those last-seen scores (≈ the new day's start).
                    known.formUnion(Set(lastSeen.keys))
                    windowStart = lastSeen.isEmpty ? seen : lastSeen
                }
                // Otherwise (same day) the window + roster are left alone so deltas and NEW accumulate.
                // Persist everything in one durable write.
                state.windowStart = windowStart
                state.known = Array(known)
                state.lastSeen = seen
                state.cycleDay = Date().timeIntervalSinceReferenceDate
                saveLBState(state)
            }
            // NEW = players on the board not in the learned roster yet, derived live so a mid-day arrival is
            // caught at once and persists until tomorrow. Flag nobody when the roster isn't established yet,
            // or when it would flag EVERYONE (the "disregard if everyone is new" rule).
            let currentNames = Set(loaded.map { $0.player.displayName })
            let othersNow = currentNames.subtracting([localName])
            let unknownNow = othersNow.subtracting(known)
            let newToday: Set<String> = (known.isEmpty || (!othersNow.isEmpty && unknownNow.count == othersNow.count)) ? [] : unknownNow
            func decorate(_ e: Entry) -> Entry {
                var e = e
                e.delta = windowStart[e.displayName].map { e.score - $0 }   // keyed by nickname (launch-stable)
                e.isNew = newToday.contains(e.displayName) && !e.isLocalPlayer
                return e
            }
            entries = loaded.map { decorate(Self.makeEntry(from: $0)) }
            localEntry = local.map { decorate(Self.makeEntry(from: $0, forcedLocal: true)) }
            statusMessage = entries.isEmpty ? "No scores yet — be the first!" : nil
        } catch {
            statusMessage = "Couldn't load leaderboard: \(error.localizedDescription)"
        }
    }

    // All leaderboard delta/NEW state in ONE blob, persisted with an ATOMIC FILE WRITE (write-to-temp +
    // rename) so it is durable the instant it's saved and a force-quit can't drop it — the earlier
    // UserDefaults approach could lose an un-flushed write on a hard force-quit, which zeroed the deltas
    // on relaunch. Also mirrored to the iCloud KVS for cross-device sync + reinstall recovery.
    //  • windowStart — scores when the current day's delta window began (deltas = current − windowStart)
    //  • lastSeen    — scores at your most recent login; becomes the next day's windowStart
    //  • cycleDay    — the day windowStart belongs to (detects the first login of a new day)
    //  • known       — the roster you've already met; anyone not in it is flagged NEW
    private struct LBState: Codable {
        var windowStart: [String: Int] = [:]
        var lastSeen: [String: Int] = [:]
        var known: [String] = []
        var cycleDay: Double = 0
    }
    private let lbStateFile = "lb_state_v6.json"           // v6: nickname-keyed, discards old ID-keyed blobs
    private let lbStateKVSKey = "DigAPigToo_LBState_v6"

    private func lbStateURL() -> URL? {
        let fm = FileManager.default
        guard let dir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                    appropriateFor: nil, create: true) else { return nil }
        return dir.appendingPathComponent(lbStateFile)
    }
    private func loadLBState() -> LBState {
        // Durable local file first; fall back to the iCloud KVS mirror (fresh install / another device).
        if let url = lbStateURL(), let d = try? Data(contentsOf: url),
           let s = try? JSONDecoder().decode(LBState.self, from: d) { return s }
        if let d = CloudSync.data(forKey: lbStateKVSKey),
           let s = try? JSONDecoder().decode(LBState.self, from: d) { return s }
        return LBState()
    }
    private func saveLBState(_ s: LBState) {
        guard let d = try? JSONEncoder().encode(s) else { return }
        if let url = lbStateURL() { try? d.write(to: url, options: .atomic) }   // durable immediately
        CloudSync.set(d, forKey: lbStateKVSKey); _ = CloudSync.flush()          // mirror to iCloud (best-effort)
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
