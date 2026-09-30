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

    var idFrac: Double { idTotal > 0 ? Double(idMastered) / Double(idTotal) : 0 }
    var traceFrac: Double { traceTotal > 0 ? Double(traceMastered) / Double(traceTotal) : 0 }
    var fillFrac: Double { fillTotal > 0 ? Double(fillMastered) / Double(fillTotal) : 0 }

    /// 0…1000 weighted mastery score (1000 = every domain fully mastered).
    var score: Int {
        Int((Self.idWeight * idFrac + Self.traceWeight * traceFrac + Self.fillWeight * fillFrac) * 1000)
    }

    /// Each domain's contribution to the score (0…1000), for the breakdown display.
    var idPoints: Int { Int(Self.idWeight * idFrac * 1000) }
    var tracePoints: Int { Int(Self.traceWeight * traceFrac * 1000) }
    var fillPoints: Int { Int(Self.fillWeight * fillFrac * 1000) }

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

        return m
    }
}
