//
//  MasteryScore.swift
//  DigAPigToo
//
//  A single 0–1000 "how much do you truly know" score, weighted to mirror the BIOL 2501 practical:
//  physical IDs dominate (~68%), traces next (~22%), fill-ins least (~10%) — matched to the real
//  exam's points (219 total: 150 from 30 ID stations, 48 from 2 traces, 21 from fill-ins).
//  It rewards retained understanding, not cramming volume. This is what gets submitted to the
//  Game Center leaderboard.
//

import Foundation

@MainActor
struct MasteryScore {
    // Each domain's share of the real practical grade (219 pts: 150 IDs / 48 traces / 21 fill-ins).
    // They sum to 1.0.
    static let idWeight = 150.0 / 219.0      // ≈ 0.685
    static let traceWeight = 48.0 / 219.0    // ≈ 0.219
    static let fillWeight = 21.0 / 219.0     // ≈ 0.096

    var idMastered = 0, idTotal = 0
    var traceMastered = 0, traceTotal = 0      // fully-mastered counts (shown as "X / Y")
    var fillMastered = 0, fillTotal = 0
    // Partial-credit sums (per sub-unit): traces earn credit for the steps recalled, fill-ins for the
    // blanks solved — so a long multi-part item isn't all-or-nothing. IDs stay binary (no sub-units).
    var traceCredit = 0.0
    var fillCredit = 0.0

    // Practice/performance inputs (quizzes + Real Exam, which both record into StatsManager).
    var questionsAnswered = 0
    var answerAccuracy = 0.0        // 0…1 overall correctness
    var bestExamScore = 0          // best correct-item count in one Real-Exam session

    var idFrac: Double { idTotal > 0 ? Double(idMastered) / Double(idTotal) : 0 }
    var traceFrac: Double { traceTotal > 0 ? traceCredit / Double(traceTotal) : 0 }
    var fillFrac: Double { fillTotal > 0 ? fillCredit / Double(fillTotal) : 0 }

    // Fully-MASTERED fractions (vs the partial-credit `*Frac` above, which the points use). Achievements
    // key off these so "half mastered" means half of them actually mastered, not half the credit earned.
    var idMasteredFrac: Double { idTotal > 0 ? Double(idMastered) / Double(idTotal) : 0 }
    var traceMasteredFrac: Double { traceTotal > 0 ? Double(traceMastered) / Double(traceTotal) : 0 }
    var fillMasteredFrac: Double { fillTotal > 0 ? Double(fillMastered) / Double(fillTotal) : 0 }

    // MARK: Mastery (understanding) — the primary 0…1000 component
    var masteryPoints: Int {
        Int((Self.idWeight * idFrac + Self.traceWeight * traceFrac + Self.fillWeight * fillFrac) * 1000)
    }
    var idPoints: Int { Int(Self.idWeight * idFrac * 1000) }
    var tracePoints: Int { Int(Self.traceWeight * traceFrac * 1000) }
    var fillPoints: Int { Int(Self.fillWeight * fillFrac * 1000) }

    // MARK: Practice (using it correctly) — a 0…250 differentiator on top of mastery
    // Among people who've mastered everything, this ranks who practices MORE, more ACCURATELY,
    // and can hold it together across a full-length exam.
    static let volumeCap = 100.0        // reps from quizzes + exams
    static let accuracyCap = 50.0       // overall correctness
    static let examCap = 100.0          // best full-length-exam performance
    // Maxing volume takes real study — roughly the ~398 IDs practiced several times over.
    static let volumeTarget = 2000.0
    // A flawless full-length practical: 30 stations × 5 items = 150 correct.
    static let examTarget = 150.0

    var practicePoints: Int { Int(Self.volumeCap * min(1.0, Double(questionsAnswered) / Self.volumeTarget)) }
    var accuracyPoints: Int {
        let confidence = min(1.0, Double(questionsAnswered) / 100.0)   // earned over ~100 questions
        return Int(answerAccuracy * confidence * Self.accuracyCap)
    }
    var examPoints: Int { Int(Self.examCap * min(1.0, Double(bestExamScore) / Self.examTarget)) }
    var performancePoints: Int { practicePoints + accuracyPoints + examPoints }

    /// Total leaderboard score: mastery (≤1000) + practice/performance (≤250).
    var score: Int { masteryPoints + performancePoints }

    static func current() -> MasteryScore {
        let data = AnatomyDataManager.shared
        let cards = FlashcardManager.shared
        let quiz = StatsManager.shared
        let traces = TraceProgressManager.shared
        let fills = FillBlankProgressManager.shared

        var m = MasteryScore()

        // IDs: mastered via an exam-horizon flashcard (≥3 consecutive spaced successful reviews)
        // OR enough guess-resistant, spaced quiz/exam recall (the per-structure mastery evidence ≥ 1).
        // Both can be LOST: a flashcard lapse leaves the review phase and resets reps; a wrong quiz/
        // exam answer resets the evidence streak. (Replaces the old bars — review+2-reps cards at
        // ~2–3-day intervals, and cumulative-80%-accuracy quizzes — which both inflated the score.)
        m.idTotal = data.structures.count
        for s in data.structures {
            let cardMastered = cards.schedule(for: s.name).isMasteredForScore
            let quizMastered = quiz.isQuizMastered(s.name)
            if cardMastered || quizMastered { m.idMastered += 1 }
        }

        m.traceTotal = data.traces.count
        m.traceMastered = traces.masteredCount(in: data.traces)
        m.traceCredit = traces.creditSum(in: data.traces)              // partial: credit per step recalled

        m.fillTotal = data.fillBlanks.count
        m.fillMastered = fills.summary(for: data.fillBlanks).mastered
        m.fillCredit = fills.creditSum(for: data.fillBlanks)           // partial: credit per blank solved

        m.questionsAnswered = quiz.totalAnswered
        m.answerAccuracy = quiz.overallAccuracy
        m.bestExamScore = quiz.bestExamScore

        return m
    }
}
