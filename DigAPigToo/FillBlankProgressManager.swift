//
//  FillBlankProgressManager.swift
//  DigAPigToo
//
//  Per-fill-in study progress + a lightweight spaced-repetition ordering, so the study mode
//  surfaces new, weak, and stale questions first instead of always starting from the same one.
//  Keyed by the question's PROMPT text (stable across launches, unlike the runtime UUID).
//  Persists to UserDefaults and mirrors to iCloud (per-key last-writer-wins), like the other
//  progress managers.
//

import Foundation
import Combine

@MainActor
final class FillBlankProgressManager: ObservableObject {
    static let shared = FillBlankProgressManager()

    /// A fill-in climbs a one-way difficulty ladder:
    /// `.mc` (multiple choice, recognition) → `.write` (write-in, active recall) → `.mastered`.
    /// Getting the write-in wrong demotes it back to `.mc`. Mastering write-in masters both,
    /// since write-in is strictly harder than multiple choice.
    enum Stage: String, Codable { case mc, write, mastered }

    struct QProgress: Codable {
        var seen: Int = 0            // attempts (whole-sentence)
        var correct: Int = 0         // attempts where EVERY gap was right
        var reps: Int = 0            // consecutive all-correct passes WITHIN the current stage
        var lastSeen: Date = .distantPast
        var due: Date = Date()       // next recommended time (new = now)
        var intervalDays: Double = 0
        var stage: Stage = .mc       // current difficulty stage
        var bestCorrect: Int = 0     // most blanks solved in a single pass — drives partial credit

        init() {}

