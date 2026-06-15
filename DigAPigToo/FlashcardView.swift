//
//  FlashcardView.swift
//  DigAPigToo
//
//  Anki-style spaced-repetition flashcard study mode.
//  Flow: pick categories → study session (image front → flip → rate) → summary.
//  Only structures that HAVE an image are eligible (the image is the card front).
//

import SwiftUI

// MARK: - Setup / category picker

struct FlashcardView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @StateObject private var cards = FlashcardManager.shared

    /// Selected category IDs. Empty = none chosen yet.
    @State private var selected: Set<UUID> = []
    @State private var session: FlashcardSession?

    // Category groupings mirror the IDs page order.
    private var groups: [(title: String, categories: [AnatomyCategory])] {
        let cats = dataManager.categories
        func find(_ names: [String]) -> [AnatomyCategory] { names.compactMap { n in cats.first { $0.name == n } } }
        return [
            ("Terminology", find(["Anatomical Planes", "Directional Terminology"])),
            ("Gross Anatomy", find([
                "External", "Buccal Cavity", "Upper Thoracic", "Peritoneal Cavity",
                "Digestive System", "Respiratory System", "Circulatory System",
                "Urinary System", "Male Reproductive", "Female Reproductive",
                "Fetal Structures", "Adult Maternal Pig", "Cow Eye"])),
            ("Histology", find([
                "Blood Histology", "Vessel Histology", "Respiratory Histology",
                "Gastrointestinal Histology", "Liver Histology", "Pancreas Histology",
                "Kidney Histology", "Reproductive Histology"])),
            ("Other", find(["Epithelial Types", "Microscope"])),
        ].filter { !$0.categories.isEmpty }
    }

    /// Structures that are eligible as cards: in a selected category AND have ≥1 image.
    private func eligibleStructures() -> [AnatomyStructure] {
        dataManager.structures.filter { selected.contains($0.categoryId) && !$0.images.isEmpty }
    }

    /// Count of image-backed structures in a category.
    private func cardCount(_ category: AnatomyCategory) -> Int {
        dataManager.structures.filter { $0.categoryId == category.id && !$0.images.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let names = eligibleStructures().map { $0.name }
                    let due = cards.dueCount(from: names)
                    let total = names.count
                    Button {
                        startSession()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.stack.fill")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start Studying").fontWeight(.semibold)
                                Text(total == 0
                                     ? "Select categories below"
                                     : "\(due) due · \(total) cards selected")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .disabled(total == 0)
                } footer: {
                    Text("Image-backed structures from your selected categories. The image is the front of each card; tap to reveal the answer. Reviews are scheduled with spaced repetition.")
                }

                ForEach(groups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.categories) { category in
                            let count = cardCount(category)
                            Button {
                                toggle(category.id, enabled: count > 0)
                            } label: {
                                HStack {
                                    Image(systemName: selected.contains(category.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selected.contains(category.id) ? .blue : .secondary)
                                    Text(category.name)
                                        .foregroundStyle(count > 0 ? .primary : .secondary)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .disabled(count == 0)
                        }
                    }
                }
            }
            .navigationTitle("Flashcards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Select All") { selectAll() }
                        Button("Clear Selection") { selected.removeAll() }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .fullScreenCover(item: $session) { sess in
                FlashcardSessionView(session: sess)
            }
        }
    }

    private func toggle(_ id: UUID, enabled: Bool) {
        guard enabled else { return }
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func selectAll() {
        selected = Set(groups.flatMap { $0.categories }.filter { cardCount($0) > 0 }.map { $0.id })
    }

    private func startSession() {
        let pool = eligibleStructures()
        // Due cards first (new + overdue); if none are due, study the whole selection.
        let dueNames = Set(cards.dueCards(from: pool.map { $0.name }))
        let ordered: [AnatomyStructure]
        if dueNames.isEmpty {
            ordered = pool.shuffled()
        } else {
            ordered = pool.filter { dueNames.contains($0.name) }
        }
        guard !ordered.isEmpty else { return }
        session = FlashcardSession(structures: ordered)
    }
}

// MARK: - Session model

/// Identifiable wrapper so it can drive `.fullScreenCover(item:)`.
struct FlashcardSession: Identifiable {
    let id = UUID()
    let structures: [AnatomyStructure]
}

// MARK: - Study session view

struct FlashcardSessionView: View {
    let session: FlashcardSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cards = FlashcardManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared

    @State private var index = 0
    @State private var revealed = false
    @State private var ratedCount = 0
    @State private var ratingTally: [String: Int] = ["again": 0, "hard": 0, "good": 0, "easy": 0]

    private var current: AnatomyStructure? {
        guard index < session.structures.count else { return nil }
        return session.structures[index]
    }

    private func categoryName(_ s: AnatomyStructure) -> String {
        dataManager.categories.first { $0.id == s.categoryId }?.name ?? ""
    }

