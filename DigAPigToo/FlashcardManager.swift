//
//  FlashcardManager.swift
//  DigAPigToo
//
//  Spaced-repetition (SRS) scheduling + persistence for the flashcard study mode.
//  Models Anki's learning-steps + review algorithm:
//    • New cards run through short LEARNING STEPS (1 min → 10 min) before graduating.
//    • A new card must be passed at least twice (Good at each step) to graduate.
//    • Again restarts the steps and keeps the card in the current session.
//    • After graduating, intervals grow in DAYS using an ease factor (SM-2 style).
//    • Again on a mature card = a lapse: ease drops, interval is slashed, and the card
//      goes through RELEARNING steps before returning to review.
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
        case again   // forgot — restart steps / lapse
        case hard    // recalled with difficulty
        case good    // recalled
        case easy    // trivial — big jump
    }

    enum Phase: String, Codable {
        case new         // never studied
        case learning    // going through the short learning steps
        case review      // graduated; day-based intervals
        case relearning  // lapsed from review; short steps before returning to review
    }

    // MARK: - Algorithm constants (Anki defaults)
    /// Learning steps for a brand-new card, in seconds: 1 min → 10 min.
    static let learningSteps: [Double] = [60, 600]
    /// Relearning steps after a lapse, in seconds: 10 min.
    static let relearnSteps: [Double] = [600]
    static let graduatingIntervalDays: Double = 1      // Good graduates to 1 day
    static let easyGraduatingIntervalDays: Double = 4  // Easy graduates straight to 4 days
    static let hardMultiplier: Double = 1.2            // Hard on review = ×1.2
    static let easyBonus: Double = 1.3                 // Easy on review = ×ease×1.3
    static let startingEase: Double = 2.5              // 250%
    static let minEase: Double = 1.3
    static let easePenaltyAgain: Double = 0.20         // −20% on lapse
    static let easePenaltyHard: Double = 0.15          // −15% on Hard
    static let easeBonusEasy: Double = 0.15            // +15% on Easy

    private static let secondsPerDay: Double = 86_400

    // MARK: - Per-card scheduling record
    struct CardSchedule: Codable {
        var phase: Phase = .new
        var learningStep: Int = 0       // index into the current step array
        var ease: Double = FlashcardManager.startingEase
        var intervalDays: Double = 0    // current review interval in days
        var due: Date = Date()          // next review time
        var reps: Int = 0               // successful reviews since last lapse
        var lapses: Int = 0             // times rated Again while in review
        var lastReviewed: Date? = nil
        var totalReviews: Int = 0

        var isNew: Bool { phase == .new }

        init() {}

        // Custom decoding so older saved data (which had no `phase`/`learningStep`)
        // migrates cleanly instead of failing to decode.
        enum CodingKeys: String, CodingKey {
            case phase, learningStep, ease, intervalDays, due, reps, lapses, lastReviewed, totalReviews
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            ease = try c.decodeIfPresent(Double.self, forKey: .ease) ?? FlashcardManager.startingEase
            intervalDays = try c.decodeIfPresent(Double.self, forKey: .intervalDays) ?? 0
            due = try c.decodeIfPresent(Date.self, forKey: .due) ?? Date()
            reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 0
            lapses = try c.decodeIfPresent(Int.self, forKey: .lapses) ?? 0
            lastReviewed = try c.decodeIfPresent(Date.self, forKey: .lastReviewed)
            totalReviews = try c.decodeIfPresent(Int.self, forKey: .totalReviews) ?? 0
            learningStep = try c.decodeIfPresent(Int.self, forKey: .learningStep) ?? 0
            if let p = try c.decodeIfPresent(Phase.self, forKey: .phase) {
                phase = p
            } else {
                // Migrate old (pre-learning-steps) records.
                if totalReviews == 0 { phase = .new }
                else if intervalDays >= 1 { phase = .review }
                else { phase = .learning }
            }
        }
    }

    // MARK: - Published state
    @Published private(set) var schedules: [String: CardSchedule] = [:]
    /// Lifetime count of card reviews, for the stats screen.
    @Published private(set) var lifetimeReviews: Int = 0

    // v2: bumped from the original key to discard pre-release test data that was scheduled
    // by the first (buggy) interval scheme and would otherwise migrate in as inflated
    // review-phase intervals. Safe because flashcards had not shipped.
    private let udKey = "DigAPigToo_FlashcardSchedules_v2"
    private let udReviewsKey = "DigAPigToo_FlashcardLifetimeReviews_v2"

    private init() { load() }

    // MARK: - Querying

    func schedule(for name: String) -> CardSchedule {
        schedules[name] ?? CardSchedule()
    }

    /// Whether a card should be studied now (new, or its due time has passed).
    func isDue(_ name: String, asOf now: Date = Date()) -> Bool {
        let s = schedules[name] ?? CardSchedule()
        return s.phase == .new || s.due <= now
    }

    /// Cards to study now, in study order:
    ///   1. Previously-seen cards that are due, MOST OVERDUE FIRST.
    ///   2. New (never-studied) cards, SHUFFLED, after the review backlog.
    func dueCards(from names: [String], asOf now: Date = Date()) -> [String] {
        var dueExisting: [String] = []
        var newCards: [String] = []
        for name in names {
            let s = schedules[name] ?? CardSchedule()
            if s.phase == .new {
                newCards.append(name)
            } else if s.due <= now {
                dueExisting.append(name)
            }
        }
        dueExisting.sort { (schedules[$0]?.due ?? now) < (schedules[$1]?.due ?? now) }
        return dueExisting + newCards.shuffled()
    }

    func dueCount(from names: [String], asOf now: Date = Date()) -> Int {
        names.filter { isDue($0, asOf: now) }.count
    }

    func newCount(from names: [String]) -> Int {
        names.filter { (schedules[$0] ?? CardSchedule()).phase == .new }.count
    }

    // MARK: - Recording a review

    /// Apply a rating to a card and persist. Returns the updated schedule (the session
    /// uses `phase`/`due` on the result to decide whether the card stays in this session).
    @discardableResult
    func record(name: String, rating: Rating, now: Date = Date()) -> CardSchedule {
        var s = schedules[name] ?? CardSchedule()
        apply(&s, rating, now)
        s.lastReviewed = now
        s.totalReviews += 1
        schedules[name] = s
        lifetimeReviews += 1
        save()
        return s
    }

    /// Short human label of the interval a rating would produce (for the buttons),
    /// e.g. "1m", "10m", "1d", "2mo". Does not mutate state.
    func previewLabel(for name: String, rating: Rating, now: Date = Date()) -> String {
        var s = schedules[name] ?? CardSchedule()
        apply(&s, rating, now)
        return Self.humanInterval(s.due.timeIntervalSince(now))
    }

    // MARK: - Core algorithm (shared by record + preview)

    private func apply(_ s: inout CardSchedule, _ rating: Rating, _ now: Date) {
        switch s.phase {
        case .new, .learning:
            applySteps(&s, rating, now, steps: Self.learningSteps, relearning: false)
        case .relearning:
            applySteps(&s, rating, now, steps: Self.relearnSteps, relearning: true)
        case .review:
            applyReview(&s, rating, now)
        }
    }

    /// Learning / relearning phase: short steps in minutes.
    private func applySteps(_ s: inout CardSchedule, _ rating: Rating, _ now: Date,
                            steps: [Double], relearning: Bool) {
        s.phase = relearning ? .relearning : .learning

        switch rating {
        case .again:
            // Restart the steps.
            s.learningStep = 0
            s.due = now.addingTimeInterval(steps[0])
        case .hard:
            // Repeat a delay between the current and next step (or ×1.5 if at the last).
            let cur = steps[min(s.learningStep, steps.count - 1)]
            let next = (s.learningStep + 1 < steps.count) ? steps[s.learningStep + 1] : cur * 1.5
            s.due = now.addingTimeInterval((cur + next) / 2)
        case .good:
            let nextStep = s.learningStep + 1
            if nextStep < steps.count {
                s.learningStep = nextStep
                s.due = now.addingTimeInterval(steps[nextStep])
            } else {
                graduate(&s, now, relearning: relearning, easy: false)
            }
        case .easy:
            graduate(&s, now, relearning: relearning, easy: true)
        }
    }

    /// Move a card out of (re)learning and back into day-based review.
    private func graduate(_ s: inout CardSchedule, _ now: Date, relearning: Bool, easy: Bool) {
        s.phase = .review
        s.learningStep = 0
        if relearning {
            // Returning from a lapse: keep the (already slashed) interval, min 1 day.
            s.intervalDays = max(1, s.intervalDays)
            if easy { s.intervalDays *= Self.easyBonus }
        } else {
            s.intervalDays = easy ? Self.easyGraduatingIntervalDays : Self.graduatingIntervalDays
            s.reps = 0
        }
        s.reps += 1
        s.due = now.addingTimeInterval(s.intervalDays * Self.secondsPerDay)
    }

    /// Review phase: day-based intervals multiplied by the ease factor.
    /// Implements Anki's late-review bonus (a card answered after its due date gets part
    /// of the overdue time folded into the next interval) and the SM-2 limitation that
    /// every non-Again interval is at least the previous interval + 1 day.
    private func applyReview(_ s: inout CardSchedule, _ rating: Rating, _ now: Date) {
        let prev = s.intervalDays
        // Days the card is overdue (0 if reviewed on time or early).
        let daysLate = max(0, now.timeIntervalSince(s.due) / Self.secondsPerDay)

        switch rating {
        case .again:
            // Lapse: drop ease, slash interval, send through relearning.
            // (New-interval default 0% → interval effectively resets; 1-day floor on return.)
            s.lapses += 1
            s.ease = max(Self.minEase, s.ease - Self.easePenaltyAgain)
            s.intervalDays = 1
            s.reps = 0
            s.phase = .relearning
            s.learningStep = 0
            s.due = now.addingTimeInterval(Self.relearnSteps[0])
            return
        case .hard:
            // Hard does not get the late bonus in Anki; ×1.2 on the scheduled interval.
            s.ease = max(Self.minEase, s.ease - Self.easePenaltyHard)
            s.intervalDays = prev * Self.hardMultiplier
        case .good:
            // Good folds in HALF the overdue days before multiplying by ease.
            s.intervalDays = (prev + daysLate / 2) * s.ease
        case .easy:
            // Easy folds in ALL the overdue days, then ×ease×easyBonus; ease +15%.
            s.ease += Self.easeBonusEasy
            s.intervalDays = (prev + daysLate) * s.ease * Self.easyBonus
        }

        // SM-2 limitation: every successful interval is at least previous + 1 day.
        s.intervalDays = max(prev + 1, s.intervalDays)
        s.reps += 1
        s.due = now.addingTimeInterval(s.intervalDays * Self.secondsPerDay)
    }

    // MARK: - Formatting

    static func humanInterval(_ seconds: Double) -> String {
        if seconds < 3_600 { return "\(max(1, Int((seconds / 60).rounded())))m" }
        if seconds < Self.secondsPerDay { return "\(Int((seconds / 3_600).rounded()))h" }
        let days = seconds / Self.secondsPerDay
        if days < 30 { return "\(Int(days.rounded()))d" }
        if days < 365 { return "\(Int((days / 30).rounded()))mo" }
        return "\(String(format: "%.1f", days / 365))y"
    }

    // MARK: - Aggregates for stats

    var trackedCardCount: Int { schedules.count }

    var dueTodayAcrossAll: Int {
        let now = Date()
        return schedules.values.filter { $0.phase != .new && $0.due <= now }.count
    }

    /// Cards considered "mature" (interval ≥ 21 days, Anki's convention).
    var matureCount: Int {
        schedules.values.filter { $0.phase == .review && $0.intervalDays >= 21 }.count
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
