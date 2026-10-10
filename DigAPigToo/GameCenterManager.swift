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

            // DAILY point deltas vs a start-of-day baseline (holds all day, resets at local midnight).
            // The baseline is EXTENDED LAZILY: any player seen for the first time today is added at
            // their current score, so a newcomer — or anyone a partial earlier load missed — just
            // starts at 0 rather than being mislabeled. Everything is guarded on a NON-EMPTY load, so a
            // partial/empty fetch can never capture a bogus baseline (which once tagged all-but-me new).
            var baseline = loadBaseline()
            let lastDate = UserDefaults.standard.object(forKey: baselineDateKey) as? Date
            let newDay = lastDate == nil || !Calendar.current.isDate(lastDate!, inSameDayAs: Date())
            if newDay && !loaded.isEmpty { baseline = [:] }        // fresh start line for the new day
            var baselineChanged = newDay
            for raw in loaded where baseline[raw.player.gamePlayerID] == nil {
                baseline[raw.player.gamePlayerID] = raw.score; baselineChanged = true
            }
            if let l = local, baseline[l.player.gamePlayerID] == nil {
                baseline[l.player.gamePlayerID] = l.score; baselineChanged = true
            }
            if baselineChanged && !loaded.isEmpty {
                saveBaseline(baseline)
                UserDefaults.standard.set(Date(), forKey: baselineDateKey)
            }
            func withDelta(_ e: Entry) -> Entry {
                var e = e
                e.delta = baseline[e.id].map { e.score - $0 }
                return e
            }
            entries = loaded.map { withDelta(Self.makeEntry(from: $0)) }
            localEntry = local.map { withDelta(Self.makeEntry(from: $0, forcedLocal: true)) }
            statusMessage = entries.isEmpty ? "No scores yet — be the first!" : nil
        } catch {
            statusMessage = "Couldn't load leaderboard: \(error.localizedDescription)"
        }
    }

    // Start-of-day baseline for the leaderboard's daily point deltas (device-local; resets each day).
    // _v2 keys discard any baseline captured by the earlier buggy build (which could poison it to
    // "only me") so devices start clean.
    private let baselineKey = "DigAPigToo_LBDailyBaseline_v2"
    private let baselineDateKey = "DigAPigToo_LBDailyBaselineDate_v2"
    private func loadBaseline() -> [String: Int] {
        (UserDefaults.standard.dictionary(forKey: baselineKey) ?? [:]).compactMapValues { $0 as? Int }
    }
    private func saveBaseline(_ snap: [String: Int]) {
        UserDefaults.standard.set(snap, forKey: baselineKey)
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
