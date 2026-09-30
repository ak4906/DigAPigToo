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
    // Rewards putting in reps (quizzes + exams) AND getting them right, so among two people who
    // have mastered everything, the one who practices more and makes fewer mistakes ranks higher.
    static let practiceVolumeCap = 150.0   // pts from sheer reps (0.5 pt/question, maxes at 300 Q)
    static let accuracyCap = 100.0         // pts from correctness (full only at 100% over 50+ Q)

    var practicePoints: Int { Int(min(Self.practiceVolumeCap, Double(questionsAnswered) * 0.5)) }
    var accuracyPoints: Int {
        let confidence = min(1.0, Double(questionsAnswered) / 50.0)   // ramp in over first 50 Q
        return Int(answerAccuracy * confidence * Self.accuracyCap)
    }
    var performancePoints: Int { practicePoints + accuracyPoints }

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

        return m
    }
}
