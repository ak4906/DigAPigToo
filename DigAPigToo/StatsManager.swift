//
//  StatsManager.swift
//  DigAPigToo
//
//  Persists long-term per-structure quiz performance to UserDefaults.
//  Keyed by structure name (stable across launches, unlike UUID).
//

import Foundation
import Combine

@MainActor
class StatsManager: ObservableObject {
    static let shared = StatsManager()

    // MARK: - Per-structure record
    struct StructureStat: Codable {
        var correctCount: Int = 0
        var incorrectCount: Int = 0
        var lastSeen: Date = Date()
        /// Mastery evidence 0…1 (exam-horizon): each correct answer adds guess-resistance-scaled
        /// credit (see `masteryCredit`), SCALED by reaction-time confidence; any wrong answer resets
        /// it to 0. ≥1 ⇒ this ID is mastered.
        var masteryEvidence: Double = 0
        /// Was the last answer a confident one (correct AND not slow)? Drives Smart mode's adaptive
        /// rest: confident IDs rest longer, struggled ones (wrong or slow) come back sooner.
        var lastConfident: Bool = true

        var totalAttempts: Int { correctCount + incorrectCount }
        var accuracy: Double {
            guard totalAttempts > 0 else { return 0 }
            return Double(correctCount) / Double(totalAttempts)
        }
        var accuracyPercent: Int { Int(accuracy * 100) }
        var isMastered: Bool { masteryEvidence >= 1.0 - 1e-9 }

