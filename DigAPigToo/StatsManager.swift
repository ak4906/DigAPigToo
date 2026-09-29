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

        var totalAttempts: Int { correctCount + incorrectCount }
        var accuracy: Double {
            guard totalAttempts > 0 else { return 0 }
            return Double(correctCount) / Double(totalAttempts)
        }
        var accuracyPercent: Int { Int(accuracy * 100) }
    }

    // MARK: - Published state
    @Published private(set) var stats: [String: StructureStat] = [:]

    private let udKey = "DigAPigToo_StructureStats"
    private init() {
        load()
        mergeFromCloud()
        CloudSync.observe { [weak self] in
            Task { @MainActor in self?.mergeFromCloud() }
        }
    }

    // MARK: - Record an answer
    func record(structureName: String, correct: Bool) {
        var s = stats[structureName] ?? StructureStat()
        if correct { s.correctCount += 1 } else { s.incorrectCount += 1 }
        s.lastSeen = Date()
        stats[structureName] = s
        save()
    }

    /// Reclassify one prior incorrect attempt as correct — used by the "I got it right"
    /// override when the answer matcher misgraded a typed answer. Moves one count from
    /// incorrect to correct so accuracy isn't unfairly dinged.
    func overrideLastToCorrect(structureName: String) {
        guard var s = stats[structureName], s.incorrectCount > 0 else { return }
        s.incorrectCount -= 1
        s.correctCount += 1
        stats[structureName] = s
        save()
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
        UserDefaults.standard.removeObject(forKey: udKey)
        CloudSync.set(nil, forKey: udKey)
        CloudSync.flush()
    }

    // MARK: - Persistence (local UserDefaults + iCloud key-value mirror)
    private func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        UserDefaults.standard.set(data, forKey: udKey)
        CloudSync.set(data, forKey: udKey)
        CloudSync.flush()
    }
    private func load() {
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