        // Defensive decode so progress saved before newer fields existed still loads (defaults).
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            seen = try c.decodeIfPresent(Int.self, forKey: .seen) ?? 0
            correct = try c.decodeIfPresent(Int.self, forKey: .correct) ?? 0
            reps = try c.decodeIfPresent(Int.self, forKey: .reps) ?? 0
            lastSeen = try c.decodeIfPresent(Date.self, forKey: .lastSeen) ?? .distantPast
            due = try c.decodeIfPresent(Date.self, forKey: .due) ?? Date()
            intervalDays = try c.decodeIfPresent(Double.self, forKey: .intervalDays) ?? 0
            stage = try c.decodeIfPresent(Stage.self, forKey: .stage) ?? .mc
            bestCorrect = try c.decodeIfPresent(Int.self, forKey: .bestCorrect) ?? 0
        }
    }

    @Published private(set) var progress: [String: QProgress] = [:]

    /// Correct passes needed to advance each stage.
    private let mcGraduateReps = 1     // one correct multiple-choice pass → graduate to write-in
    private let writeMasterReps = 2    // two correct write-in passes → fully mastered

    private let udKey = "DigAPigToo_FillBlankProgress"

    private init() {
        load()
        mergeFromCloud()
        CloudSync.observe { [weak self] in Task { @MainActor in self?.mergeFromCloud() } }
    }

    func entry(for prompt: String) -> QProgress { progress[prompt] ?? QProgress() }
    func isMastered(_ prompt: String) -> Bool { (progress[prompt]?.stage ?? .mc) == .mastered }

    /// The stage a fill-in should currently be studied in (drives multiple-choice vs write-in).
    func stage(for prompt: String) -> Stage { progress[prompt]?.stage ?? .mc }

    /// Record a completed sentence. `correctBlanks`/`totalBlanks` give partial credit per blank; the
    /// ladder (MC → write-in → mastered, demote on a miss) still turns on whether EVERY gap was right.
    func record(prompt: String, correctBlanks: Int, totalBlanks: Int) {
        var p = progress[prompt] ?? QProgress()
        p.seen += 1
        p.lastSeen = Date()
        p.bestCorrect = max(p.bestCorrect, correctBlanks)
        let allCorrect = totalBlanks > 0 && correctBlanks >= totalBlanks
        if allCorrect {
            p.correct += 1
            p.reps += 1
            if p.stage == .mc && p.reps >= mcGraduateReps {
                // Graduated recognition → restart spacing for the harder write-in stage, soon.
                p.stage = .write
                p.reps = 0
                p.intervalDays = 0
                p.due = Date().addingTimeInterval(600)
            } else {
                if p.stage == .write && p.reps >= writeMasterReps { p.stage = .mastered }
                p.intervalDays = p.intervalDays == 0 ? 1 : min(p.intervalDays * 2.5, 60)
                p.due = Date().addingTimeInterval(p.intervalDays * 86_400)
            }
        } else {
            p.reps = 0
            if p.stage != .mc { p.stage = .mc }      // missed the write-in → back to multiple choice
            p.intervalDays = 0
            p.due = Date().addingTimeInterval(600)    // ~10 min → resurfaces later this session
        }
        progress[prompt] = p
        save()
    }

    /// Smart study order: never-seen first, then due questions (weakest first), then the rest
    /// (soonest-due first). Randomness in the first two tiers keeps a fresh session from always
    /// starting with the same question and over-drilling the early ones.
    func smartOrder(_ questions: [FillBlankQuestion]) -> [FillBlankQuestion] {
        let now = Date()
        // Compute each question's sort key ONCE (random drawn once per element), then sort by the
        // fixed keys — a comparator that re-rolled randomness per comparison isn't a valid ordering.
        let keyed: [(q: FillBlankQuestion, tier: Int, sub: Double)] = questions.map { q in
            let p = entry(for: q.prompt)
            if p.seen == 0 { return (q, 0, Double.random(in: 0..<1)) }               // new → shuffled
            if p.due <= now {
                let acc = p.seen > 0 ? Double(p.correct) / Double(p.seen) : 0
                return (q, 1, acc + Double.random(in: 0..<0.3))                       // due → weakest-ish first
            }
            return (q, 2, p.due.timeIntervalSinceReferenceDate)                        // not due → soonest first
        }
        return keyed
            .sorted { $0.tier != $1.tier ? $0.tier < $1.tier : $0.sub < $1.sub }
            .map { $0.q }
    }

    /// Browse-All order: the questions' original topic order, but ROTATED to resume right after the
    /// one you most recently saw — so repeated passes cycle through everything instead of restarting
    /// at the top (where the first few got over-seen and the last ones never appeared).
    func browseOrder(_ questions: [FillBlankQuestion]) -> [FillBlankQuestion] {
        guard !questions.isEmpty else { return questions }
        var bestIdx: Int? = nil
        var bestDate = Date.distantPast
        for (i, q) in questions.enumerated() {
            if let d = progress[q.prompt]?.lastSeen, d >= bestDate { bestDate = d; bestIdx = i }
        }
        guard let idx = bestIdx else { return questions }   // none seen yet → original order
        let start = (idx + 1) % questions.count
        return Array(questions[start...] + questions[..<start])
    }

    /// Counts over a question set, for the Stats tab.
    func summary(for questions: [FillBlankQuestion]) -> (studied: Int, mastered: Int, total: Int) {
        var studied = 0, mastered = 0
        for q in questions {
            if let p = progress[q.prompt], p.seen > 0 {
                studied += 1
                if p.stage == .mastered { mastered += 1 }
            }
        }
        return (studied, mastered, questions.count)
    }

    /// Partial-credit sum for the mastery score: each fill-in contributes the fraction of its blanks
    /// you best solved in a single pass (0…1), so a 2-of-3 attempt earns credit instead of nothing.
    func creditSum(for questions: [FillBlankQuestion]) -> Double {
        questions.reduce(0.0) { sum, q in
            let total = q.answers.count
            guard total > 0 else { return sum }
            return sum + min(1.0, Double(progress[q.prompt]?.bestCorrect ?? 0) / Double(total))
        }
    }

    /// How many studied questions sit in each stage (unseen questions are excluded).
    func stageCounts(for questions: [FillBlankQuestion]) -> (mc: Int, write: Int, mastered: Int) {
        var mc = 0, write = 0, mastered = 0
        for q in questions {
            guard let p = progress[q.prompt], p.seen > 0 else { continue }
            switch p.stage {
            case .mc: mc += 1
            case .write: write += 1
            case .mastered: mastered += 1
            }
        }
        return (mc, write, mastered)
    }

    func reset() {
        progress = [:]
        UserDefaults.standard.removeObject(forKey: udKey)
        CloudSync.set(nil, forKey: udKey)
        CloudSync.flush()
    }

    /// Manual iCloud sync (iCloud Sync page).
    func syncNow() { mergeFromCloud(); save() }

    // MARK: Persistence (local UserDefaults + iCloud key-value mirror)
    private func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: udKey)
        CloudSync.set(data, forKey: udKey)
        CloudSync.flush()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([String: QProgress].self, from: data) else { return }
        progress = decoded
    }

    /// Merge the iCloud copy: union of questions, newer `lastSeen` wins; push up if we hold more.
    private func mergeFromCloud() {
        guard let data = CloudSync.data(forKey: udKey),
              let cloud = try? JSONDecoder().decode([String: QProgress].self, from: data) else { return }
        var changed = false
        for (k, remote) in cloud {
            if let local = progress[k] {
                if remote.lastSeen > local.lastSeen { progress[k] = remote; changed = true }
            } else {
                progress[k] = remote; changed = true
            }
        }
        var cloudStale = false
        for (k, local) in progress {
            if let remote = cloud[k] { if local.lastSeen > remote.lastSeen { cloudStale = true; break } }
            else { cloudStale = true; break }
        }
        if changed || cloudStale { save() }
    }
}
