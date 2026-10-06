//
//  DigAPigTooApp.swift
//  DigAPigToo
//
//  Created by Alexander Knue on 5/8/26.
//

import SwiftUI

@main
struct DigAPigTooApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, phase in
                    // Queue the next leaderboard rank check whenever we go to the background.
                    if phase == .background { NotificationManager.shared.scheduleBackgroundCheck() }
                }
        }
        // Best-effort background check for "a classmate passed you" alerts. Fires only once the
        // Background Modes capability + the matching Info.plist identifier are set up (see
        // NotificationManager); until then this is a harmless no-op.
        .backgroundTask(.appRefresh(NotificationManager.bgTaskID)) {
            await NotificationManager.shared.handleBackgroundRefresh()
        }
    }
}