        init() {}
        // Custom decode so stats saved before newer fields existed still load (defaults) instead of
        // failing the whole blob.
        enum CodingKeys: String, CodingKey { case correctCount, incorrectCount, lastSeen, masteryEvidence, lastConfident }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            correctCount = try c.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0
            incorrectCount = try c.decodeIfPresent(Int.self, forKey: .incorrectCount) ?? 0
            lastSeen = try c.decodeIfPresent(Date.self, forKey: .lastSeen) ?? Date()
            masteryEvidence = try c.decodeIfPresent(Double.self, forKey: .masteryEvidence) ?? 0
            lastConfident = try c.decodeIfPresent(Bool.self, forKey: .lastConfident) ?? true
        }
    }

    // MARK: - Published state
    @Published private(set) var stats: [String: StructureStat] = [:]
    /// Best single Real-Exam result (correct items in one session). Benchmarks the leaderboard's
    /// exam-performance points against a flawless full-length exam (30 stations = 150 items).
    @Published private(set) var bestExamScore: Int = 0

    private let udKey = "DigAPigToo_StructureStats"
    private let examKey = "DigAPigToo_BestExamScore"
    private let sweptKey = "DigAPigToo_QuizSweptNames"   // device-local sweep cursor (no cloud sync)
    /// Names already shown in the current "Sweep" cycle, so a sweep resumes instead of restarting.
    private var sweptNames: Set<String> = []
    private init() {
        load()
        mergeFromCloud()
        CloudSync.observe { [weak self] in
            Task { @MainActor in self?.mergeFromCloud() }
        }
    }

    // MARK: - Record an answer
    /// `kind`/`difficulty` drive base mastery credit; `responseTime` (seconds from the image appearing
    /// to the answer) scales it by CONFIDENCE — a correct answer that's fast relative to the user's own
    /// typical time earns more credit (masters in fewer reps); a slow/hesitant one earns less and will
    /// come back sooner. A cold first-ever write-in correct = instant mastery (prior knowledge); any
    /// wrong answer resets the evidence streak. (Defaults keep older/neutral callers working.)
    func record(structureName: String, correct: Bool,
                kind: RecallKind = .multipleChoice, difficulty: QuizDifficulty = .easy,
                responseTime: TimeInterval? = nil) {
        var s = stats[structureName] ?? StructureStat()
        let firstExposure = s.totalAttempts == 0
        if correct { s.correctCount += 1 } else { s.incorrectCount += 1 }
        s.lastSeen = Date()
        if correct {
            let mult = confidenceMultiplier(responseTime: responseTime, kind: kind)   // uses the OLD baseline
            if firstExposure && kind == .writeIn {
                s.masteryEvidence = 1.0   // wrote it cold on first exposure ⇒ already knew it
            } else {
                s.masteryEvidence = min(1.0, s.masteryEvidence + masteryCredit(kind: kind, difficulty: difficulty) * mult)
            }
            s.lastConfident = mult >= 1.0   // fast/normal correct = confident; slow = struggled
        } else {
            s.masteryEvidence = 0           // a miss breaks the streak — rebuild from scratch
            s.lastConfident = false
        }
        if let rt = responseTime, rt >= Self.rtFloor, rt <= Self.rtCeiling { updateReactionBaseline(rt, kind) }
        stats[structureName] = s
        save()
    }

    // MARK: - Reaction-time confidence (device-local)
    // A per-mode exponential moving average of answer time is the user's personal "typical speed".
    // Fast-vs-their-own-norm ⇒ they know it; slow ⇒ effortful. Per-user, so nothing is blanket-"easy".
    private let rtMcKey = "DigAPigToo_RT_EMA_MC"
    private let rtWriteKey = "DigAPigToo_RT_EMA_Write"
    private static let rtAlpha = 0.15
    private static let rtFloor: TimeInterval = 0.3    // faster than this = a mis-tap, not a real answer
    private static let rtCeiling: TimeInterval = 30   // slower than this = walked away / distracted

    private func reactionBaseline(_ kind: RecallKind) -> Double {
        UserDefaults.standard.double(forKey: kind == .writeIn ? rtWriteKey : rtMcKey)
    }
    private func updateReactionBaseline(_ rt: TimeInterval, _ kind: RecallKind) {
        let key = kind == .writeIn ? rtWriteKey : rtMcKey
        let cur = UserDefaults.standard.double(forKey: key)
        let next = cur <= 0 ? rt : cur * (1 - Self.rtAlpha) + rt * Self.rtAlpha
        UserDefaults.standard.set(next, forKey: key)
    }
    /// Credit multiplier for a correct answer based on how fast it was vs the user's own norm.
    private func confidenceMultiplier(responseTime rt: TimeInterval?, kind: RecallKind) -> Double {
        guard let rt, rt >= Self.rtFloor, rt <= Self.rtCeiling else { return 1.0 }   // missing/implausible → neutral
        let baseline = reactionBaseline(kind)
        guard baseline > 0 else { return 1.0 }                                        // no norm yet → neutral
        switch rt / baseline {
        case ..<0.6: return 3.0     // much faster than your norm — you know it cold
        case ..<1.0: return 2.0     // faster than your norm
        case ..<1.5: return 1.0     // about normal
        default:     return 0.6     // slow / hesitant — earns less, returns sooner
        }
    }

    /// True once a structure's quiz/exam evidence has reached mastery (≥1).
    func isQuizMastered(_ structureName: String) -> Bool { stats[structureName]?.isMastered ?? false }

    /// "Sweep" quiz selection: return up to `count` names from `names` not yet shown this cycle,
    /// resuming where the last sweep left off; when the pool is exhausted it starts a fresh cycle.
    /// Device-local only (a review-order convenience, not progress worth syncing).
    func sweepPick(from names: [String], count: Int) -> [String] {
        guard count > 0, !names.isEmpty else { return [] }
        let pool = Set(names)
        var available = pool.subtracting(sweptNames)
        if available.count < count {
            sweptNames.subtract(pool)     // finished a cycle for this pool → make it all available again
            available = pool
        }
        let chosen = Array(available).shuffled().prefix(count)
        sweptNames.formUnion(chosen)
        UserDefaults.standard.set(Array(sweptNames), forKey: sweptKey)
        return Array(chosen)
    }

    /// Reclassify one prior incorrect attempt as correct — used by the "I got it right"
    /// override when the answer matcher misgraded a typed answer. Moves one count from
    /// incorrect to correct so accuracy isn't unfairly dinged.
    func overrideLastToCorrect(structureName: String) {
        guard var s = stats[structureName], s.incorrectCount > 0 else { return }
        s.incorrectCount -= 1
        s.correctCount += 1
        // The override only applies to write-answer quiz/exam, so credit it as a correct write-in
        // (the preceding wrong had reset the streak to 0).
        s.masteryEvidence = min(1.0, s.masteryEvidence + masteryCredit(kind: .writeIn, difficulty: .easy))
        stats[structureName] = s
        save()
    }

    /// Record a completed Real-Exam session's correct-item count; keeps the running best.
    func recordExamScore(_ correctItems: Int) {
        guard correctItems > bestExamScore else { return }
        bestExamScore = correctItems
        saveExamScore()
    }

    // MARK: - Aggregates
    var totalAnswered: Int { stats.values.reduce(0) { $0 + $1.totalAttempts } }

    var overallAccuracy: Double {
        let total = totalAnswered
        guard total > 0 else { return 0 }
        let correct = stats.values.reduce(0) { $0 + $1.correctCount }
        return Double(correct) / Double(total)
    }

    /// Structures attempted at least twice, sorted worst → best
    var weakest: [(name: String, stat: StructureStat)] {
        stats.filter { $0.value.totalAttempts >= 2 }
            .sorted { $0.value.accuracy < $1.value.accuracy }
            .map { (name: $0.key, stat: $0.value) }
    }

    /// Structures attempted at least twice, sorted best → worst
    var strongest: [(name: String, stat: StructureStat)] {
        stats.filter { $0.value.totalAttempts >= 2 }
            .sorted { $0.value.accuracy > $1.value.accuracy }
            .map { (name: $0.key, stat: $0.value) }
    }

    /// Category-level accuracy given the full structure list
    func categoryAccuracy(structures: [AnatomyStructure],
                          categories: [AnatomyCategory]) -> [(category: String, accuracy: Double, attempts: Int)] {
        categories.compactMap { cat in
            let names = structures.filter { $0.categoryId == cat.id }.map { $0.name }
            let catStats = names.compactMap { stats[$0] }
            let attempts = catStats.reduce(0) { $0 + $1.totalAttempts }
            guard attempts > 0 else { return nil }
            let correct = catStats.reduce(0) { $0 + $1.correctCount }
            return (category: cat.name,
                    accuracy: Double(correct) / Double(attempts),
                    attempts: attempts)
        }
        .sorted { $0.accuracy < $1.accuracy }
    }

    // MARK: - Reset
    func reset() {
        stats = [:]
        bestExamScore = 0
        UserDefaults.standard.removeObject(forKey: udKey)
        UserDefaults.standard.removeObject(forKey: examKey)
        CloudSync.set(nil, forKey: udKey)
        CloudSync.set(0, forKey: examKey)
        CloudSync.flush()
    }

    /// Manual iCloud sync (iCloud Sync page): pull the cloud copy in, then push the merged
    /// result back up.
    func syncNow() { mergeFromCloud(); save(); saveExamScore() }

    // MARK: - Persistence (local UserDefaults + iCloud key-value mirror)
    private func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: udKey)
        CloudSync.set(data, forKey: udKey)
        CloudSync.flush()
    }
    private func saveExamScore() {
        UserDefaults.standard.set(bestExamScore, forKey: examKey)
        CloudSync.set(bestExamScore, forKey: examKey)
        CloudSync.flush()
    }
    private func load() {
        bestExamScore = UserDefaults.standard.integer(forKey: examKey)
        sweptNames = Set(UserDefaults.standard.stringArray(forKey: sweptKey) ?? [])
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([String: StructureStat].self, from: data)
        else { return }
        stats = decoded
    }

    /// Merge the iCloud copy into local stats: union of structures, and for a
    /// structure recorded on both devices the more recently seen record wins
    /// (per-key last-writer-wins via `lastSeen`). Idempotent; re-saves + re-pushes
    /// the merged result only when something actually changed.
    private func mergeFromCloud() {
        // Best exam score: take the higher of local vs cloud (independent of the stats blob).
        let cloudExam = CloudSync.integer(forKey: examKey)
        if cloudExam != bestExamScore { bestExamScore = max(bestExamScore, cloudExam); saveExamScore() }
        guard let data = CloudSync.data(forKey: udKey),
              let cloud = try? JSONDecoder().decode([String: StructureStat].self, from: data)
        else { return }   // no cloud copy yet — a later record()/notification will seed it
        var changed = false          // we adopted something newer from the cloud
        for (name, remote) in cloud {
            if let local = stats[name] {
                if remote.lastSeen > local.lastSeen { stats[name] = remote; changed = true }
            } else {
                stats[name] = remote; changed = true
            }
        }
        // Do we hold anything the cloud is missing or has an older copy of? If so,
        // push our union up so the other device gets it without us having to record.
        var cloudStale = false
        for (name, local) in stats {
            if let remote = cloud[name] { if local.lastSeen > remote.lastSeen { cloudStale = true; break } }
            else { cloudStale = true; break }
        }
        if changed || cloudStale { save() }
    }
}
