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

enum FlashcardMode: String, CaseIterable {
    case categories = "Categories"
    case decks = "Decks"
}

struct FlashcardView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @StateObject private var cards = FlashcardManager.shared
    @StateObject private var deckManager = DeckManager.shared

    @State private var mode: FlashcardMode = .categories
    /// Selected category IDs. Empty = none chosen yet.
    @State private var selected: Set<UUID> = []
    @State private var session: FlashcardSession?
    @State private var showingStats = false

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
            Group {
                switch mode {
                case .categories: categoryPicker
                case .decks:      DeckListView(session: $session)
                }
            }
            .navigationTitle("Flashcards")
            .safeAreaInset(edge: .top) {
                Picker("Mode", selection: $mode) {
                    ForEach(FlashcardMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingStats = true } label: { Image(systemName: "chart.bar.fill") }
                }
                if mode == .categories {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Select All") { selectAll() }
                            Button("Clear Selection") { selected.removeAll() }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
            }
            .fullScreenCover(item: $session) { sess in
                FlashcardSessionView(session: sess)
            }
            .sheet(isPresented: $showingStats) {
                FlashcardStatsView()
            }
        }
    }

    private var categoryPicker: some View {
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
    }

    private func toggle(_ id: UUID, enabled: Bool) {
        guard enabled else { return }
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
    }

    private func selectAll() {
        selected = Set(groups.flatMap { $0.categories }.filter { cardCount($0) > 0 }.map { $0.id })
    }

    private func startSession() {
        session = FlashcardSession.build(from: eligibleStructures())
    }
}

// MARK: - Session model

/// Identifiable wrapper so it can drive `.fullScreenCover(item:)`.
struct FlashcardSession: Identifiable {
    let id = UUID()
    let structures: [AnatomyStructure]

    /// Build a study session from an image-backed pool, in SRS study order:
    /// most-overdue reviewed cards first, then shuffled new cards. If nothing is due,
    /// the whole pool is shuffled so an extra pass is always possible. Returns nil if
    /// the pool is empty.
    @MainActor
    static func build(from pool: [AnatomyStructure]) -> FlashcardSession? {
        guard !pool.isEmpty else { return nil }
        let cards = FlashcardManager.shared
        let orderedNames = cards.dueCards(from: pool.map { $0.name })
        let byName = Dictionary(pool.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        var ordered = orderedNames.compactMap { byName[$0] }
        if ordered.isEmpty { ordered = pool.shuffled() }
        guard !ordered.isEmpty else { return nil }
        return FlashcardSession(structures: ordered)
    }
}

// MARK: - Study session view

struct FlashcardSessionView: View {
    let session: FlashcardSession
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cards = FlashcardManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared

    /// Live study queue. Cards in a learning/relearning step whose next due time falls
    /// within the session are re-inserted a few slots back (Anki keeps short-step cards
    /// in the current session; "Again" always brings the card back before you finish).
    @State private var queue: [AnatomyStructure] = []
    @State private var revealed = false
    @State private var ratedCount = 0            // total ratings (incl. repeats)
    @State private var uniqueCompleted = 0       // cards that left the queue for good
    @State private var ratingTally: [String: Int] = ["again": 0, "hard": 0, "good": 0, "easy": 0]

    /// Cards that graduated far enough to leave the session stay re-inserted no sooner
    /// than this many seconds out; anything longer means "not this session".
    private let sessionHorizon: TimeInterval = 20 * 60   // 20 min

