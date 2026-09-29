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

    struct QProgress: Codable {
        var seen: Int = 0            // attempts (whole-sentence)
        var correct: Int = 0         // attempts where EVERY gap was right
        var reps: Int = 0            // consecutive all-correct passes (drives interval + mastery)
        var lastSeen: Date = .distantPast
        var due: Date = Date()       // next recommended time (new = now)
        var intervalDays: Double = 0
    }

    @Published private(set) var progress: [String: QProgress] = [:]

    private let udKey = "DigAPigToo_FillBlankProgress"

    private init() {
        load()
        mergeFromCloud()
        CloudSync.observe { [weak self] in Task { @MainActor in self?.mergeFromCloud() } }
    }

    func entry(for prompt: String) -> QProgress { progress[prompt] ?? QProgress() }
    func isMastered(_ prompt: String) -> Bool { (progress[prompt]?.reps ?? 0) >= 2 }

    /// Record a completed sentence (all its gaps answered). `allCorrect` = every gap was right.
    func record(prompt: String, allCorrect: Bool) {
        var p = progress[prompt] ?? QProgress()
        p.seen += 1
        p.lastSeen = Date()
        if allCorrect {
            p.correct += 1
            p.reps += 1
            p.intervalDays = p.intervalDays == 0 ? 1 : min(p.intervalDays * 2.5, 60)
            p.due = Date().addingTimeInterval(p.intervalDays * 86_400)
        } else {
            p.reps = 0
            p.intervalDays = 0
            p.due = Date().addingTimeInterval(600)   // ~10 min → resurfaces later this session
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

    /// Counts over a question set, for the Stats tab.
    func summary(for questions: [FillBlankQuestion]) -> (studied: Int, mastered: Int, total: Int) {
        var studied = 0, mastered = 0
        for q in questions {
            if let p = progress[q.prompt], p.seen > 0 {
                studied += 1
                if p.reps >= 2 { mastered += 1 }
            }
        }
        return (studied, mastered, questions.count)
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
