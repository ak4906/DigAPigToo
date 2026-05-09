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
    private init() { load() }

    // MARK: - Record an answer
    func record(structureName: String, correct: Bool) {
        var s = stats[structureName] ?? StructureStat()
        if correct { s.correctCount += 1 } else { s.incorrectCount += 1 }
        s.lastSeen = Date()
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
    }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: udKey)
        }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([String: StructureStat].self, from: data)
        else { return }
        stats = decoded
    }
}