    var body: some View {
        NavigationStack {
            Group {
                if let s = current {
                    cardBody(for: s)
                } else {
                    summary
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if current != nil {
                        Text("\(index + 1) / \(session.structures.count)")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Card

    @ViewBuilder
    private func cardBody(for s: AnatomyStructure) -> some View {
        VStack(spacing: 0) {
            // Front: image (always visible)
            if let img = s.images.first {
                AnatomyImageView(image: img, fillsFrame: false, title: s.name,
                                 hideFullscreenTitle: !revealed)
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .background(Color.black.opacity(0.03))
            }

            // Back: revealed details
            ScrollView {
                if revealed {
                    answerDetails(for: s)
                        .padding()
                        .transition(.opacity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill").font(.title2).foregroundStyle(.secondary)
                        Text("Tap to reveal").font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }

            Spacer(minLength: 0)

            // Controls
            if revealed {
                ratingButtons(for: s)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { revealed = true }
                } label: {
                    Text("Show Answer")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !revealed { withAnimation(.easeInOut(duration: 0.2)) { revealed = true } }
        }
    }

    @ViewBuilder
    private func answerDetails(for s: AnatomyStructure) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(s.name).font(.title2).fontWeight(.bold)
                if s.highYield {
                    Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                }
            }
            // Category — labeled, so gross vs histology versions are never confused.
            Label(categoryName(s), systemImage: "folder.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.secondary.opacity(0.12))
                .cornerRadius(7)

            if !s.function.isEmpty {
                factBlock(title: "Function", icon: "bolt.fill", color: .blue, text: s.function)
            }
            if !s.examTips.isEmpty {
                factList(title: "Exam Tips", icon: "lightbulb.fill", color: .green, items: s.examTips)
            }
            if !s.commonConfusions.isEmpty {
                factList(title: "Common Confusions", icon: "exclamationmark.circle.fill", color: .orange, items: s.commonConfusions)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func factBlock(title: String, icon: String, color: Color, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.subheadline.weight(.semibold)).foregroundStyle(color)
            Text(text).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.07))
        .cornerRadius(10)
    }

    private func factList(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.subheadline.weight(.semibold)).foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: icon).font(.caption2).foregroundStyle(color)
                    Text(item).font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.07))
        .cornerRadius(10)
    }

    // MARK: Rating

    private func ratingButtons(for s: AnatomyStructure) -> some View {
        HStack(spacing: 8) {
            ratingButton("Again", .red, .again, for: s)
            ratingButton("Hard", .orange, .hard, for: s)
            ratingButton("Good", .blue, .good, for: s)
            ratingButton("Easy", .green, .easy, for: s)
        }
        .padding()
    }

    private func ratingButton(_ label: String, _ color: Color,
                              _ rating: FlashcardManager.Rating,
                              for s: AnatomyStructure) -> some View {
        Button {
            cards.record(name: s.name, rating: rating)
            ratingTally[key(rating), default: 0] += 1
            ratedCount += 1
            advance()
        } label: {
            VStack(spacing: 2) {
                Text(label).fontWeight(.semibold)
                Text(intervalPreview(s, rating)).font(.caption2).opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color)
            .foregroundStyle(.white)
            .cornerRadius(10)
        }
    }

    private func key(_ r: FlashcardManager.Rating) -> String {
        switch r { case .again: return "again"; case .hard: return "hard"; case .good: return "good"; case .easy: return "easy" }
    }

    /// Human-readable preview of the next interval if the user picks this rating.
    private func intervalPreview(_ s: AnatomyStructure, _ rating: FlashcardManager.Rating) -> String {
        let sched = cards.schedule(for: s.name)
        switch rating {
        case .again: return "10m"
        case .hard:  return sched.isNew ? "1d" : fmt(max(1, sched.intervalDays * 1.2))
        case .good:  return sched.isNew ? "1d" : (sched.reps == 1 ? "6d" : fmt(max(1, sched.intervalDays * sched.ease)))
        case .easy:  return sched.isNew ? "4d" : fmt(max(1, sched.intervalDays * sched.ease * 1.3))
        }
    }

    private func fmt(_ days: Double) -> String {
        if days >= 30 { return "\(Int((days / 30).rounded()))mo" }
        return "\(Int(days.rounded()))d"
    }

    private func advance() {
        revealed = false
        withAnimation(.easeInOut(duration: 0.15)) { index += 1 }
    }

    // MARK: Summary

    private var summary: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundStyle(.green)
            Text("Session Complete").font(.title2).fontWeight(.semibold)
            Text("\(ratedCount) card\(ratedCount == 1 ? "" : "s") reviewed")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                tally("Again", ratingTally["again"] ?? 0, .red)
                tally("Hard", ratingTally["hard"] ?? 0, .orange)
                tally("Good", ratingTally["good"] ?? 0, .blue)
                tally("Easy", ratingTally["easy"] ?? 0, .green)
            }
            .padding(.top, 4)

            Button {
                dismiss()
            } label: {
                Text("Finish").fontWeight(.semibold)
                    .frame(maxWidth: .infinity).padding()
                    .background(.blue).foregroundStyle(.white).cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding()
    }

    private func tally(_ label: String, _ count: Int, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.title3).fontWeight(.bold).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
