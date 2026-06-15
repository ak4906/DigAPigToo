//
//  FlashcardManager.swift
//  DigAPigToo
//
//  Spaced-repetition (SRS) scheduling + persistence for the flashcard study mode.
//  Keyed by structure name (stable across launches, like StatsManager).
//
//  PERSISTENCE: currently local (UserDefaults + Codable). The storage is isolated
//  behind `load()`/`save()` so it can be swapped for SwiftData+CloudKit later to sync
//  across iPhone/iPad/Mac without touching the SRS logic or the UI.
//

import Foundation
import Combine

@MainActor
class FlashcardManager: ObservableObject {
    static let shared = FlashcardManager()

    // MARK: - SRS rating (Anki-style)
    enum Rating {
        case again   // forgot — reset
        case hard    // recalled with difficulty
        case good    // recalled
        case easy    // trivial — big jump
    }

    // MARK: - Per-card scheduling record
    struct CardSchedule: Codable {
        var ease: Double = 2.5          // ease factor (Anki default 2.5)
        var intervalDays: Double = 0    // current interval in days
        var due: Date = Date()          // next review date
        var reps: Int = 0               // successful reps in a row
        var lapses: Int = 0             // number of times rated "again"
        var lastReviewed: Date? = nil
        var totalReviews: Int = 0

        var isNew: Bool { totalReviews == 0 }
    }

    // MARK: - Published state
    @Published private(set) var schedules: [String: CardSchedule] = [:]
    /// Lifetime count of card reviews, for the stats screen.
    @Published private(set) var lifetimeReviews: Int = 0

    private let udKey = "DigAPigToo_FlashcardSchedules"
    private let udReviewsKey = "DigAPigToo_FlashcardLifetimeReviews"

    private init() { load() }

    // MARK: - Querying

    func schedule(for name: String) -> CardSchedule {
        schedules[name] ?? CardSchedule()
    }

    /// Whether a card is currently due (new cards are always due).
    func isDue(_ name: String, asOf now: Date = Date()) -> Bool {
        let s = schedules[name] ?? CardSchedule()
        return s.isNew || s.due <= now
    }

    /// Given a candidate pool of structure names, return those due now (new + overdue),
    /// ordered: overdue first (most overdue first), then new cards.
    func dueCards(from names: [String], asOf now: Date = Date()) -> [String] {
        let due = names.filter { isDue($0, asOf: now) }
        return due.sorted { a, b in
            let sa = schedules[a] ?? CardSchedule()
            let sb = schedules[b] ?? CardSchedule()
            // New cards last; among reviewed, earliest due first.
            if sa.isNew != sb.isNew { return !sa.isNew && sb.isNew }
            return sa.due < sb.due
        }
    }

    func dueCount(from names: [String], asOf now: Date = Date()) -> Int {
        names.filter { isDue($0, asOf: now) }.count
    }

    func newCount(from names: [String]) -> Int {
        names.filter { (schedules[$0] ?? CardSchedule()).isNew }.count
    }

    // MARK: - Recording a review (SM-2–style)

    /// Apply a rating to a card and persist. Returns the updated schedule.
    @discardableResult
    func record(name: String, rating: Rating, now: Date = Date()) -> CardSchedule {
        var s = schedules[name] ?? CardSchedule()

        switch rating {
        case .again:
            s.reps = 0
            s.lapses += 1
            s.ease = max(1.3, s.ease - 0.20)
            s.intervalDays = 0            // relearn — due again very soon
            s.due = now.addingTimeInterval(60 * 10)   // ~10 minutes
        case .hard:
            s.ease = max(1.3, s.ease - 0.15)
            s.intervalDays = s.isNew ? 1 : max(1, s.intervalDays * 1.2)
            s.reps += 1
            s.due = now.addingTimeInterval(s.intervalDays * 86_400)
        case .good:
            if s.isNew {
                s.intervalDays = 1
            } else if s.reps == 1 {
                s.intervalDays = 6
            } else {
                s.intervalDays = max(1, s.intervalDays * s.ease)
            }
            s.reps += 1
            s.due = now.addingTimeInterval(s.intervalDays * 86_400)
        case .easy:
            s.ease += 0.15
            if s.isNew {
                s.intervalDays = 4
            } else {
                s.intervalDays = max(1, s.intervalDays * s.ease * 1.3)
            }
            s.reps += 1
            s.due = now.addingTimeInterval(s.intervalDays * 86_400)
        }

        s.lastReviewed = now
        s.totalReviews += 1
        schedules[name] = s
        lifetimeReviews += 1
        save()
        return s
    }

    // MARK: - Aggregates for stats

    var trackedCardCount: Int { schedules.count }

    var dueTodayAcrossAll: Int {
        let now = Date()
        return schedules.values.filter { !$0.isNew && $0.due <= now }.count
    }

    /// Cards considered "mature" (interval ≥ 21 days, Anki's convention).
    var matureCount: Int {
        schedules.values.filter { $0.intervalDays >= 21 }.count
    }

    // MARK: - Reset

    func resetAll() {
        schedules = [:]
        lifetimeReviews = 0
        UserDefaults.standard.removeObject(forKey: udKey)
        UserDefaults.standard.removeObject(forKey: udReviewsKey)
    }

    func reset(name: String) {
        schedules[name] = nil
        save()
    }

    // MARK: - Persistence (swap this section for SwiftData+CloudKit later)

    private func save() {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: udKey)
        }
        UserDefaults.standard.set(lifetimeReviews, forKey: udReviewsKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: udKey),
           let decoded = try? JSONDecoder().decode([String: CardSchedule].self, from: data) {
            schedules = decoded
        }
        lifetimeReviews = UserDefaults.standard.integer(forKey: udReviewsKey)
    }
}
