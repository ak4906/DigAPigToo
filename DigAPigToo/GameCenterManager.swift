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
            let (local, loaded, count) = try await board.loadEntries(
                for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 50))
            totalPlayers = count
            entries = loaded.map { Self.makeEntry(from: $0) }
            localEntry = local.map { Self.makeEntry(from: $0, forcedLocal: true) }
            statusMessage = entries.isEmpty ? "No scores yet — be the first!" : nil
        } catch {
            statusMessage = "Couldn't load leaderboard: \(error.localizedDescription)"
        }
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
