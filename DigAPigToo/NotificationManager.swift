//
//  NotificationManager.swift
//  DigAPigToo
//
//  Local "someone passed you on the leaderboard" alerts. Serverless: there's no backend to push,
//  so the app can only learn your rank changed when IT loads the leaderboard — in the foreground, or
//  via a best-effort Background App Refresh. Default ON (opt-out in Settings) so people discover the
//  competition; heavily throttled + coalesced so a room full of classmates studying at once can never
//  produce a flood of notifications.
//
//  REQUIRES (one-time Xcode setup, or background checks silently never run):
//   1. target → Signing & Capabilities → + Background Modes → check "Background fetch".
//   2. target → Info → add "Permitted background task scheduler identifiers"
//      (BGTaskSchedulerPermittedIdentifiers) → item: cometzfly.DigAPigToo.rankcheck
//

import Foundation
import Combine
import UserNotifications
import BackgroundTasks
import GameKit

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    /// Must match the identifier registered via `.backgroundTask(.appRefresh:)` and listed in Info.plist.
    static let bgTaskID = "cometzfly.DigAPigToo.rankcheck"

    @Published private(set) var isEnabled: Bool

    private let enabledKey = "DigAPigToo_RankAlertsEnabled"
    private let baselineKey = "DigAPigToo_RankAlertBaseline"       // rank we measure drops against
    private let lastNotifiedKey = "DigAPigToo_RankAlertLastNotified"
    /// Minimum gap between alerts — the core anti-spam guard. A drop of several places between checks
    /// collapses into ONE "N classmates passed you" alert rather than one per place.
    private let cooldown: TimeInterval = 2 * 60 * 60

    private init() {
        // Default ON (opt-out): treat "never set" as enabled.
        if UserDefaults.standard.object(forKey: enabledKey) == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        }
    }

    // MARK: - Settings

    func setEnabled(_ on: Bool) {
        isEnabled = on
        UserDefaults.standard.set(on, forKey: enabledKey)
        if on {
            Task { await requestAuthorization(); scheduleBackgroundCheck() }
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.bgTaskID)
        }
    }

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Ask once, in context, when an opted-in user opens the ranking screen.
    func requestAuthorizationIfEnabled() async {
        guard isEnabled else { return }
        await requestAuthorization()
    }

    // MARK: - Rank tracking

    private var baselineRank: Int {
        get { UserDefaults.standard.integer(forKey: baselineKey) }
        set { UserDefaults.standard.set(newValue, forKey: baselineKey) }
    }
    private var lastNotified: Date? {
        get { UserDefaults.standard.object(forKey: lastNotifiedKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastNotifiedKey) }
    }

    /// Record the player's current rank.
    /// • Foreground (`fromBackground == false`): they're looking at the board, so just re-baseline —
    ///   future drops are measured from what they last saw, and no alert fires.
    /// • Background: if they've slipped since the baseline, fire ONE throttled, coalesced alert.
    func recordRank(_ rank: Int, total: Int, fromBackground: Bool) {
        guard rank > 0 else { return }
        if !fromBackground {
            baselineRank = rank
            return
        }
        guard isEnabled else { baselineRank = rank; return }
        let base = baselineRank
        guard base > 0 else { baselineRank = rank; return }   // first baseline — nothing to compare yet
        if rank > base {                                      // higher number = slipped down
            if let last = lastNotified, Date().timeIntervalSince(last) < cooldown { return }
            // Whoever now occupies the positions you fell through = the player(s) who passed you.
            let passers = GameCenterManager.shared.entries
                .filter { $0.rank >= base && $0.rank < rank }
                .sorted { $0.rank < $1.rank }
                .map { $0.displayName }
            postDropNotification(passedBy: rank - base, newRank: rank, total: total, passers: passers)
            baselineRank = rank
            lastNotified = Date()
        } else if rank < base {
            baselineRank = rank                               // moved up — measure future drops from here
        }
    }

    private func postDropNotification(passedBy: Int, newRank: Int, total: Int, passers: [String]) {
        let content = UNMutableNotificationContent()
        // Name the rival(s) when we know them; fall back to a count if the names weren't loaded.
        switch passers.count {
        case 1:  content.title = "\(passers[0]) just passed you"
        case 2:  content.title = "\(passers[0]) and \(passers[1]) passed you"
        case let n where n >= 3:
            content.title = "\(passers[0]), \(passers[1]), and \(n - 2) more passed you"
        default: content.title = passedBy == 1 ? "A classmate passed you" : "\(passedBy) classmates passed you"
        }
        let place = total > 0 ? "You're now #\(newRank) of \(total). " : ""
        content.body = "\(place)Jump back in and reclaim your spot!"
        content.sound = .default
        let req = UNNotificationRequest(identifier: "rankdrop-\(Int(Date().timeIntervalSince1970))",
                                        content: content, trigger: nil)   // deliver immediately
        UNUserNotificationCenter.current().add(req)
    }

    // MARK: - Background App Refresh (best-effort)

    /// Queue the next background check. iOS decides the actual timing (and may skip it); `earliestBeginDate`
    /// is only a floor. No-op (silently) until the Background Modes capability + Info.plist id are set up.
    func scheduleBackgroundCheck() {
        guard isEnabled else { return }
        let req = BGAppRefreshTaskRequest(identifier: Self.bgTaskID)
        req.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60)
        try? BGTaskScheduler.shared.submit(req)
    }

    /// Runs when iOS grants a background-refresh window: reload the leaderboard and check for a slip.
    func handleBackgroundRefresh() async {
        scheduleBackgroundCheck()                 // always line up the next one first
        guard isEnabled else { return }
        let gc = GameCenterManager.shared
        if !gc.isAuthenticated {
            gc.authenticate()
            try? await Task.sleep(nanoseconds: 3_000_000_000)   // give a cached GC session a moment
        }
        guard gc.isAuthenticated else { return }
        await gc.loadLeaderboard(foreground: false)   // background: must NOT move the user's point-delta baseline
        if let me = gc.localEntry { recordRank(me.rank, total: gc.totalPlayers, fromBackground: true) }
    }
}
