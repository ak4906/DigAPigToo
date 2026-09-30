//
//  MasteryScore.swift
//  DigAPigToo
//
//  A single 0–1000 "how much do you truly know" score, weighted to mirror the BIOL 2501 practical:
//  physical IDs dominate (~65%), traces next (~23%), fill-in / epithelial knowledge least (~12%).
//  It rewards retained understanding, not cramming volume: an ID only counts once it's a solid
//  spaced-repetition flashcard OR has high quiz accuracy over several attempts. Fill-ins (which
//  allow "I got it right" self-grading) carry the smallest weight, so the ranking can't be gamed.
//  This is what gets submitted to the Game Center leaderboard.
//

import Foundation

@MainActor
struct MasteryScore {
    // Weights reflect each domain's share of the practical grade. They sum to 1.0.
    static let idWeight = 0.65
    static let traceWeight = 0.23
    static let fillWeight = 0.12

    var idMastered = 0, idTotal = 0
    var traceMastered = 0, traceTotal = 0
    var fillMastered = 0, fillTotal = 0

    // Practice/performance inputs (quizzes + Real Exam, which both record into StatsManager).
    var questionsAnswered = 0
    var answerAccuracy = 0.0        // 0…1 overall correctness
    var bestExamScore = 0          // best correct-item count in one Real-Exam session

    var idFrac: Double { idTotal > 0 ? Double(idMastered) / Double(idTotal) : 0 }
    var traceFrac: Double { traceTotal > 0 ? Double(traceMastered) / Double(traceTotal) : 0 }
    var fillFrac: Double { fillTotal > 0 ? Double(fillMastered) / Double(fillTotal) : 0 }

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

        // IDs: known via a solid review-phase flashcard OR high quiz accuracy over enough attempts.
        m.idTotal = data.structures.count
        for s in data.structures {
            let sched = cards.schedule(for: s.name)
            let cardKnown = sched.phase == .review && sched.reps >= 2
            let qstat = quiz.stats[s.name]
            let quizKnown = (qstat?.totalAttempts ?? 0) >= 3 && (qstat?.accuracy ?? 0) >= 0.8
            if cardKnown || quizKnown { m.idMastered += 1 }
        }

        m.traceTotal = data.traces.count
        m.traceMastered = traces.masteredCount(in: data.traces)

        m.fillTotal = data.fillBlanks.count
        m.fillMastered = fills.summary(for: data.fillBlanks).mastered

        m.questionsAnswered = quiz.totalAnswered
        m.answerAccuracy = quiz.overallAccuracy
        m.bestExamScore = quiz.bestExamScore

        return m
    }
}