    private var current: AnatomyStructure? { queue.first }

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
                        // Progress = cards fully done / starting count; queue can grow with
                        // repeats, so show remaining rather than a misleading "x / total".
                        Text("\(queue.count) left")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if queue.isEmpty && ratedCount == 0 {
                    queue = session.structures
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
            rate(s, rating)
        } label: {
            VStack(spacing: 2) {
                Text(label).fontWeight(.semibold)
                Text(cards.previewLabel(for: s.name, rating: rating)).font(.caption2).opacity(0.85)
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

    /// Apply a rating and update the live queue.
    private func rate(_ s: AnatomyStructure, _ rating: FlashcardManager.Rating) {
        let now = Date()
        let updated = cards.record(name: s.name, rating: rating, now: now)
        ratingTally[key(rating), default: 0] += 1
        ratedCount += 1

        // Remove the card from the front of the queue.
        if !queue.isEmpty { queue.removeFirst() }

        // If it's still in a (re)learning step due soon, keep it in this session by
        // re-inserting it a few positions back (so a couple of other cards come first).
        let secondsUntilDue = updated.due.timeIntervalSince(now)
        let stillLearning = (updated.phase == .learning || updated.phase == .relearning)
        if stillLearning && secondsUntilDue <= sessionHorizon {
            let insertAt = min(queue.count, 3)   // ~3 cards later, like Anki's step burying
            queue.insert(s, at: insertAt)
        } else {
            uniqueCompleted += 1
        }

        revealed = false
    }

    // MARK: Summary

    private var summary: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundStyle(.green)
            Text("Session Complete").font(.title2).fontWeight(.semibold)
            Text("\(uniqueCompleted) card\(uniqueCompleted == 1 ? "" : "s") studied · \(ratedCount) rating\(ratedCount == 1 ? "" : "s")")
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

// MARK: - Deck list (Decks mode)

struct DeckListView: View {
    @Binding var session: FlashcardSession?
    @StateObject private var deckManager = DeckManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared
    @StateObject private var cards = FlashcardManager.shared

    @State private var showingNewDeck = false
    @State private var newDeckName = ""
    @State private var renaming: DeckManager.Deck?
    @State private var renameText = ""

    /// Image-backed structures for a deck's structure names, preserving deck order.
    private func structures(for deck: DeckManager.Deck) -> [AnatomyStructure] {
        let byName = Dictionary(dataManager.structures.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        return deck.structureNames.compactMap { byName[$0] }.filter { !$0.images.isEmpty }
    }

    var body: some View {
        List {
            if deckManager.decks.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.stack.badge.plus").font(.title).foregroundStyle(.secondary)
                        Text("No decks yet").font(.headline)
                        Text("Create a deck, then add cards to it from here or from any structure's detail page.")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                }
            }

            ForEach(deckManager.decks) { deck in
                Section {
                    let studyable = structures(for: deck)
                    let due = cards.dueCount(from: studyable.map { $0.name })
                    Button {
                        session = FlashcardSession.build(from: studyable)
                    } label: {
                        HStack {
                            Image(systemName: "play.circle.fill").foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Study \(deck.name)").fontWeight(.semibold).foregroundStyle(.primary)
                                Text(studyable.isEmpty
                                     ? "No image-backed cards yet"
                                     : "\(due) due · \(studyable.count) card\(studyable.count == 1 ? "" : "s")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .disabled(studyable.isEmpty)

                    NavigationLink {
                        DeckDetailView(deckID: deck.id)
                    } label: {
                        Label("Edit cards (\(deck.cardCount))", systemImage: "square.and.pencil")
                    }
                } header: {
                    Text(deck.name)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deckManager.deleteDeck(deck.id)
                    } label: { Label("Delete", systemImage: "trash") }
                    Button {
                        renaming = deck
                        renameText = deck.name
                    } label: { Label("Rename", systemImage: "pencil") }
                    .tint(.blue)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { newDeckName = ""; showingNewDeck = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Deck", isPresented: $showingNewDeck) {
            TextField("Deck name", text: $newDeckName)
            Button("Create") { deckManager.createDeck(name: newDeckName) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename Deck", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Deck name", text: $renameText)
            Button("Save") { if let d = renaming { deckManager.renameDeck(d.id, to: renameText) }; renaming = nil }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
    }
}

// MARK: - Deck detail (add/remove cards)

struct DeckDetailView: View {
    let deckID: UUID
    @StateObject private var deckManager = DeckManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var showingAdd = false

    private var deck: DeckManager.Deck? { deckManager.deck(deckID) }

    private func categoryName(_ name: String) -> String {
        guard let s = dataManager.structures.first(where: { $0.name == name }) else { return "" }
        return dataManager.categories.first { $0.id == s.categoryId }?.name ?? ""
    }

    var body: some View {
        List {
            if let deck {
                if deck.structureNames.isEmpty {
                    Text("No cards yet. Tap + to add structures.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(deck.structureNames, id: \.self) { name in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                            let cat = categoryName(name)
                            if !cat.isEmpty {
                                Text(cat).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { deckManager.remove(deck.structureNames[i], from: deckID) }
                    }
                }
            }
        }
        .navigationTitle(deck?.name ?? "Deck")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            DeckAddCardsView(deckID: deckID)
        }
    }
}

// MARK: - Add cards to a deck (searchable structure picker)

struct DeckAddCardsView: View {
    let deckID: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var deckManager = DeckManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var searchText = ""

    /// Only image-backed structures are useful as cards.
    private var candidates: [AnatomyStructure] {
        let base = dataManager.structures.filter { !$0.images.isEmpty }
        let sorted = base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.aliases.contains { a in a.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private func categoryName(_ s: AnatomyStructure) -> String {
        dataManager.categories.first { $0.id == s.categoryId }?.name ?? ""
    }

    var body: some View {
        NavigationStack {
            List(candidates) { s in
                let inDeck = deckManager.contains(s.name, in: deckID)
                Button {
                    deckManager.toggle(s.name, in: deckID)
                } label: {
                    HStack {
                        Image(systemName: inDeck ? "checkmark.circle.fill" : "plus.circle")
                            .foregroundStyle(inDeck ? .green : .blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.name).foregroundStyle(.primary)
                            let cat = categoryName(s)
                            if !cat.isEmpty { Text(cat).font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search structures")
            .navigationTitle("Add Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - Add-to-deck sheet (used from a structure's detail page)

struct AddToDeckSheet: View {
    let structureName: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var deckManager = DeckManager.shared
    @State private var showingNewDeck = false
    @State private var newDeckName = ""

    var body: some View {
        NavigationStack {
            List {
                if deckManager.decks.isEmpty {
                    Text("No decks yet. Create one below.").foregroundStyle(.secondary)
                }
                ForEach(deckManager.decks) { deck in
                    let inDeck = deckManager.contains(structureName, in: deck.id)
                    Button {
                        deckManager.toggle(structureName, in: deck.id)
                    } label: {
                        HStack {
                            Image(systemName: inDeck ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(inDeck ? .green : .secondary)
                            Text(deck.name).foregroundStyle(.primary)
                            Spacer()
                            Text("\(deck.cardCount)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Button {
                    newDeckName = ""; showingNewDeck = true
                } label: {
                    Label("New Deck", systemImage: "plus")
                }
            }
            .navigationTitle("Add to Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .alert("New Deck", isPresented: $showingNewDeck) {
                TextField("Deck name", text: $newDeckName)
                Button("Create") {
                    let deck = deckManager.createDeck(name: newDeckName)
                    deckManager.add(structureName, to: deck.id)
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Flashcard stats

/// Sheet wrapper — used by the chart button in the Flashcards tab.
struct FlashcardStatsView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            FlashcardStatsContent()
                .navigationTitle("Flashcard Progress")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
                }
        }
    }
}

/// The reusable flashcard-stats body (no navigation chrome), so it can appear both in
/// the Flashcards-tab sheet and inside the shared Stats tab.
struct FlashcardStatsContent: View {
    @StateObject private var cards = FlashcardManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var showResetConfirm = false

    /// All image-backed structures = the universe of possible cards.
    private var allCardNames: [String] {
        dataManager.structures.filter { !$0.images.isEmpty }.map { $0.name }
    }

    // Category groupings mirror the IDs page order.
    private var categoryOrder: [String] {
        ["Anatomical Planes", "Directional Terminology",
         "External", "Buccal Cavity", "Upper Thoracic", "Peritoneal Cavity",
         "Digestive System", "Respiratory System", "Circulatory System",
         "Urinary System", "Male Reproductive", "Female Reproductive",
         "Fetal Structures", "Adult Maternal Pig", "Cow Eye",
         "Blood Histology", "Vessel Histology", "Respiratory Histology",
         "Gastrointestinal Histology", "Liver Histology", "Pancreas Histology",
         "Kidney Histology", "Reproductive Histology",
         "Epithelial Types", "Microscope"]
    }

    private func names(in categoryName: String) -> [String] {
        guard let cat = dataManager.categories.first(where: { $0.name == categoryName }) else { return [] }
        return dataManager.structures.filter { $0.categoryId == cat.id && !$0.images.isEmpty }.map { $0.name }
    }

    var body: some View {
        let overall = cards.progress(over: allCardNames)
        Group {
            if overall.total == 0 {
                VStack(spacing: 16) {
                    Image(systemName: "rectangle.stack.badge.person.crop").font(.system(size: 52)).foregroundStyle(.secondary)
                    Text("No cards yet").font(.headline)
                    Text("Study some flashcards to start tracking your learning progress.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding()
            } else {
                statsList(overall: overall)
            }
        }
        .confirmationDialog("Reset all flashcard progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) { cards.resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently erases all scheduling and review history for every card. Your decks are NOT deleted. This cannot be undone — avoid doing this right before an exam.")
        }
    }

    @ViewBuilder
    private func statsList(overall: FlashcardManager.ProgressBreakdown) -> some View {
        List {
            // Overall progress
            Section("Overall") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Learned").font(.subheadline)
                        Spacer()
                        Text("\(overall.learned) / \(overall.total)  ·  \(Int(overall.learnedFraction * 100))%")
                            .font(.subheadline.monospacedDigit()).fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    progressBar(overall.learnedFraction, color: .blue)
                }
                .padding(.vertical, 2)

                statRow("New (not started)", overall.new, "circle.dashed", .gray)
                statRow("Learning", overall.learning, "hourglass", .orange)
                statRow("Young (review)", overall.young, "leaf.fill", .green)
                statRow("Mature (21+ day interval)", overall.mature, "tree.fill", .teal)
                HStack {
                    Label("Total reviews done", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text("\(cards.lifetimeReviews)").fontWeight(.semibold)
                }
                HStack {
                    Label("Due now", systemImage: "bell.badge.fill")
                    Spacer()
                    Text("\(cards.dueCount(from: allCardNames))").fontWeight(.semibold).foregroundStyle(.red)
                }
            }

            // Per-category progress (most-learned first for encouragement... or least? use least-learned first)
            let catRows: [(name: String, b: FlashcardManager.ProgressBreakdown)] = categoryOrder.compactMap { cat in
                let ns = names(in: cat)
                guard !ns.isEmpty else { return nil }
                return (cat, cards.progress(over: ns))
            }.sorted { $0.b.learnedFraction < $1.b.learnedFraction }
            if !catRows.isEmpty {
                Section("By Category (least learned first)") {
                    ForEach(catRows, id: \.name) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(row.name).font(.subheadline)
                                Spacer()
                                Text("\(Int(row.b.learnedFraction * 100))%")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(row.b.learnedFraction >= 0.75 ? .green : row.b.learnedFraction >= 0.4 ? .orange : .secondary)
                            }
                            progressBar(row.b.learnedFraction, color: row.b.learnedFraction >= 0.75 ? .green : row.b.learnedFraction >= 0.4 ? .orange : .blue)
                            Text("\(row.b.learned) / \(row.b.total) learned").font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Hardest cards
            let hardest = cards.hardestCards(among: allCardNames, limit: 12)
            if !hardest.isEmpty {
                Section("Toughest Cards — Most Lapses") {
                    ForEach(hardest, id: \.name) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).font(.subheadline)
                                Text("ease \(Int(item.ease * 100))%").font(.caption2).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(item.lapses)×")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.red)
                            Text("forgotten").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // What's next
            let next = cards.upcoming(among: allCardNames, limit: 8)
            if !next.isEmpty {
                Section("Coming Up Next") {
                    ForEach(next, id: \.name) { item in
                        HStack {
                            Text(item.name).font(.subheadline)
                            Spacer()
                            Text(FlashcardManager.dueLabel(item.due))
                                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("Reset Flashcard Progress", role: .destructive) { showResetConfirm = true }
            } footer: {
                Text("Erases review scheduling for all cards. Keeps your decks.")
            }
        }
    }

    private func statRow(_ label: String, _ value: Int, _ icon: String, _ color: Color) -> some View {
        HStack {
            Label(label, systemImage: icon).foregroundStyle(.primary)
            Spacer()
            Text("\(value)").fontWeight(.semibold).foregroundStyle(color)
        }
    }

    private func progressBar(_ fraction: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(.gray.opacity(0.15)).frame(height: 6)
                RoundedRectangle(cornerRadius: 3).fill(color)
                    .frame(width: max(0, geo.size.width * fraction), height: 6)
            }
        }
        .frame(height: 6)
    }
}
