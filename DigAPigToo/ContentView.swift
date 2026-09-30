//
//  ContentView.swift
//  DigAPigToo
//
//  Created by Alexander Knue on 5/8/26.
//

import SwiftUI
import PhotosUI
import UIKit

/// iPad-only layout scaling. `isPad` is true on iPad and on iPad apps running on Apple
/// Silicon Macs; iPhone (any orientation) stays exactly as designed. Used to enlarge
/// images that otherwise look tiny on the bigger screen.
extension UIDevice {
    static var isPad: Bool { current.userInterfaceIdiom == .pad }
}

extension View {
    /// Hardware-keyboard (Mac / iPad) shortcut: maps number keys 1–9 to a 0-based choice index,
    /// top to bottom. No-op past 9 (avoids a multi-digit key). Used for all multiple-choice lists.
    @ViewBuilder func numberKeyShortcut(_ index: Int) -> some View {
        if index < 9 {
            self.keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [])
        } else {
            self
        }
    }
}

/// iPhone: a fixed image height (unchanged). iPad: a fraction of the container's height,
/// so images scale proportionally across iPad sizes (mini → 12.9") and orientation
/// instead of a fixed pixel value.
struct AdaptiveImageHeight: ViewModifier {
    let phone: CGFloat
    let padFraction: CGFloat
    func body(content: Content) -> some View {
        if UIDevice.isPad {
            content.containerRelativeFrame(.vertical) { height, _ in height * padFraction }
        } else {
            content.frame(height: phone)
        }
    }
}

extension View {
    /// `phone` = fixed height on iPhone; `padFraction` = share of container height on iPad.
    func adaptiveImageHeight(phone: CGFloat, padFraction: CGFloat) -> some View {
        modifier(AdaptiveImageHeight(phone: phone, padFraction: padFraction))
    }
}

struct ContentView: View {
    @State private var selectedTab: Int = 0
    /// Tracks whether the IDs tab is at its root (no category drilled into). When inside
    /// a category, IDs tab-swipe is disabled so the category-level swipe takes over.
    @State private var idsAtRoot: Bool = true
    /// Same idea for Diagrams: disabled while viewing a diagram's image pager so the
    /// internal left/right image swipe isn't hijacked into a tab change.
    @State private var diagramsAtRoot: Bool = true
    /// Same idea for Search: disabled while paging through search results so the
    /// result pager's left/right swipe isn't hijacked into a tab change.
    @State private var searchAtRoot: Bool = true
    /// Same idea for Quiz: disabled while a quiz/exam is actually running so dragging to
    /// select text in an answer field doesn't get hijacked into a tab change.
    @State private var quizAtRoot: Bool = true
    private let lastTabIndex = 11

    var body: some View {
        TabView(selection: $selectedTab) {
            AtlasView(isAtRoot: $idsAtRoot)
                .tabItem { Label("IDs", systemImage: "photo.on.rectangle") }
                .tag(0)

            TracesView()
                .tabItem { Label("Traces", systemImage: "arrow.right.circle") }
                .tag(1)

            FlashcardView()
                .tabItem { Label("Flashcards", systemImage: "rectangle.stack.fill") }
                .tag(2)

            QuizCustomizationView(isAtRoot: $quizAtRoot)
                .tabItem { Label("Quiz", systemImage: "pencil") }
                .tag(3)

            FillBlankListView()
                .tabItem { Label("Fill-In", systemImage: "text.badge.plus") }
                .tag(4)

            SearchView(isAtRoot: $searchAtRoot)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(5)

            DiagramsView(isAtRoot: $diagramsAtRoot)
                .tabItem { Label("Diagrams", systemImage: "photo.stack.fill") }
                .tag(6)

            StatsView()
                .tabItem { Label("Stats & Ranking", systemImage: "chart.bar.fill") }
                .tag(7)

            GuideView()
                .tabItem { Label("Guide", systemImage: "book") }
                .tag(8)

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(9)

            UploadView()
                .tabItem { Label("Contribute", systemImage: "plus.app") }
                .tag(10)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(11)
        }
        // If the user opted into offline images, quietly pick up any newly-added
        // photos on launch so their downloaded set stays complete.
        .task { OfflineImageStore.shared.fetchMissingIfEnabled() }
    }
}

// MARK: - Tab swipe modifier

// MARK: - Atlas

enum AtlasViewMode {
    case byCategory
    case alphabetical
}

struct AtlasView: View {
    /// Reports nav-stack depth to ContentView so IDs tab-swipe disables inside a category.
    @Binding var isAtRoot: Bool
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var navPath = NavigationPath()
    @State private var viewMode: AtlasViewMode = .byCategory

    /// All structures sorted alphabetically (flat). Drives both the grouped list and the
    /// running "ID x/X" position counter.
    private var alphabeticalAll: [AnatomyStructure] {
        dataManager.structures.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func sectionLetter(for structure: AnatomyStructure) -> String {
        let first = structure.name.first.map { String($0).uppercased() } ?? "#"
        return first.first?.isLetter == true ? first : "#"
    }

    /// All structures sorted alphabetically, grouped into sections by first letter.
    private var alphabeticalGroups: [(letter: String, structures: [AnatomyStructure])] {
        let grouped = Dictionary(grouping: alphabeticalAll) { sectionLetter(for: $0) }
        return grouped.keys.sorted().map { (letter: $0, structures: grouped[$0] ?? []) }
    }

    // Ordered super-category groupings
    private var groups: [(title: String, systemImage: String, categories: [AnatomyCategory])] {
        let cats = dataManager.categories
        func find(_ name: String) -> AnatomyCategory? { cats.first { $0.name == name } }

        return [
            (
                title: "Terminology",
                systemImage: "character.book.closed.fill",
                categories: ["Anatomical Planes", "Directional Terminology"].compactMap { find($0) }
            ),
            (
                title: "Gross Anatomy",
                systemImage: "scissors",
                categories: [
                    "External", "Buccal Cavity", "Upper Thoracic", "Peritoneal Cavity",
                    "Digestive System", "Respiratory System", "Circulatory System",
                    "Urinary System", "Male Reproductive", "Female Reproductive",
                    "Fetal Structures", "Adult Maternal Pig", "Cow Eye"
                ].compactMap { find($0) }
            ),
            (
                title: "Histology",
                systemImage: "magnifyingglass.circle.fill",
                categories: [
                    "Blood Histology", "Vessel Histology", "Respiratory Histology",
                    "Gastrointestinal Histology", "Liver Histology", "Pancreas Histology",
                    "Kidney Histology", "Reproductive Histology"
                ].compactMap { find($0) }
            ),
            (
                title: "Epithelial Types",
                systemImage: "square.grid.2x2.fill",
                categories: ["Epithelial Types"].compactMap { find($0) }
            ),
            (
                title: "Microscopy",
                systemImage: "magnifyingglass.circle.fill",
                categories: ["Microscope"].compactMap { find($0) }
            ),
        ].filter { !$0.categories.isEmpty }
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                MiniLeaderboardView()
                // View-mode toggle lives in the body (not the toolbar): a trailing toolbar item
                // gets an extra bar-button chrome outline on iPad/Mac stacked on the segmented
                // control; in-body it shows a single clean outline like the other pickers.
                HStack {
                    Spacer()
                    Picker("View", selection: $viewMode) {
                        Image(systemName: "folder").tag(AtlasViewMode.byCategory)
                        Image(systemName: "textformat.abc").tag(AtlasViewMode.alphabetical)
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
                Group {
                    switch viewMode {
                    case .byCategory:   categoryList
                    case .alphabetical: alphabeticalList
                    }
                }
            }
            .navigationTitle("Dig a Pig Too")
            .navigationDestination(for: CategoryNavDestination.self) { dest in
                StructureListView(initialCategory: dest.category, initialScrollID: dest.scrollToID)
            }
            .navigationDestination(for: AlphabeticalNavDestination.self) { dest in
                // Alphabetical mode pages through the full alphabetical order.
                let all = dataManager.structures.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                StructurePagerView(
                    allStructures: all,
                    initialIndex: all.firstIndex(where: { $0.id == dest.structure.id }) ?? 0
                )
            }
        }
        .onChange(of: navPath.count) { _, count in
            isAtRoot = (count == 0)
        }
    }

    private var categoryList: some View {
        List {
            ForEach(groups, id: \.title) { group in
                Section {
                    ForEach(group.categories) { category in
                        NavigationLink(value: CategoryNavDestination(category)) {
                            Label {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(category.name)
                                            .font(.body)
                                        if !category.description.isEmpty {
                                            Text(category.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    let count = dataManager.structures.filter { $0.categoryId == category.id }.count
                                    Text("\(count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.trailing, 4)
                                }
                            } icon: {
                                let info = categoryIcon(category.name)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(info.color)
                                        .frame(width: 32, height: 32)
                                    if let asset = info.customAsset {
                                        Image(asset)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                            .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: info.symbol)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Label(group.title, systemImage: group.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var alphabeticalList: some View {
        let total = alphabeticalAll.count
        // Precompute each structure's 1-based position in the flat alphabetical order.
        let positionByID: [UUID: Int] = Dictionary(
            uniqueKeysWithValues: alphabeticalAll.enumerated().map { ($0.element.id, $0.offset + 1) }
        )
        return ScrollViewReader { proxy in
            List {
                ForEach(alphabeticalGroups, id: \.letter) { group in
                    Section {
                        ForEach(group.structures) { structure in
                            NavigationLink(value: AlphabeticalNavDestination(structure: structure)) {
                                HStack {
                                    Text(structure.name).font(.body)
                                    if dataManager.isHistologyStructure(structure) {
                                        Text("HISTOLOGY")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.purple)
                                            .padding(.horizontal, 5).padding(.vertical, 2)
                                            .background(.purple.opacity(0.15), in: Capsule())
                                    }
                                    Spacer()
                                    if let pos = positionByID[structure.id] {
                                        Text("\(pos)/\(total)")
                                            .font(.caption2.monospacedDigit())
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.letter)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("\(group.structures.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .id(group.letter)
                }
            }
            .overlay(alignment: .trailing) {
                alphabetIndexBar(proxy: proxy)
            }
        }
    }

    /// Vertical A–Z scrubber along the right edge. Dragging jumps the list to the nearest
    /// available letter section, mapping the touch's vertical position to a letter index.
    private func alphabetIndexBar(proxy: ScrollViewProxy) -> some View {
        let letters = alphabeticalGroups.map { $0.letter }
        return GeometryReader { geo in
            VStack(spacing: 1) {
                ForEach(letters, id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let count = letters.count
                        guard count > 0, geo.size.height > 0 else { return }
                        let fraction = max(0, min(0.9999, value.location.y / geo.size.height))
                        let idx = min(count - 1, Int(fraction * CGFloat(count)))
                        withAnimation(.none) { proxy.scrollTo(letters[idx], anchor: .top) }
                    }
            )
        }
        .frame(width: 18)
        .padding(.trailing, 2)
    }

    struct IconInfo {
        let symbol: String          // SF Symbol name (used when customAsset is nil)
        let color: Color
        let customAsset: String?    // Optional asset-catalog image name (rendered as template)

        init(symbol: String, color: Color, customAsset: String? = nil) {
            self.symbol = symbol
            self.color = color
            self.customAsset = customAsset
        }
    }

    private func categoryIcon(_ name: String) -> IconInfo {
        switch name {
        // Terminology
        case "Anatomical Planes":           return IconInfo(symbol: "square.split.2x2",                  color: .blue)
        case "Directional Terminology":     return IconInfo(symbol: "arrow.up.left.and.arrow.down.right", color: .blue)
        // Gross anatomy
        case "External":                    return IconInfo(symbol: "pawprint.fill",                      color: Color(red: 0.6, green: 0.35, blue: 0.1), customAsset: "External")
        case "Buccal Cavity":               return IconInfo(symbol: "mouth.fill",                         color: .pink)
        case "Upper Thoracic":              return IconInfo(symbol: "figure.arms.open",                   color: .indigo, customAsset: "UpperThoracic")
        case "Peritoneal Cavity":           return IconInfo(symbol: "circle.inset.filled",                color: .indigo, customAsset: "PeritonealCavity")
        case "Digestive System":            return IconInfo(symbol: "fork.knife",                         color: .orange, customAsset: "DigestiveSystem")
        case "Respiratory System":          return IconInfo(symbol: "lungs.fill",                         color: .cyan)
        case "Circulatory System":          return IconInfo(symbol: "heart.fill",                         color: .red)
        case "Urinary System":              return IconInfo(symbol: "drop.fill",                          color: Color(red: 0.9, green: 0.7, blue: 0.1), customAsset: "UrinarySystem")
        case "Male Reproductive":           return IconInfo(symbol: "figure.stand",                       color: .blue, customAsset: "MaleReproductive")
        case "Female Reproductive":         return IconInfo(symbol: "figure.stand.dress",                 color: .purple, customAsset: "FemaleReproductive")
        case "Fetal Structures":            return IconInfo(symbol: "figure.2.and.child.holdinghands",    color: .teal, customAsset: "FetalStructures")
        case "Adult Maternal Pig":          return IconInfo(symbol: "pawprint.fill",                      color: Color(red: 0.5, green: 0.25, blue: 0.05), customAsset: "AdultMaternalPig")
        case "Cow Eye":                     return IconInfo(symbol: "eye.fill",                           color: .green)
        // Histology — all use a consistent deep purple
        case "Blood Histology":             return IconInfo(symbol: "drop.fill",                          color: .purple)
        case "Vessel Histology":            return IconInfo(symbol: "waveform.path.ecg",                  color: .purple, customAsset: "VesselHistology")
        case "Respiratory Histology":       return IconInfo(symbol: "lungs.fill",                         color: .purple)
        case "Gastrointestinal Histology":  return IconInfo(symbol: "fork.knife",                         color: .purple, customAsset: "GIHistology")
        case "Liver Histology":             return IconInfo(symbol: "leaf.fill",                          color: .purple, customAsset: "LiverHistology")
        case "Pancreas Histology":          return IconInfo(symbol: "cross.case.fill",                    color: .purple, customAsset: "PancreasHistology")
        case "Kidney Histology":            return IconInfo(symbol: "drop.circle.fill",                   color: .purple, customAsset: "KidneyHistology")
        case "Reproductive Histology":      return IconInfo(symbol: "figure.2",                           color: .purple, customAsset: "ReproductiveHistology")
        // Other
        case "Epithelial Types":            return IconInfo(symbol: "square.grid.2x2.fill",               color: .indigo, customAsset: "EpithelialTypes")
        case "Microscope":                  return IconInfo(symbol: "magnifyingglass.circle.fill",         color: .gray, customAsset: "Microscope")
        default:                            return IconInfo(symbol: "circle.fill",                        color: .gray)
        }
    }
}

struct StructureListView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    /// Index into `orderedCategories` — drives the TabView selection so the user
    /// can swipe horizontally to navigate between adjacent categories.
    @State private var categoryIndex: Int
    /// Updated by onCurrentChanged (not onBack) so the list can be scrolled WHILE the
    /// pager is still covering it — the back animation then reveals it in the right place.
    @State private var pendingScrollID: UUID?

    init(initialCategory: AnatomyCategory, initialScrollID: UUID? = nil) {
        let ordered = Self.buildOrderedCategories()
        let idx = ordered.firstIndex(where: { $0.id == initialCategory.id }) ?? 0
        self._categoryIndex = State(initialValue: idx)
        self._pendingScrollID = State(initialValue: initialScrollID)
    }

    /// Ordered list of all categories, matching the order shown in AtlasView's groups.
    /// Built statically so it can be referenced from the initializer.
    private static func buildOrderedCategories() -> [AnatomyCategory] {
        let cats = AnatomyDataManager.shared.categories
        func find(_ name: String) -> AnatomyCategory? { cats.first { $0.name == name } }
        let names: [String] = [
            // Terminology
            "Anatomical Planes", "Directional Terminology",
            // Gross Anatomy
            "External", "Buccal Cavity", "Upper Thoracic", "Peritoneal Cavity",
            "Digestive System", "Respiratory System", "Circulatory System",
            "Urinary System", "Male Reproductive", "Female Reproductive",
            "Fetal Structures", "Adult Maternal Pig", "Cow Eye",
            // Histology
            "Blood Histology", "Vessel Histology", "Respiratory Histology",
            "Gastrointestinal Histology", "Liver Histology", "Pancreas Histology",
            "Kidney Histology", "Reproductive Histology",
            // Other
            "Epithelial Types", "Microscope",
        ]
        return names.compactMap(find)
    }

    private var orderedCategories: [AnatomyCategory] { Self.buildOrderedCategories() }
    private var displayCategory: AnatomyCategory { orderedCategories[categoryIndex] }

    var body: some View {
        let ordered = dataManager.orderedStructures

        TabView(selection: $categoryIndex) {
            ForEach(Array(orderedCategories.enumerated()), id: \.offset) { idx, category in
                categoryPage(for: category)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationTitle(displayCategory.name)
        // Destination defined at the outer level so it survives category swipes.
        .navigationDestination(for: AnatomyStructure.self) { structure in
            let idx = ordered.firstIndex(where: { $0.id == structure.id }) ?? 0
            StructurePagerView(
                allStructures: ordered,
                initialIndex: idx,
                onCurrentChanged: { current in
                    // 1. Instantly switch category if the structure pager crossed into a new one.
                    if let newIdx = orderedCategories.firstIndex(where: { $0.id == current.categoryId }),
                       newIdx != categoryIndex {
                        withTransaction(Transaction(animation: .none)) {
                            categoryIndex = newIdx
                        }
                    }
                    // 2. Pre-scroll the list NOW, while the pager still covers it.
                    pendingScrollID = current.id
                }
            )
        }
    }

    /// The list of structures for a single category. Each TabView page renders this.
    /// Histology categories are grouped into sections by their handout slide; all other
    /// categories show a flat list.
    @ViewBuilder
    private func categoryPage(for category: AnatomyCategory) -> some View {
        let structures = dataManager.structures(in: category)
        ScrollViewReader { proxy in
            Group {
                if dataManager.isHistologyCategory(category) {
                    List {
                        ForEach(dataManager.structuresBySlide(in: category), id: \.slide?.number) { group in
                            Section {
                                ForEach(group.structures) { structure in
                                    NavigationLink(value: structure) {
                                        Text(structure.name)
                                    }
                                    .id(structure.id)
                                }
                            } header: {
                                Text(group.slide?.displayTitle(in: category.name) ?? "Other")
                                    .font(.subheadline.weight(.semibold))
                                    .textCase(nil)
                            }
                        }
                    }
                } else if dataManager.hasSubcategories(category) {
                    List {
                        ForEach(dataManager.structuresBySubcategory(in: category), id: \.subcategory) { group in
                            Section {
                                ForEach(group.structures) { structure in
                                    NavigationLink(value: structure) {
                                        Text(structure.name)
                                    }
                                    .id(structure.id)
                                }
                            } header: {
                                Text(group.subcategory)
                                    .font(.subheadline.weight(.semibold))
                                    .textCase(nil)
                            }
                        }
                    }
                } else {
                    List(structures) { structure in
                        NavigationLink(value: structure) {
                            Text(structure.name)
                        }
                        .id(structure.id)
                    }
                }
            }
            .onChange(of: pendingScrollID) { _, id in
                guard let id else { return }
                // Only scroll if this page contains the target structure.
                guard structures.contains(where: { $0.id == id }) else { return }
                withAnimation(.none) { proxy.scrollTo(id, anchor: .center) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.none) { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
    }
}

struct StructureDetailView: View {
    let structure: AnatomyStructure
    /// Reports the structure the user ended on after browsing images in fullscreen, so
    /// the enclosing pager can follow along.
    var onFullscreenNavigate: ((UUID) -> Void)? = nil
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var showingAddToDeck = false

    private var categoryName: String {
        dataManager.categories.first { $0.id == structure.categoryId }?.name ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image gallery
                if !structure.images.isEmpty {
                    TabView {
                        ForEach(structure.images) { img in
                            AnatomyImageView(image: img, fillsFrame: false, title: structure.name,
                                             onFullscreenNavigate: onFullscreenNavigate)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .tabViewStyle(.page)
                    .adaptiveImageHeight(phone: 300, padFraction: 0.50)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray.opacity(0.15))
                        .adaptiveImageHeight(phone: 220, padFraction: 0.42)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo").font(.system(size: 50)).foregroundStyle(.secondary)
                                Text("No photos yet").font(.caption).foregroundStyle(.secondary)
                            }
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        Text(structure.name).font(.largeTitle).fontWeight(.bold)
                        Spacer()
                        if structure.highYield {
                            Label("High Yield", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.yellow.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }

                    if !categoryName.isEmpty {
                        Label(categoryName, systemImage: "folder.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.secondary.opacity(0.1))
                            .cornerRadius(7)
                    }

                    if !structure.aliases.isEmpty {
                        Text(structure.aliases.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !structure.function.isEmpty {
                        DetailSection(title: "Function", icon: "bolt.fill", color: .blue) {
                            Text(structure.function)
                        }
                    }

                    if !structure.histology.isEmpty {
                        DetailSection(title: "Histology / Epithelial Type", icon: "waveform.path.ecg", color: .purple) {
                            Text(structure.histology)
                        }
                    }

                    if !structure.connections.isEmpty {
                        DetailSection(title: "Connections & Pathway", icon: "arrow.right.circle.fill", color: .teal) {
                            Text(structure.connections)
                                .fontDesign(.monospaced)
                                .font(.caption)
                        }
                    }

                    if !structure.commonConfusions.isEmpty {
                        DetailSection(title: "Common Confusions", icon: "exclamationmark.circle.fill", color: .orange) {
                            ForEach(structure.commonConfusions, id: \.self) { c in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange).font(.caption)
                                    Text(c)
                                }
                            }
                        }
                    }

                    if !structure.examTips.isEmpty {
                        DetailSection(title: "Exam Tips", icon: "lightbulb.fill", color: .green) {
                            ForEach(structure.examTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "lightbulb.fill").foregroundStyle(.green).font(.caption)
                                    Text(tip)
                                }
                            }
                        }
                    }

                    Button {
                        showingAddToDeck = true
                    } label: {
                        Label("Add to Deck", systemImage: "rectangle.stack.badge.plus")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.blue.opacity(0.15))
                            .cornerRadius(10)
                    }

                    NavigationLink("Contribute a Photo") {
                        UploadPhotoForStructureView(structure: structure)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.blue.opacity(0.15))
                    .cornerRadius(10)
                }
                .padding()
            }
            .padding()
        }
        // navigationTitle is set by StructurePagerView when used in the atlas.
        // When navigated to directly (e.g. from Search), set it here as a fallback.
        .navigationTitle(structure.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddToDeck) {
            AddToDeckSheet(structureName: structure.name)
        }
    }
}

// MARK: - Atlas Navigation Destination

struct CategoryNavDestination: Hashable {
    let category: AnatomyCategory
    let scrollToID: UUID?
    init(_ category: AnatomyCategory, scrollTo id: UUID? = nil) {
        self.category = category
        self.scrollToID = id
    }
}

/// Distinct nav value for tapping a structure in the IDs Alphabetical view. Kept separate
/// from a plain AnatomyStructure destination so it does not collide with the one
/// StructureListView registers for category-mode paging.
struct AlphabeticalNavDestination: Hashable {
    let structure: AnatomyStructure
}

// MARK: - Structure Pager (swipe left/right between all structures in atlas order)

struct StructurePagerView: View {
    let allStructures: [AnatomyStructure]
    /// Called every time the user swipes to a new page — fires while the pager is still visible.
    /// StructureListView uses this to proactively update its displayed category, so that the
    /// correct list content is already rendered by the time the back animation begins.
    var onCurrentChanged: ((AnatomyStructure) -> Void)? = nil
    /// Called once when the pager disappears — used only for triggering the final scroll.
    var onBack: ((AnatomyStructure) -> Void)? = nil
    @State private var currentIndex: Int
    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    @State private var showSwipeHint = false

    init(allStructures: [AnatomyStructure], initialIndex: Int,
         onCurrentChanged: ((AnatomyStructure) -> Void)? = nil,
         onBack: ((AnatomyStructure) -> Void)? = nil) {
        self.allStructures = allStructures
        self.onCurrentChanged = onCurrentChanged
        self.onBack = onBack
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentIndex) {
                ForEach(Array(allStructures.enumerated()), id: \.element.id) { idx, structure in
                    StructureDetailView(structure: structure, onFullscreenNavigate: { structureID in
                        // Follow the fullscreen viewer: land on whichever structure the
                        // user last viewed in fullscreen.
                        if let newIdx = allStructures.firstIndex(where: { $0.id == structureID }) {
                            currentIndex = newIdx
                        }
                    })
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // First-time swipe hint overlay
            if showSwipeHint {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                    Text("Swipe to browse structures")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.black.opacity(0.65), in: Capsule())
                .padding(.bottom, 24)
                .transition(.opacity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(allStructures[currentIndex].name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(currentIndex + 1) / \(allStructures.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: currentIndex) { _, _ in
            // Proactive update — runs while pager is still on screen so the list
            // behind it is already correct before the back animation starts.
            onCurrentChanged?(allStructures[currentIndex])
            // Hide swipe hint on first swipe
            if showSwipeHint {
                withAnimation(.easeOut(duration: 0.3)) { showSwipeHint = false }
                hasSeenSwipeHint = true
            }
        }
        .onAppear {
            if !hasSeenSwipeHint && allStructures.count > 1 {
                // Brief delay so the view settles before hint appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeIn(duration: 0.3)) { showSwipeHint = true }
                    // No auto-dismiss — hint stays until the user swipes
                }
            }
        }
        .onDisappear {
            onBack?(allStructures[currentIndex])
        }
    }
}

// Renders a single AnatomyImage — local asset or remote URL, with zoom label
// Tap anywhere on the image to open a fullscreen pinch-to-zoom viewer.
/// Remote image with an explicit failed/retry state. SwiftUI's `AsyncImage` does NOT
/// re-attempt a load when connectivity returns, so a dropped image would otherwise sit
/// stuck on the spinner forever. This shows "Loading failed — tap to retry" on failure
/// (or after a load times out), and retrying forces a fresh request. `onLoaded` fires
/// once the load attempt RESOLVES — success or hard failure — so a caller gating on "all
/// images loaded" (quiz/exam timer) isn't hung forever by one image that won't load.
private struct RemoteImageView: View {
    let urlString: String
    var fillsFrame: Bool = true
    var onLoaded: (() -> Void)? = nil

    @State private var attempt = 0
    @State private var timedOut = false

    var body: some View {
        AsyncImage(url: OfflineImageStore.shared.loadURL(for: urlString)) { phase in
            switch phase {
            case .success(let img):
                imageContent(img).onAppear { onLoaded?() }
            case .failure:
                retry.onAppear { onLoaded?() }
            case .empty:
                Group {
                    if timedOut {
                        retry
                    } else {
                        Color.gray.opacity(0.1).overlay(ProgressView())
                    }
                }
                .task(id: attempt) {
                    timedOut = false
                    try? await Task.sleep(nanoseconds: 12_000_000_000)   // 12s load timeout
                    if !Task.isCancelled { timedOut = true }
                }
            @unknown default:
                Color.gray.opacity(0.1)
            }
        }
        .id(attempt)   // bumping `attempt` forces AsyncImage to reload
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private func imageContent(_ img: Image) -> some View {
        if fillsFrame {
            img.resizable().scaledToFill().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            img.resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var retry: some View {
        VStack(spacing: 6) {
            Image(systemName: "arrow.clockwise").font(.title2)
            Text("Loading failed").font(.caption).fontWeight(.medium)
            Text("Tap to retry").font(.caption2).foregroundStyle(.secondary)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.12))
        .contentShape(Rectangle())
        .onTapGesture { timedOut = false; attempt += 1 }
    }
}

struct AnatomyImageView: View {
    let image: AnatomyImage
    var fillsFrame: Bool = true        // false → scaledToFit (show full image, no cropping)
    var title: String = ""             // shown in fullscreen nav bar
    var fullscreenMode: FullscreenMode = .structure
    var hideFullscreenTitle: Bool = false  // true in quiz context — shows "?" instead of answer
    /// Reports the structure the user ended on when the fullscreen viewer closes.
    var onFullscreenNavigate: ((UUID) -> Void)? = nil
    /// Fired once the image resolves (success OR failure), so callers can e.g. start a
    /// quiz timer only after the photo is actually on screen.
    var onLoaded: (() -> Void)? = nil
    @State private var showFullscreen = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if image.isRemote {
                RemoteImageView(urlString: image.source, fillsFrame: fillsFrame, onLoaded: onLoaded)
                    .id(image.source)
            } else if let uiImg = UIImage(named: image.source) {
                Group {
                    if fillsFrame {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image(uiImage: uiImg).resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .onAppear { onLoaded?() }
            } else {
                Color.gray.opacity(0.15)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    .onAppear { onLoaded?() }
            }

            VStack(alignment: .trailing, spacing: 2) {
                // Tap-to-zoom hint
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption2)
                    .padding(5)
                    .background(.black.opacity(0.5))
                    .foregroundStyle(.white)
                    .cornerRadius(5)

                if !hideFullscreenTitle {
                    if let mag = image.magnification {
                        Text("\(mag)x").font(.caption.bold()).padding(6)
                            .background(.black.opacity(0.55)).foregroundStyle(.white)
                            .cornerRadius(6)
                    }
                    if !image.caption.isEmpty {
                        Text(image.caption).font(.caption2).padding(6)
                            .background(.black.opacity(0.45)).foregroundStyle(.white)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(8)
        }
        .background(Color.gray.opacity(0.1))
        .onTapGesture { showFullscreen = true }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageSheet(image: image, title: title, mode: fullscreenMode,
                                 hideTitle: hideFullscreenTitle,
                                 onDismissAt: onFullscreenNavigate)
        }
    }
}

// MARK: - Fullscreen Zoomable Image Sheet

enum FullscreenMode {
    case structure                    // swipe through all structures (one page each)
    case diagram([DiagramGroup])      // swipe through all diagram images only
}

/// One slot in the fullscreen pager.
private struct FullscreenEntry: Identifiable {
    let id: UUID               // stable: structure.id or image.id
    let title: String
    let image: AnatomyImage?   // nil = no photo for this structure
}

struct FullscreenImageSheet: View {
    let image: AnatomyImage        // tapped image — used to find initial position
    var title: String = ""
    var mode: FullscreenMode = .structure
    var hideTitle: Bool = false    // true in quiz — replaces structure name with "?" to avoid spoilers
    /// In .structure mode, reports the structure the user ended on so the underlying
    /// pager can follow along — you're dropped back at the structure you last viewed
    /// in fullscreen, not the one you entered from.
    var onDismissAt: ((UUID) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var currentIndex = 0
    @State private var dismissOffset: CGFloat = 0
    @State private var dismissOpacity: Double = 1.0
    @State private var isZoomed = false

    // MARK: Entry lists

    private func structureEntries() -> [FullscreenEntry] {
        // Find which structure owns the tapped image so we can show it specifically
        let tappedStructureId = dataManager.structures.first(where: { s in
            s.images.contains(where: { $0.id == image.id })
        })?.id

        return dataManager.orderedStructures.map { structure in
            let displayImage: AnatomyImage?
            if structure.id == tappedStructureId {
                // Show the exact image the user tapped
                displayImage = structure.images.first(where: { $0.id == image.id })
                              ?? structure.images.first
            } else {
                displayImage = structure.images.first   // nil if no photos
            }
            return FullscreenEntry(id: structure.id, title: structure.name, image: displayImage)
        }
    }

    private func diagramEntries(groups: [DiagramGroup]) -> [FullscreenEntry] {
        groups.flatMap { group in
            group.images.map { img in
                FullscreenEntry(id: img.id, title: group.title, image: img)
            }
        }
    }

    private var entries: [FullscreenEntry] {
        switch mode {
        case .structure:             return structureEntries()
        case .diagram(let groups):  return diagramEntries(groups: groups)
        }
    }

    private var initialIndex: Int {
        switch mode {
        case .structure:
            // Find the structure that contains the tapped image
            let tappedStructureId = dataManager.structures.first(where: { s in
                s.images.contains(where: { $0.id == image.id })
            })?.id
            return entries.firstIndex(where: { $0.id == tappedStructureId }) ?? 0
        case .diagram:
            return entries.firstIndex(where: { $0.image?.id == image.id }) ?? 0
        }
    }

    private var currentEntry: FullscreenEntry? {
        guard currentIndex < entries.count else { return nil }
        return entries[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Only the image TabView moves — nav bar stays fixed
                TabView(selection: $currentIndex) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        FullscreenPageView(image: entry.image, structureName: entry.title,
                                          isZoomed: $isZoomed)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                .offset(y: dismissOffset)
                .opacity(dismissOpacity)
            }
            .navigationTitle(hideTitle ? "?" : (currentEntry?.title ?? title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !hideTitle, let mag = currentEntry?.image?.magnification {
                        Text("\(mag)×")
                            .font(.caption.bold())
                            .lineLimit(1)
                            .fixedSize()
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.white.opacity(0.2))
                            .foregroundStyle(.white)
                            .cornerRadius(6)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear { currentIndex = initialIndex }
        .onChange(of: currentIndex) { _, _ in
            isZoomed = false
            // Keep the underlying pager in sync LIVE while swiping, so when the viewer
            // closes it's already on the right page — no flash of the original entry.
            if case .structure = mode, currentIndex < entries.count {
                onDismissAt?(entries[currentIndex].id)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard !isZoomed else { return }
                    let h = value.translation.height
                    let w = value.translation.width
                    guard abs(h) > abs(w) else { return }
                    dismissOffset = h
                    dismissOpacity = max(0.3, 1.0 - abs(h) / 400)
                }
                .onEnded { value in
                    guard !isZoomed else { return }
                    let h = value.translation.height
                    let w = value.translation.width
                    if abs(h) > abs(w) && abs(h) > 120 {
                        withAnimation(.easeOut(duration: 0.22)) {
                            dismissOffset = h > 0 ? 900 : -900
                            dismissOpacity = 0
                        }
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dismissOffset = 0
                            dismissOpacity = 1.0
                        }
                    }
                }
        )
    }
}

/// One page in the fullscreen pager — zoomable image or "no photo" placeholder.
private struct FullscreenPageView: View {
    let image: AnatomyImage?
    let structureName: String
    @Binding var isZoomed: Bool

    var body: some View {
        if let img = image {
            if img.isRemote, let url = OfflineImageStore.shared.loadURL(for: img.source) {
                AsyncZoomableImage(url: url, isZoomed: $isZoomed)
            } else if let uiImg = UIImage(named: img.source) {
                ZoomableUIImage(uiImage: uiImg, isZoomed: $isZoomed)
            } else {
                noPhotoPlaceholder
            }
        } else {
            noPhotoPlaceholder
        }
    }

    private var noPhotoPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.4))
            Text("No photo yet for")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Text(structureName)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Loads a remote image then hands it to ZoomableUIImage
struct AsyncZoomableImage: View {
    let url: URL
    @Binding var isZoomed: Bool
    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let img = loadedImage {
                ZoomableUIImage(uiImage: img, isZoomed: $isZoomed)
            } else {
                ProgressView().tint(.white)
            }
        }
        .task {
            guard loadedImage == nil else { return }
            if let data = try? await URLSession.shared.data(from: url).0,
               let img = UIImage(data: data) {
                loadedImage = img
            }
        }
    }
}

// UIScrollView wrapper — real pinch-to-zoom + pan, up to 6×
struct ZoomableUIImage: UIViewRepresentable {
    let uiImage: UIImage
    @Binding var isZoomed: Bool

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.backgroundColor = .black
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = context.coordinator

        let imageView = UIImageView(image: uiImage)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        // Double-tap to zoom in/out
        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(isZoomed: $isZoomed) }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?
        var isZoomed: Binding<Bool>

        init(isZoomed: Binding<Bool>) {
            self.isZoomed = isZoomed
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            self.scrollView = scrollView
            return imageView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            isZoomed.wrappedValue = scrollView.zoomScale > scrollView.minimumZoomScale
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let point = recognizer.location(in: imageView)
                let zoomRect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
                scrollView.zoom(to: zoomRect, animated: true)
            }
        }
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            content()
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(10)
    }
}

// MARK: - Traces

struct TracesView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared

    var grouped: [(String, [TraceQuestion])] {
        let cats = dataManager.traceCategories
        return cats.map { cat in (cat, dataManager.traces(in: cat)) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, items in
                    Section(header: Text(category).font(.headline)) {
                        ForEach(items) { trace in
                            NavigationLink {
                                TraceDetailView(trace: trace)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(trace.title).font(.subheadline).fontWeight(.semibold)
                                        Text(trace.scenario)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    Spacer()
                                    if trace.highYield {
                                        Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Trace Practice")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TraceDetailView: View {
    let trace: TraceQuestion
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var showStudy = false          // false = interactive card practice (default)
    @State private var showImages = true          // study mode: show/hide per-step thumbnails
    /// Image-backed structures resolved per step (computed once when the trace opens).
    @State private var stepStructures: [UUID: [AnatomyStructure]] = [:]

    var body: some View {
        Group {
            if showStudy {
                studyView
            } else {
                // Interactive card practice is the DEFAULT view for a trace.
                TracePracticeView(trace: trace, stepStructures: stepStructures)
            }
        }
        .navigationTitle(trace.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Resolve each step's structures once (best-effort text → image-backed structures).
            if stepStructures.isEmpty {
                for step in trace.steps {
                    stepStructures[step.id] = dataManager.structures(inTraceStep: step.text)
                }
            }
        }
        .toolbar {
            if showStudy {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showImages.toggle() } label: {
                        Image(systemName: showImages ? "photo.fill" : "photo")
                    }
                    .accessibilityLabel(showImages ? "Hide step images" : "Show step images")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(showStudy ? "Practice" : "Study") { showStudy.toggle() }
                    .font(.subheadline)
            }
        }
    }

    /// The full read-through of the trace (secondary to practice) — every step in order with
    /// its images, plus key points.
    private var studyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(trace.scenario)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.07))
                .cornerRadius(10)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Full Trace")
                        .font(.headline)
                        .padding(.bottom, 8)
                    ForEach(Array(trace.steps.enumerated()), id: \.element.id) { idx, step in
                        TraceStepRow(step: step, index: idx, isLast: idx == trace.steps.count - 1,
                                     structures: showImages ? (stepStructures[step.id] ?? []) : [])
                    }
                }
                .padding()
                .background(.gray.opacity(0.05))
                .cornerRadius(10)

                if !trace.keyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Key Points & Common Mistakes", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        ForEach(trace.keyPoints, id: \.self) { pt in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.orange).font(.caption)
                                Text(pt).font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(.orange.opacity(0.08))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }
}

struct TraceStepRow: View {
    let step: TraceStep
    let index: Int
    let isLast: Bool
    var structures: [AnatomyStructure] = []

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.isHighlight ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(step.isHighlight ? .white : .secondary)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)   // stretch to connect to the next step
                        .frame(minHeight: 24)
                }
            }
            .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(step.text)
                    .font(step.isHighlight ? .body.weight(.semibold) : .body)
                    .foregroundStyle(step.isHighlight ? .primary : .secondary)
                    .padding(.top, 1)

                // Best-effort images for the structures named in this step (tap → ID card).
                if !structures.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(structures) { s in
                                NavigationLink { StructureDetailView(structure: s) } label: {
                                    TraceThumb(image: s.images.first)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.leading, 8)
            .padding(.bottom, isLast ? 0 : 10)
        }
    }
}

/// Small tappable thumbnail for a structure shown alongside a trace step.
private struct TraceThumb: View {
    let image: AnatomyImage?
    var body: some View {
        Group {
            if let img = image {
                if img.isRemote {
                    AsyncImage(url: OfflineImageStore.shared.loadURL(for: img.source)) { phase in
                        if let i = phase.image { i.resizable().scaledToFill() }
                        else { Color.gray.opacity(0.12).overlay(ProgressView().scaleEffect(0.5)) }
                    }
                } else if let ui = UIImage(named: img.source) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.12).overlay(Image(systemName: "photo").font(.caption2).foregroundStyle(.secondary))
                }
            } else {
                Color.gray.opacity(0.12).overlay(Image(systemName: "photo").font(.caption2).foregroundStyle(.secondary))
            }
        }
        .frame(width: 46, height: 46)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(.gray.opacity(0.2)))
    }
}

// MARK: - Fill-in-the-Blank

struct FillBlankListView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @StateObject private var progressMgr = FillBlankProgressManager.shared
    @State private var selectedCategory: String = "All"
    @State private var mcatOnly = false

    var categories: [String] {
        ["All"] + Array(Set(dataManager.fillBlanks.map { $0.category })).sorted()
    }

    var filtered: [FillBlankQuestion] {
        dataManager.fillBlanks.filter {
            (selectedCategory == "All" || $0.category == selectedCategory) &&
            (!mcatOnly || $0.mcatRelevant)
        }
    }

    /// The filtered questions grouped into alphabetical category sections, so the unfiltered
    /// list is scannable. Flattening this (in order) gives the swipe-paging order.
    var displayGroups: [(category: String, items: [FillBlankQuestion])] {
        let items = filtered
        return Array(Set(items.map { $0.category })).sorted().map { c in
            (c, items.filter { $0.category == c })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                    Toggle("MCAT-relevant only", isOn: $mcatOnly)
                    NavigationLink {
                        FillBlankStudyView(questions: filtered, useSmartOrder: true)
                    } label: {
                        Label("Smart Review (\(filtered.count))", systemImage: "brain.head.profile")
                            .foregroundStyle(.indigo)
                    }
                    .disabled(filtered.isEmpty)
                    NavigationLink {
                        FillBlankStudyView(questions: filtered, useSmartOrder: false)
                    } label: {
                        Label("Browse All in Order (\(filtered.count))", systemImage: "list.number")
                    }
                    .disabled(filtered.isEmpty)
                    if !filtered.isEmpty {
                        let s = progressMgr.summary(for: filtered)
                        HStack {
                            Label("Mastered", systemImage: "checkmark.seal.fill")
                                .font(.caption).foregroundStyle(.green)
                            Spacer()
                            Text("\(s.mastered) / \(s.total)").font(.caption.bold()).foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Smart Review prioritizes new, missed, and least-recently-seen questions so you cycle through all of them. Browse All goes straight through by topic. Each fill-in starts as multiple choice; once you master it, it graduates to write-in (active recall) and can't be done as multiple choice anymore. Miss the write-in and it drops back to multiple choice.")
                }
                let groups = displayGroups
                let order = groups.flatMap { $0.items }
                let indexByID = Dictionary(order.enumerated().map { ($0.element.id, $0.offset) },
                                           uniquingKeysWith: { first, _ in first })
                ForEach(groups, id: \.category) { group in
                    Section(group.category) {
                        ForEach(group.items) { q in
                            NavigationLink {
                                FillBlankDetailView(questions: order, startAt: indexByID[q.id] ?? 0)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(q.prompt)
                                        .font(.subheadline)
                                        .lineLimit(2)
                                    if q.mcatRelevant {
                                        Text("MCAT")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 5).padding(.vertical, 1)
                                            .background(.purple.opacity(0.15))
                                            .foregroundStyle(.purple)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fill-in-the-Blank")
        }
    }
}

struct FillBlankDetailView: View {
    let questions: [FillBlankQuestion]
    @State private var index: Int

    /// Pager over the current (filtered) list — swipe left/right between adjacent fill-ins.
    init(questions: [FillBlankQuestion], startAt: Int) {
        self.questions = questions
        _index = State(initialValue: min(max(startAt, 0), max(questions.count - 1, 0)))
    }
    /// Single-question convenience (e.g. from Search) — no paging.
    init(question: FillBlankQuestion) {
        self.questions = [question]
        _index = State(initialValue: 0)
    }

    var body: some View {
        TabView(selection: $index) {
            ForEach(Array(questions.enumerated()), id: \.element.id) { i, q in
                FillBlankRevealCard(question: q, isActive: i == index).tag(i)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationTitle(questions.count > 1 ? "Fill-in \(index + 1) of \(questions.count)" : "Fill-in-the-Blank")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// One reveal-style fill-in card: question → "Reveal Answer" → answers + explanation.
private struct FillBlankRevealCard: View {
    let question: FillBlankQuestion
    var isActive: Bool = true          // only the on-screen pager card owns the space shortcut
    @State private var revealed = false

    // The sentence with blanks as blue placeholders, or (once revealed) filled in with the answers
    // in bold green so it reads as a complete sentence.
    private var renderedPrompt: AttributedString {
        let parts = question.prompt.components(separatedBy: "___")
        var s = AttributedString()
        for j in parts.indices {
            s += AttributedString(parts[j])
            guard j < question.answers.count else { continue }
            var chunk = AttributedString(revealed ? question.answers[j] : "____")
            chunk.foregroundColor = revealed ? .green : .blue
            chunk.font = .body.bold()
            s += chunk
        }
        return s
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(revealed ? "Answer" : "Question")
                        .font(.headline)
                        .foregroundStyle(revealed ? .green : .blue)
                    Text(renderedPrompt)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((revealed ? Color.green : Color.blue).opacity(0.07))
                .cornerRadius(10)

                if revealed {
                    if !question.explanation.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Why", systemImage: "lightbulb.fill")
                                .font(.subheadline)
                                .foregroundStyle(.green)
                            Text(question.explanation)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.green.opacity(0.08))
                        .cornerRadius(10)
                    }
                } else {
                    let revealButton = Button {
                        withAnimation { revealed = true }
                    } label: {
                        Label("Reveal Answer", systemImage: "eye.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .cornerRadius(10)
                    }
                    // Hardware keyboard: space reveals (only the visible pager card registers it).
                    if isActive {
                        revealButton.keyboardShortcut(.space, modifiers: [])
                    } else {
                        revealButton
                    }
                }

                Label(question.category, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .onChange(of: question.id) { revealed = false }
    }
}

// MARK: - Quiz

// Category name sets used for preset selection buttons
private let grossAnatomyCategoryNames: Set<String> = [
    "Anatomical Planes", "Directional Terminology", "External",
    "Buccal Cavity", "Upper Thoracic", "Peritoneal Cavity",
    "Digestive System", "Respiratory System", "Circulatory System",
    "Urinary System", "Male Reproductive", "Female Reproductive",
    "Fetal Structures", "Adult Maternal Pig", "Cow Eye"
]
private let histologyCategoryNames: Set<String> = [
    "Blood Histology", "Vessel Histology", "Respiratory Histology",
    "Gastrointestinal Histology", "Liver Histology", "Pancreas Histology",
    "Kidney Histology", "Reproductive Histology", "Microscope", "Epithelial Types"
]

struct QuizCustomizationView: View {
    /// Reports to ContentView whether we're on the setup screen (true) or inside a running
    /// quiz/exam (false), so the Quiz tab-swipe disables while running.
    @Binding var isAtRoot: Bool
    @StateObject private var dataManager = AnatomyDataManager.shared
    // Landscape (wider than tall) → lay the setting pickers side-by-side in columns; portrait
    // (taller than wide) → stack them. Driven by actual size (below) so it flips live on rotate
    // /resize and treats iPad portrait as portrait (size class alone can't tell iPad orientation).
    @State private var isWide = false

    // Regular quiz state
    @State private var numQuestions = 10
    @State private var timeSelection = 18   // -1 = custom, 0 = unlimited
    @State private var customTime = 18
    @State private var quizMode: QuizMode = .multipleChoice
    @State private var difficulty: QuizDifficulty = .easy   // multiple-choice distractor difficulty
    @State private var selectedCategoryIDs: Set<UUID> = []

    // Real Exam state
    @State private var numStations = 30
    @State private var stationTimeSelection = 90   // -1 = custom
    @State private var stationCustomTime = 90
    @State private var examGradeAtEnd = true       // true = reveal only after all stations (realistic)

    // Drives programmatic navigation from the Start button (a Button, not a
    // NavigationLink, so it matches the Flashcards "Start Studying" row exactly:
    // one chevron, and the label tints blue when enabled / dims when disabled).
    @State private var startRunner = false
    // Real Exam launches as a full-screen cover (no back-swipe gesture); quiz stays a nav push.
    @State private var showExam = false

    var effectiveQuizTime: Int   { timeSelection == -1 ? customTime : timeSelection }
    var effectiveStationTime: Int { stationTimeSelection == -1 ? stationCustomTime : stationTimeSelection }

    private var allIDs: Set<UUID> { Set(dataManager.categories.map { $0.id }) }

    // MARK: Individual setting controls (no Section wrapper) — reused by the compact stacked
    // layout and the wide/landscape side-by-side columns layout.

    /// A titled column for the wide layout: small caption label above the control.
    @ViewBuilder private func labeled<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased()).font(.caption2).foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var quizModeControl: some View {
        Picker("Mode", selection: $quizMode) {
            Text("Multiple Choice").tag(QuizMode.multipleChoice)
            Text("Write Answer").tag(QuizMode.writeAnswer)
            Text("Real Exam").tag(QuizMode.realExam)
        }
        .pickerStyle(.segmented)
        Group {
            switch quizMode {
            case .writeAnswer:
                Text("Write the structure name from memory. Minor spelling errors are accepted.")
            case .realExam:
                Text("Replicates the actual practical: stations of 5 IDs, structures grouped by organ system/region — just like real dissection setups.")
            case .multipleChoice:
                EmptyView()
            }
        }
        .font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private var numQuestionsControl: some View {
        Picker("Questions", selection: $numQuestions) {
            ForEach([5, 10, 15, 20], id: \.self) { Text("\($0)") }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder private var difficultyControl: some View {
        Picker("Difficulty", selection: $difficulty) {
            ForEach(QuizDifficulty.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        Text(difficulty.blurb).font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private var quizTimeControl: some View {
        Picker("Time", selection: $timeSelection) {
            Text("10s").tag(10)
            Text("18s").tag(18)
            Text("30s").tag(30)
            Text("∞").tag(0)
            Text("Custom").tag(-1)
        }
        .pickerStyle(.segmented)
        if timeSelection == 18 {
            Text("Real exam pace — ~90 s per station, 5 IDs each")
                .font(.caption).foregroundStyle(.secondary)
        }
        if timeSelection == -1 {
            Stepper("Custom: \(customTime) seconds", value: $customTime, in: 1...300, step: 1)
        }
    }

    @ViewBuilder private var stationsControl: some View {
        Picker("Stations", selection: $numStations) {
            ForEach([5, 10, 20, 30], id: \.self) { Text("\($0)") }
        }
        .pickerStyle(.segmented)
        Text("\(numStations) stations × 5 IDs = \(numStations * 5) total items")
            .font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private var stationTimeControl: some View {
        Picker("Time", selection: $stationTimeSelection) {
            Text("60s").tag(60)
            Text("90s").tag(90)
            Text("120s").tag(120)
            Text("Custom").tag(-1)
        }
        .pickerStyle(.segmented)
        if stationTimeSelection == 90 {
            Text("Real exam: 90 seconds per station")
                .font(.caption).foregroundStyle(.secondary)
        }
        if stationTimeSelection == -1 {
            Stepper("Custom: \(stationCustomTime) seconds",
                    value: $stationCustomTime, in: 30...300, step: 5)
        }
    }

    @ViewBuilder private var feedbackControl: some View {
        Picker("Feedback", selection: $examGradeAtEnd) {
            Text("At the end").tag(true)
            Text("After each station").tag(false)
        }
        .pickerStyle(.segmented)
        Text(examGradeAtEnd
             ? "Realistic: no answers are shown until you finish every station, like the actual practical."
             : "Study mode: each station is graded right after you submit it.")
            .font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private var examStructureControl: some View {
        let gross = Int((Double(numStations) * 22.0 / 30.0).rounded())
        let histo = numStations - gross
        Label("~\(gross) gross anatomy stations, ~\(histo) histology/microscope stations — structures grouped by organ system within each station", systemImage: "chart.pie")
            .font(.caption).foregroundStyle(.secondary)
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── Start (kept at the top so it's easy to find) ───────────
                Section {
                    Button {
                        if quizMode == .realExam { showExam = true } else { startRunner = true }
                    } label: {
                        if quizMode == .realExam {
                            StartRowLabel(title: "Start Exam",
                                          subtitle: "\(numStations) stations · \(effectiveStationTime)s each")
                        } else {
                            StartRowLabel(title: "Start Quiz",
                                          subtitle: selectedCategoryIDs.isEmpty
                                            ? "Select categories below"
                                            : "\(numQuestions) questions · \(selectedCategoryIDs.count) categories")
                        }
                    }
                    .disabled(quizMode != .realExam && selectedCategoryIDs.isEmpty)
                }

                // ── Settings: stacked when portrait; side-by-side columns when landscape ──
                if isWide {
                    Section {
                        HStack(alignment: .top, spacing: 24) {
                            labeled("Quiz Mode") { quizModeControl }
                            if quizMode == .realExam {
                                labeled("Stations") { stationsControl }
                                labeled("Time / Station") { stationTimeControl }
                            } else {
                                labeled("Questions") { numQuestionsControl }
                                if quizMode == .multipleChoice {
                                    labeled("Difficulty") { difficultyControl }
                                }
                            }
                        }
                        if quizMode == .realExam {
                            labeled("Feedback") { feedbackControl }
                            examStructureControl
                        } else {
                            labeled("Time / Question") { quizTimeControl }
                        }
                    }
                } else {
                    Section { quizModeControl } header: { Text("Quiz Mode") }
                    if quizMode == .realExam {
                        Section { stationsControl } header: { Text("Number of Stations") }
                        Section { stationTimeControl } header: { Text("Time Per Station") }
                        Section { feedbackControl } header: { Text("Feedback") }
                        Section { examStructureControl } header: { Text("Exam Structure") }
                    } else {
                        Section { numQuestionsControl } header: { Text("Number of Questions") }
                        if quizMode == .multipleChoice {
                            Section { difficultyControl } header: { Text("Difficulty") }
                        }
                        Section { quizTimeControl } header: { Text("Time Per Question") }
                    }
                }

                // Category picker (not for Real Exam, which auto-builds its own categories).
                if quizMode != .realExam {
                    CategoryPickerSections(
                        selected: $selectedCategoryIDs,
                        count: { dataManager.structures(in: $0).count }
                    )
                }
            }
            // Measure the form's own size to pick columns (landscape) vs stacked (portrait);
            // updates live on rotate / window resize.
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { isWide = geo.size.width > geo.size.height }
                        .onChange(of: geo.size) { isWide = geo.size.width > geo.size.height }
                }
            }
            .navigationTitle("Quiz")
            .onAppear {
                if selectedCategoryIDs.isEmpty { selectedCategoryIDs = allIDs }
                isAtRoot = !(startRunner || showExam)
            }
            .onChange(of: startRunner) { isAtRoot = !(startRunner || showExam) }
            .onChange(of: showExam) { isAtRoot = !(startRunner || showExam) }
            .navigationDestination(isPresented: $startRunner) {
                QuizView(numQuestions: numQuestions, timePerQuestion: effectiveQuizTime,
                         selectedCategoryIDs: selectedCategoryIDs, quizMode: quizMode, difficulty: difficulty)
            }
            // Real Exam is a FULL-SCREEN COVER (not a nav push): a cover has NO back-swipe pop
            // gesture, so it's impossible to swipe out of the exam. Exit is via Close / Done.
            // Its own NavigationStack still lets tapping a graded answer push the ID card (and
            // swipe back from THAT to the exam), while the exam root itself can't be swiped away.
            .fullScreenCover(isPresented: $showExam) {
                NavigationStack {
                    ExamHostView(numStations: numStations, timePerStation: effectiveStationTime, gradeAtEnd: examGradeAtEnd)
                }
            }
        }
    }
}

struct QuizPresetButton: View {
    let label: String
    let action: () -> Void
    init(_ label: String, action: @escaping () -> Void) {
        self.label = label; self.action = action
    }
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .cornerRadius(8)
        }
    }
}

struct QuizView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var quizSession: QuizSession?
    @Environment(\.dismiss) var dismiss

    let numQuestions: Int
    let timePerQuestion: Int
    let selectedCategoryIDs: Set<UUID>
    let quizMode: QuizMode
    var difficulty: QuizDifficulty = .easy

    var body: some View {
        Group {
            if let session = quizSession {
                if session.isComplete {
                    QuizResultsView(quizSession: session, dismiss: dismiss)
                } else {
                    QuizQuestionView(quizSession: $quizSession)
                }
            } else {
                ProgressView("Preparing quiz...")
                    .onAppear(perform: startQuiz)
            }
        }
        .navigationBarTitle("Quiz", displayMode: .inline)
    }

    private func startQuiz() {
        let selectedCats = dataManager.categories.filter { selectedCategoryIDs.contains($0.id) }
        var pool: [AnatomyStructure] = selectedCats.isEmpty
            ? dataManager.structures
            : selectedCats.flatMap { dataManager.structures(in: $0) }
        pool.shuffle()
        let chosen = Array(pool.prefix(numQuestions))

        // Distractors are drawn per the chosen difficulty (Easy = anywhere, Hard = nearby).
        var questions: [QuizQuestion] = []
        for s in chosen {
            let distractors = dataManager.distractors(for: s, count: 3, difficulty: difficulty)
            questions.append(QuizQuestion(structure: s, distractors: distractors))
        }

        quizSession = QuizSession(questions: questions, timePerQuestion: TimeInterval(timePerQuestion), quizMode: quizMode)
    }
}

/// Quiz photo sizing: on iPhone multiple-choice the image fills the available height (so it's
/// as large as possible and the answer buttons drop to the bottom); otherwise the standard
/// fixed phone height / iPad fractional height.
private struct QuizPhotoSizing: ViewModifier {
    let fill: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if fill {
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content.adaptiveImageHeight(phone: 180, padFraction: 0.52)
        }
    }
}

struct QuizQuestionView: View {
    @Binding var quizSession: QuizSession?
    @StateObject private var statsManager = StatsManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared

    // Shared state
    @State private var isAnswered = false
    @State private var timer: Timer?
    @State private var timeRemaining: TimeInterval = 0
    @State private var questionStartDate: Date = Date()
    @State private var timerBegun = false          // countdown waits until the image is on screen
    @State private var showEndConfirm = false       // "Done — end quiz early?" dialog

    // Multiple-choice state
    @State private var shuffledChoices: [String] = []
    @State private var selectedAnswer: String?

    // Free-write state
    @State private var typedAnswer = ""
    @State private var freeWriteCorrect = false
    @State private var canOverride = false   // true only after a genuinely-submitted wrong answer
    @FocusState private var fieldFocused: Bool

    var body: some View {
        if let session = quizSession, session.currentQuestion != nil {
            VStack(spacing: 16) {
                // Header: progress + score
                HStack {
                    Text("Question \(session.currentQuestionIndex + 1)/\(session.questions.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Text("Score: \(session.score)")
                        .font(.subheadline.bold())
                }

                // Timer bar
                if session.timePerQuestion > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.2)).frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(timerColor)
                                .frame(width: max(0, CGFloat(timeRemaining / session.timePerQuestion)) * geo.size.width, height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("\(Int(ceil(timeRemaining)))s")
                        .font(.caption).foregroundStyle(timerColor).monospacedDigit()
                }

                // Photo. On iPhone multiple-choice, let the image FILL the space so it's as big
                // as possible and the options get pushed to the bottom (write-in already maxes
                // the image, and iPad uses the fractional height, so only iPhone-MC changes).
                let phoneMC = !UIDevice.isPad && session.quizMode == .multipleChoice
                Group {
                    if let q = session.currentQuestion, !q.structure.images.isEmpty {
                        let img = q.structure.images[min(q.imageIndex, q.structure.images.count - 1)]
                        AnatomyImageView(image: img, fillsFrame: false, title: q.structure.name,
                                         hideFullscreenTitle: true,
                                         onLoaded: { onImageLoaded() })
                            .id(img.id)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.15))
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo").font(.system(size: 40)).foregroundStyle(.secondary)
                                    Text("What structure is this?").font(.caption).foregroundStyle(.secondary)
                                }
                            )
                    }
                }
                .modifier(QuizPhotoSizing(fill: phoneMC))
                .clipped()

                // Answer area — branches on quiz mode
                if session.quizMode == .writeAnswer {
                    freeWriteAnswerArea(session: session)
                } else {
                    multipleChoiceAnswerArea(session: session)
                }

                // iPhone-MC: no trailing spacer — the filling image already pushes the options
                // to the bottom (just above the tab bar), maximizing image visibility.
                if !phoneMC { Spacer() }
            }
            .padding()
            .onChange(of: session.currentQuestionIndex) { resetForNewQuestion() }
            .onAppear {
                if shuffledChoices.isEmpty { resetForNewQuestion() }
                else { restartTimerFromDate() }
            }
            .onDisappear { stopTimer() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { pauseTimer(); showEndConfirm = true }
                }
            }
            .confirmationDialog("End quiz early?", isPresented: $showEndConfirm, titleVisibility: .visible) {
                Button("See Results") { finishEarly() }
                Button("Cancel", role: .cancel) { resumeTimer() }
            } message: {
                Text("You'll see results for the questions you've answered so far. Your progress is already saved to Stats.")
            }
        } else {
            ProgressView()
        }
    }

    /// End the quiz now and jump to results for whatever's been answered so far.
    private func finishEarly() {
        stopTimer()
        guard var s = quizSession else { return }
        s.currentQuestionIndex = s.questions.count
        quizSession = s
    }

    /// Pause/resume the countdown around the Done dialog (wall-clock based, so resume
    /// rebases the start date off the time that was left).
    private func pauseTimer() { stopTimer() }
    private func resumeTimer() {
        guard timerBegun, let session = quizSession, session.timePerQuestion > 0, !isAnswered else { return }
        questionStartDate = Date().addingTimeInterval(-(session.timePerQuestion - timeRemaining))
        startTimer()
    }

    // MARK: Multiple-choice answer buttons
    @ViewBuilder
    private func multipleChoiceAnswerArea(session: QuizSession) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(shuffledChoices.enumerated()), id: \.element) { i, choice in
                Button(action: { answerMultipleChoice(choice) }) {
                    Text(choice)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(mcButtonColor(choice: choice, session: session))
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(isAnswered)
                // Hardware keyboard (Mac / iPad): number keys 1–N pick the choice, top to bottom.
                .numberKeyShortcut(i)
            }
        }
    }

    // MARK: Free-write answer field
    @ViewBuilder
    private func freeWriteAnswerArea(session: QuizSession) -> some View {
        VStack(spacing: 12) {
            TextField("Type the structure name…", text: $typedAnswer)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($fieldFocused)
                .disabled(isAnswered)
                .onSubmit { submitFreeWrite(session: session) }

            if isAnswered {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: freeWriteCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(freeWriteCorrect ? .green : .red)
                            .font(.title3)
                        if freeWriteCorrect {
                            Text("Correct!").foregroundStyle(.green).fontWeight(.semibold)
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Incorrect").foregroundStyle(.red).fontWeight(.semibold)
                                if let q = session.currentQuestion {
                                    Text("Answer: \(q.structure.name)")
                                        .font(.subheadline).foregroundStyle(.primary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(freeWriteCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(10)

                    // A submitted wrong answer pauses here so the user can overturn a
                    // too-strict misgrade ("I got it right") or move on at their own pace.
                    if canOverride {
                        HStack(spacing: 10) {
                            Button { markGotItRight() } label: {
                                Label("I got it right", systemImage: "checkmark.circle")
                            }
                            .buttonStyle(.bordered)
                            .tint(.green)
                            Spacer()
                            Button("Next →") { advance() }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Button("Don't Know") { dontKnow(session: session) }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                    Button("Submit") { submitFreeWrite(session: session) }
                        .buttonStyle(.borderedProminent)
                        .disabled(typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: Timer helpers
    private var timerColor: Color {
        guard let session = quizSession, session.timePerQuestion > 0 else { return .blue }
        let ratio = timeRemaining / session.timePerQuestion
        if ratio > 0.5 { return .green }
        if ratio > 0.25 { return .orange }
        return .red
    }

    private func resetForNewQuestion() {
        stopTimer()
        guard let session = quizSession, let q = session.currentQuestion else { return }
        shuffledChoices = q.allChoices
        timeRemaining = session.timePerQuestion
        isAnswered = false
        selectedAnswer = nil
        typedAnswer = ""
        freeWriteCorrect = false
        canOverride = false
        timerBegun = false
        if session.quizMode == .writeAnswer { focusFieldSoon() }
        // Fair timing: the countdown starts only once the image is actually on screen
        // (onImageLoaded → beginTimer). A no-image question has nothing to wait for, so it
        // starts immediately. If an image fails to load the user gets a tap-to-retry and
        // the timer simply waits until it succeeds.
        if q.structure.images.isEmpty {
            beginTimer()
        }
    }

    /// Put the cursor in the answer box (and raise the keyboard) each new write-answer
    /// question. Deferred slightly because a synchronous @FocusState set on appear/change is
    /// usually dropped before the view is ready.
    private func focusFieldSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isAnswered { fieldFocused = true }
        }
    }

    /// Starts the countdown once — triggered by the image loading, the safety fallback,
    /// or a no-image question. Guarded so it only ever fires once per question.
    private func beginTimer() {
        guard !timerBegun, !isAnswered, let session = quizSession else { return }
        timerBegun = true
        guard session.timePerQuestion > 0 else { return }   // untimed mode: no countdown
        questionStartDate = Date()
        startTimer()
    }

    private func onImageLoaded() { beginTimer() }

    private func restartTimerFromDate() {
        guard timerBegun, let session = quizSession, session.timePerQuestion > 0, !isAnswered else { return }
        let elapsed = Date().timeIntervalSince(questionStartDate)
        timeRemaining = max(0, session.timePerQuestion - elapsed)
        if timeRemaining <= 0 { timeOut(); return }
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard let session = quizSession, session.timePerQuestion > 0 else { return }
            let elapsed = Date().timeIntervalSince(questionStartDate)
            let remaining = session.timePerQuestion - elapsed
            if remaining <= 0 {
                timeRemaining = 0
                timer?.invalidate()
                timeOut()
            } else {
                timeRemaining = remaining
            }
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    /// Ran out of time: record the current question as WRONG (so it's counted and shown in
    /// results) and move on. Guards against double-recording if already answered.
    private func timeOut() {
        guard var s = quizSession, let q = s.currentQuestion, !isAnswered else { advance(); return }
        stopTimer()
        isAnswered = true
        let catName = dataManager.categories.first { $0.id == q.structure.categoryId }?.name ?? "Unknown"
        s.answerHistory.append(AnswerRecord(
            structureID: q.structure.id,
            structureName: q.structure.name,
            categoryName: catName,
            givenAnswer: "(ran out of time)",
            wasCorrect: false
        ))
        quizSession = s
        statsManager.record(structureName: q.structure.name, correct: false)
        advance()
    }

    // MARK: Multiple-choice answer
    private func answerMultipleChoice(_ choice: String) {
        guard var session = quizSession, let q = session.currentQuestion else { return }
        stopTimer()
        isAnswered = true
        selectedAnswer = choice
        let correct = choice == q.structure.name
        let catName = dataManager.categories.first { $0.id == q.structure.categoryId }?.name ?? "Unknown"
        if correct { session.score += 1 }
        session.answerHistory.append(AnswerRecord(
            structureID: q.structure.id,
            structureName: q.structure.name,
            categoryName: catName,
            givenAnswer: choice,
            wasCorrect: correct
        ))
        quizSession = session
        statsManager.record(structureName: q.structure.name, correct: correct)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { advance() }
    }

    private func mcButtonColor(choice: String, session: QuizSession) -> Color {
        guard let q = session.currentQuestion else { return .blue }
        if !isAnswered { return .blue }
        if choice == q.structure.name { return .green }
        if choice == selectedAnswer { return .red }
        return .blue.opacity(0.35)
    }

    // MARK: Free-write answer
    private func submitFreeWrite(session: QuizSession) {
        guard var s = quizSession, let q = s.currentQuestion, !isAnswered else { return }
        stopTimer()
        fieldFocused = false
        isAnswered = true
        let correct = q.structure.accepts(answer: typedAnswer)
        freeWriteCorrect = correct
        let catName = dataManager.categories.first { $0.id == q.structure.categoryId }?.name ?? "Unknown"
        if correct { s.score += 1 }
        s.answerHistory.append(AnswerRecord(
            structureID: q.structure.id,
            structureName: q.structure.name,
            categoryName: catName,
            givenAnswer: typedAnswer.isEmpty ? "(no answer)" : typedAnswer,
            wasCorrect: correct
        ))
        quizSession = s
        statsManager.record(structureName: q.structure.name, correct: correct)
        if correct {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { advance() }
        } else {
            // Pause on a wrong answer: let the user override a misgrade or tap Next.
            canOverride = true
        }
    }

    // "I got it right" override — the fuzzy matcher marked a typed answer wrong but the
    // user knows it was right. Flip it to correct: bump the score, fix the answer record,
    // and move one stat from incorrect to correct.
    private func markGotItRight() {
        guard var s = quizSession, isAnswered, !freeWriteCorrect, let q = s.currentQuestion else { return }
        freeWriteCorrect = true
        canOverride = false
        s.score += 1
        if let last = s.answerHistory.indices.last {
            s.answerHistory[last].wasCorrect = true
        }
        quizSession = s
        statsManager.overrideLastToCorrect(structureName: q.structure.name)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { advance() }
    }

    private func dontKnow(session: QuizSession) {
        guard var s = quizSession, let q = s.currentQuestion, !isAnswered else { return }
        stopTimer()
        fieldFocused = false
        isAnswered = true
        freeWriteCorrect = false
        let catName = dataManager.categories.first { $0.id == q.structure.categoryId }?.name ?? "Unknown"
        s.answerHistory.append(AnswerRecord(
            structureID: q.structure.id,
            structureName: q.structure.name,
            categoryName: catName,
            givenAnswer: "(skipped)",
            wasCorrect: false
        ))
        quizSession = s
        statsManager.record(structureName: q.structure.name, correct: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { advance() }
    }

    private func advance() {
        stopTimer()
        if var session = quizSession {
            session.currentQuestionIndex += 1
            quizSession = session
        }
    }
}

struct QuizResultsView: View {
    let quizSession: QuizSession
    let dismiss: DismissAction
    @StateObject private var dataManager = AnatomyDataManager.shared

    var attempted: Int { quizSession.answerHistory.count }
    var total: Int { quizSession.questions.count }
    var pct: Int { attempted == 0 ? 0 : Int(Double(quizSession.score) / Double(attempted) * 100) }
    var grade: String {
        switch pct {
        case 90...100: return "Excellent! 🎉"
        case 75..<90:  return "Good work!"
        case 60..<75:  return "Getting there"
        default:       return "Keep studying"
        }
    }

    // Small cached thumbnail of a structure's first image (results recall aid).
    @ViewBuilder private func thumb(_ img: AnatomyImage?) -> some View {
        Group {
            if let img {
                if img.isRemote {
                    AsyncImage(url: OfflineImageStore.shared.loadURL(for: img.source)) { phase in
                        if let i = phase.image { i.resizable().scaledToFill() }
                        else { Color.gray.opacity(0.12).overlay(ProgressView().scaleEffect(0.6)) }
                    }
                } else if let ui = UIImage(named: img.source) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.12).overlay(Image(systemName: "photo").font(.caption).foregroundStyle(.secondary))
                }
            } else {
                Color.gray.opacity(0.12).overlay(Image(systemName: "photo").font(.caption).foregroundStyle(.secondary))
            }
        }
        .frame(width: 56, height: 56)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // A tappable row (thumbnail + labeled name) that opens a structure's detail page.
    @ViewBuilder private func answerLink(_ s: AnatomyStructure, label: String, symbol: String, tint: Color) -> some View {
        NavigationLink { StructureDetailView(structure: s) } label: {
            HStack(spacing: 10) {
                thumb(s.images.first)
                Image(systemName: symbol).foregroundStyle(tint).font(.subheadline)
                Text(label).font(.subheadline).foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    // One review entry: the correct answer (with image), plus — when wrong — what the user
    // chose (with image, tappable when it's a real structure) for a side-by-side compare.
    @ViewBuilder private func reviewEntry(_ record: AnswerRecord) -> some View {
        let correct = dataManager.structures.first { $0.id == record.structureID }
        let chosen = chosenStructure(for: record)
        VStack(alignment: .leading, spacing: 6) {
            if let correct {
                answerLink(correct,
                           label: record.wasCorrect ? correct.name : "Correct: \(correct.name)",
                           symbol: "checkmark.circle.fill", tint: .green)
            } else {
                Text(record.structureName).font(.subheadline).fontWeight(.semibold)
            }
            if !record.wasCorrect {
                if let chosen {
                    // "You chose" for MC; for a write-in, "You wrote" when it's an exact
                    // (case-insensitive) hit — 100% clear — else the fuzzy "You likely meant".
                    let typed = record.givenAnswer.trimmingCharacters(in: .whitespaces)
                    let isExact = ([chosen.name] + chosen.aliases).contains { $0.caseInsensitiveCompare(typed) == .orderedSame }
                    let verb = quizSession.quizMode != .writeAnswer ? "You chose"
                             : isExact ? "You wrote" : "You likely meant"
                    answerLink(chosen, label: "\(verb): \(chosen.name)",
                               symbol: "xmark.circle.fill", tint: .red)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.subheadline)
                        Text(unclearAnswer(record.givenAnswer)).font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(8)
        .background(record.wasCorrect ? Color.green.opacity(0.05) : Color.red.opacity(0.06))
        .cornerRadius(10)
    }

    /// Which structure a wrong answer points to: an exact name match (multiple choice), or
    /// for a typed answer the closest lenient match (same fuzzy logic as the answer box).
    /// nil when it's a skip/blank, a laterality near-miss of the correct answer (so we don't
    /// show a misleading unrelated guess), or the text is too far off to guess.
    private func chosenStructure(for record: AnswerRecord) -> AnatomyStructure? {
        guard !record.wasCorrect else { return nil }
        let a = record.givenAnswer
        if a == "(skipped)" || a == "(no answer)" || a == "(ran out of time)" || a.isEmpty { return nil }
        // Search INCLUDING the correct structure so a near-miss of it (e.g. "left gastric
        // artery" for "Gastric Artery") wins over unrelated structures; if the best match IS
        // the correct answer, suppress the guess (the correct answer is already displayed).
        let guess = dataManager.structures.first(where: { $0.name.caseInsensitiveCompare(a) == .orderedSame })
            ?? likelyStructure(for: a, among: dataManager.structures)
        guard let g = guess, g.id != record.structureID else { return nil }
        return g
    }

    private func unclearAnswer(_ a: String) -> String {
        switch a {
        case "(skipped)": return "Skipped"
        case "(ran out of time)": return "Ran out of time"
        case "(no answer)", "": return "No answer"
        default: return "Unclear which structure you meant (you wrote: \(a))"
        }
    }

    // Category breakdown from this quiz
    var categoryBreakdown: [(category: String, correct: Int, total: Int)] {
        let grouped = Dictionary(grouping: quizSession.answerHistory, by: { $0.categoryName })
        return grouped.map { cat, records in
            (category: cat,
             correct: records.filter { $0.wasCorrect }.count,
             total: records.count)
        }.sorted { $0.category < $1.category }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Score card
                VStack(spacing: 6) {
                    Text(grade).font(.title2).fontWeight(.semibold)
                    Text("\(quizSession.score) / \(attempted)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(pct >= 75 ? .green : pct >= 60 ? .orange : .red)
                    Text("\(pct)%").font(.title3).foregroundStyle(.secondary)
                    if attempted < total {
                        Text("Answered \(attempted) of \(total)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.gray.opacity(0.08))
                .cornerRadius(16)

                // Category breakdown
                if !categoryBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("By Category", systemImage: "chart.bar.fill")
                            .font(.headline).foregroundStyle(.blue)
                        ForEach(categoryBreakdown, id: \.category) { row in
                            HStack {
                                Text(row.category).font(.subheadline)
                                Spacer()
                                Text("\(row.correct)/\(row.total)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(row.correct == row.total ? .green : row.correct == 0 ? .red : .orange)
                            }
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.15)).frame(height: 6)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(row.correct == row.total ? Color.green : row.correct == 0 ? Color.red : Color.orange)
                                        .frame(width: geo.size.width * CGFloat(row.correct) / CGFloat(row.total), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                    .padding()
                    .background(.blue.opacity(0.06))
                    .cornerRadius(12)
                }

                // Review — every answered question, tap to open its info card
                if !quizSession.answerHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Review — tap any to learn more", systemImage: "hand.tap.fill")
                            .font(.headline).foregroundStyle(.blue)
                        ForEach(quizSession.answerHistory) { record in
                            reviewEntry(record)
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.06))
                    .cornerRadius(12)
                }

                // Long-term stats nudge
                VStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis").font(.title2).foregroundStyle(.purple)
                    Text("Long-term stats saved").font(.caption).foregroundStyle(.secondary)
                    Text("Check the Stats tab to see your weak spots").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Histology Scenario Data

/// One curated histology station scenario: 4 items (A–D).
/// E is always a random Microscope structure appended at build time.
struct HistoScenario {
    struct Entry {
        let prompt: String
        let answer: String   // exact AnatomyStructure.name OR free-text (slash = alternatives)
        var image: AnatomyImage? = nil   // exam-only photo override for THIS entry only
        var alsoAccept: [String] = []    // extra acceptable answers for THIS station only
    }
    let slideId: String      // "01", "02", …"20"
    let label: String        // e.g. "Slide #01 — Artery"
    let entries: [Entry]     // exactly 4
    /// One slide image shown on ALL of A–D (real practical: you view ONE fixed slide and
    /// answer A–D about it; only E is the microscope part). Set this to an arrow-annotated
    /// slide so B's "what does the arrow point to?" is supported. When set it wins over any
    /// per-entry `image`. nil → each entry falls back to its own image / structure image.
    var slideImage: AnatomyImage? = nil
}

private let _pA = "A. What organ / tissue is this?"
private let _pB = "B. What structure does the arrow point to?"
private let _pC = "C. Name a cell type or related structure."
private let _pD = "D. What is the function or product of C?"

/// All curated scenarios for all 20 slides.
/// `answer` is resolved at exam-build time: if an AnatomyStructure with that exact
/// name exists it becomes a structure-backed ExamItem; otherwise it becomes freeText.
private let allHistoScenarios: [HistoScenario] = {
    func e(_ prompt: String, _ answer: String, image: AnatomyImage? = nil, alsoAccept: [String] = []) -> HistoScenario.Entry {
        HistoScenario.Entry(prompt: prompt, answer: answer, image: image, alsoAccept: alsoAccept)
    }
    return [
        // SLIDE #01 — Artery / Vein / Nerve
        HistoScenario(slideId: "01", label: "Slide #01 — Artery", entries: [
            e(_pA, "Artery", image: ImageCDN.slide("artery-vein-nerve_histo_artery_1arrow.jpeg", magnification: 10, caption: "Artery")),
            e(_pB, "Tunica Media"),
            e(_pC, "Smooth muscle"),
            e(_pD, "Vasoconstriction/vasodilation"),
        ]),
        HistoScenario(slideId: "01", label: "Slide #01 — Vein", entries: [
            // Exam-only photo with a red arrow at the tunica adventitia (the IDs-page Vein
            // image stays un-annotated); the arrow is what B's prompt refers to.
            e(_pA, "Vein", image: ImageCDN.slide("artery-vein-nerve_histo_vein_1arrow.jpeg", magnification: 10, caption: "Vein")),
            e(_pB, "Tunica Adventitia"),
            e(_pC, "Endothelium/Simple squamous epithelium"),
            e(_pD, "Low-resistance blood return to heart"),
        ]),
        // (Removed the Slide #01 — Nerve scenario: the curriculum doesn't cover nerves/axons,
        // and there's no usable slide image for it — only the microscope part had a picture.)
        // SLIDE #02 — Trachea / Esophagus
        HistoScenario(slideId: "02", label: "Slide #02 — Trachea (cartilage)", entries: [
            e(_pA, "Trachea"),
            e(_pB, "Tracheal Cartilage"),
            e(_pC, "Respiratory Epithelium"),
            e(_pD, "Mucociliary clearance"),
        ]),
        HistoScenario(slideId: "02", label: "Slide #02 — Esophagus", entries: [
            // Explicit histo image: there are two "Esophagus" structures (gross + histo), so pin
            // the histology slide rather than relying on which one resolves first.
            e(_pA, "Esophagus", image: ImageCDN.slide("esophagus_histo_1.jpeg", magnification: 4, caption: "Esophagus")),
            e(_pB, "Submucosa"),   // arrow in this slide's photo points at the submucosa
            e(_pC, "Stratified squamous epithelium"),
            e(_pD, "Protection from abrasion"),
        ]),
        HistoScenario(slideId: "02", label: "Slide #02 — Trachea (glands)", entries: [
            // Show the trachea HISTOLOGY slide (sero-mucous glands), not the gross-anatomy
            // trachea photo the "Trachea" name resolves to — the B–D questions are histology.
            e(_pA, "Trachea", image: ImageCDN.slide("sero-mucous-glands-trachea_histo_1.jpeg", magnification: 10, caption: "Trachea")),
            e(_pB, "Sero-Mucous Glands"),
            e(_pC, "Mucous cells/Serous cells"),  // cell types within sero-mucous glands
            e(_pD, "Mucus secretion/Airway humidification"),
        ]),
        // SLIDE #03 — Mammal Ileum
        HistoScenario(slideId: "03", label: "Slide #03 — Ileum (Peyer's patches)", entries: [
            e(_pA, "Ileum"),
            e(_pB, "Peyer's Patches"),
            e(_pC, "Lymphocytes/Lymphoid tissue", alsoAccept: ["Lymphocyte", "Lymphoid follicle", "Lymphatic tissue", "Lymph tissue"]),
            e(_pD, "Immune surveillance", alsoAccept: ["Immune defense", "Immune response", "Mucosal immunity", "Fights infection"]),
        // Use the Peyer's-patches image for A–D (the default ileum photo has the real pointer on
        // the intestinal glands, which misleads the Peyer's-patches question).
        ], slideImage: ImageCDN.slide("peyers-patches_histo_1.jpeg", magnification: 4, caption: "Ileum")),
        HistoScenario(slideId: "03", label: "Slide #03 — Ileum (villi)", entries: [
            e(_pA, "Ileum"),
            e(_pB, "Villi"),
            e(_pC, "Enterocyte/Absorptive cell"),
            e(_pD, "Nutrient absorption"),
        ]),
        // SLIDE #04 — Cardiac Stomach
        HistoScenario(slideId: "04", label: "Slide #04 — Cardiac Stomach (glands)", entries: [
            e(_pA, "Cardiac Stomach", image: ImageCDN.slide("gastric-pits-cardiac-stomach_histo_1.heic", magnification: 4, caption: "Cardiac Stomach")),
            e(_pB, "Gastric Pits"),
            e(_pC, "Cardiac Glands"),
            e(_pD, "Mucus secretion"),
        ]),
        HistoScenario(slideId: "04", label: "Slide #04 — Cardiac Stomach (muscle)", entries: [
            e(_pA, "Cardiac Stomach", image: ImageCDN.slide("muscularis-cardiac-stomach_histo_1.png", magnification: 4, caption: "Cardiac Stomach")),
            e(_pB, "Muscularis"),
            e(_pC, "Smooth muscle"),
            e(_pD, "Mechanical mixing/Peristalsis", alsoAccept: ["Churning food", "Churning"]),
        ]),
        // SLIDE #05 — Large Intestine
        HistoScenario(slideId: "05", label: "Slide #05 — Large Intestine", entries: [
            e(_pA, "Large Intestine", image: ImageCDN.slide("intestinal-glands-large-intestine_histo_1.jpeg", magnification: 4, caption: "Large Intestine")),
            e(_pB, "Crypts of Lieberkühn"),
            e(_pC, "Goblet Cells", alsoAccept: ["Enterocyte", "Absorptive cell", "Enterocyte/Absorptive cell"]),
            e(_pD, "Mucus secretion", alsoAccept: ["Water absorption"]),
        ]),
        // SLIDE #06 — Mammal Jejunum
        HistoScenario(slideId: "06", label: "Slide #06 — Jejunum (villi)", entries: [
            e(_pA, "Jejunum", image: ImageCDN.slide("villi-jejunum_histo_1.jpeg", magnification: 10, caption: "Jejunum")),
            e(_pB, "Villi"),
            e(_pC, "Enterocyte/Absorptive cell"),
            e(_pD, "Nutrient absorption"),
        ]),
        HistoScenario(slideId: "06", label: "Slide #06 — Jejunum (crypts)", entries: [
            e(_pA, "Jejunum", image: ImageCDN.slide("intestinal-glands-jejunum_histo_1.jpeg", magnification: 10, caption: "Jejunum")),
            e(_pB, "Crypts of Lieberkühn"),       // B=crypt; C=cell type within B
            e(_pC, "Goblet Cells"),
            e(_pD, "Mucus secretion"),
        ]),
        // SLIDE #07 — Human Aorta
        HistoScenario(slideId: "07", label: "Slide #07 — Aorta (media)", entries: [
            e(_pA, "Aorta"),
            e(_pB, "Tunica Media"),
            e(_pC, "Elastic connective tissue/Elastic lamellae"),
            e(_pD, "Stretch in systole and recoil in diastole using elastic lamellae", alsoAccept: ["Elastic recoil", "Dampens pulse pressure", "Stretch and recoil"]),
        ], slideImage: ImageCDN.slide("aorta_histo_2.jpeg", magnification: 4, caption: "Aorta")),
        HistoScenario(slideId: "07", label: "Slide #07 — Aorta (intima)", entries: [
            e(_pA, "Aorta", image: ImageCDN.slide("aorta_histo_1exam.jpg", magnification: 4, caption: "Aorta")),
            e(_pB, "Tunica Intima"),
            e("C. What epithelial type does B exhibit?", "Endothelium/Simple squamous epithelium"),
            e(_pD, "Reduces friction for blood flow"),
        ]),
        // SLIDE #08 — Liver
        HistoScenario(slideId: "08", label: "Slide #08 — Liver (portal triad)", entries: [
            e(_pA, "Liver"),
            e(_pB, "Portal Triad"),
            e("C. What's the structure outlined in green?", "Bile duct"),
            e(_pD, "Bile transport"),
        ]),
        HistoScenario(slideId: "08", label: "Slide #08 — Liver (hepatocyte)", entries: [
            e(_pA, "Liver"),
            e(_pB, "Central Vein"),
            e("C. What kind of cell is abundant here?", "Hepatocyte"),
            e(_pD, "Detoxification/Metabolism"),
        ]),
        // SLIDE #09 — Mammal Pancreas
        HistoScenario(slideId: "09", label: "Slide #09 — Pancreas (islet)", entries: [
            e(_pA, "Pancreas"),
            e(_pB, "Islet of Langerhans"),
            e(_pC, "Alpha cells", alsoAccept: ["Beta cells"]),
            e(_pD, "Glucagon secretion", alsoAccept: ["Insulin secretion"]),
        ]),
        HistoScenario(slideId: "09", label: "Slide #09 — Pancreas (acinus)", entries: [
            e(_pA, "Pancreas"),
            e(_pB, "Acinus"),
            e(_pC, "Acinar Cells"),
            e(_pD, "Digestive enzyme secretion"),
        ]),
        // SLIDE #10 — Kidney
        HistoScenario(slideId: "10", label: "Slide #10 — Kidney (PCT)", entries: [
            // Uses the glomerulus slide (renal corpuscle in the centre, surrounded by tubules) so
            // B = a PCT tubule and C = the central glomerulus both read off the one image.
            e(_pA, "Kidney", image: ImageCDN.slide("glomerulus_histo_1.jpeg", magnification: 10, caption: "Kidney")),
            e(_pB, "Proximal Convoluted Tubule"),
            e("C. What's the big structure in the center?", "Glomerulus/Bowman's Capsule", alsoAccept: ["Glomerulus", "Bowman's Capsule", "Renal corpuscle"]),
            e(_pD, "Filtration of blood", alsoAccept: ["Blood filtration", "Ultrafiltration"]),
        ]),
        HistoScenario(slideId: "10", label: "Slide #10 — Kidney (DCT)", entries: [
            e(_pA, "Kidney"),
            e(_pB, "Distal Convoluted Tubule"),
            e("C. What epithelial type does B exhibit?", "Simple cuboidal epithelium"),
            e(_pD, "Active ion transport and regulation", alsoAccept: ["Ion/water regulation", "Ion regulation", "Reabsorption"]),
        ]),
        // SLIDE #11 — Mammal Duodenum
        HistoScenario(slideId: "11", label: "Slide #11 — Duodenum (Brunner's)", entries: [
            // A shows the same duodenum HISTOLOGY image as B, not the gross duodenum photo the name resolves to.
            e(_pA, "Duodenum", image: ImageCDN.slide("brunners-glands_histo_1.png", magnification: 10, caption: "Duodenum")),
            e(_pB, "Brunner's Glands"),
            e(_pC, "Mucous cells"),               // cell type inside Brunner's glands → mucus
            e(_pD, "Alkaline mucus secretion"),
        ]),
        HistoScenario(slideId: "11", label: "Slide #11 — Duodenum (villi)", entries: [
            e(_pA, "Duodenum", image: ImageCDN.slide("villi-duodenum_histo_1.jpg", magnification: 10, caption: "Duodenum")),
            e(_pB, "Villi"),
            e(_pC, "Enterocyte/Absorptive cell"),
            e(_pD, "Nutrient absorption"),
        ]),
        // SLIDE #12 — Mammal Fundic Stomach
        HistoScenario(slideId: "12", label: "Slide #12 — Fundic Stomach", entries: [
            e(_pA, "Fundic Stomach", image: ImageCDN.slide("fundic-glands_histo_1.png", magnification: 10, caption: "Fundic Stomach")),
            e(_pB, "Fundic Glands"),
            e(_pC, "Parietal cells", alsoAccept: ["Chief cells"]),
            e(_pD, "HCl secretion", alsoAccept: ["Hydrochloric acid secretion", "Pepsinogen secretion", "Pepsinogen"]),
        ]),
        // SLIDE #13 — Mammal Ovary
        HistoScenario(slideId: "13", label: "Slide #13 — Ovary (secondary follicle)", entries: [
            // A shows the ovary HISTOLOGY slide (same image as B), not the gross ovary photo
            // the "Ovary" name resolves to — "what tissue is this?" is about reading the slide.
            e(_pA, "Ovary", image: ImageCDN.slide("secondary-follicle_histo_1.HEIC", magnification: 10, caption: "Ovary")),
            e(_pB, "Secondary Follicle"),
            e("C. What is the big structure above B?", "Corpus Luteum"),
            e(_pD, "Progesterone production/Progesterone"),
        ]),
        HistoScenario(slideId: "13", label: "Slide #13 — Ovary (primary follicle)", entries: [
            // A shows the ovary HISTOLOGY slide (same image as B), not the gross ovary photo the
            // "Ovary" name resolves to — "what tissue is this?" is about reading the slide.
            e(_pA, "Ovary", image: ImageCDN.slide("primary-follicle_histo_1.jpg", magnification: 40, caption: "Ovary")),
            e(_pB, "Primary Follicle"),
            e("C. What does B contain?", "Primary Oocyte"),
            e("D. What maturation process does C undergo?", "Oogenesis"),
        ]),
        // SLIDE #14 — Lung Section
        HistoScenario(slideId: "14", label: "Slide #14 — Lung (bronchus)", entries: [
            e(_pA, "Lung", image: ImageCDN.slide("bronchus_histo_1.jpg", magnification: 4, caption: "Lung")),
            e(_pB, "Bronchus"),
            e("C. What is the thick structure bordering B?", "Cartilage", alsoAccept: ["Hyaline cartilage"]),
            e(_pD, "Structural support/Prevent collapse during breathing", alsoAccept: ["Prevents collapse", "Structural support", "Keeps airway open"]),
        ]),
        HistoScenario(slideId: "14", label: "Slide #14 — Lung (alveoli)", entries: [
            e(_pA, "Lung"),
            e(_pB, "Alveolar Sacs", alsoAccept: ["Alveoli", "Alveolus"]),
            e("C. What epithelial type does B exhibit?", "Simple squamous epithelium"),
            e(_pD, "Gas exchange/O2-CO2 exchange"),
        ]),
        // SLIDE #15 — Human Vena Cava
        HistoScenario(slideId: "15", label: "Slide #15 — Vena Cava (media)", entries: [
            e(_pA, "Vena Cava"),
            e(_pB, "Tunica Media"),
            e(_pC, "Smooth muscle"),
            e(_pD, "Venoconstriction/Venodilation", alsoAccept: ["Venoconstriction and venodilation", "Venoconstriction", "Venodilation"]),
        ]),
        HistoScenario(slideId: "15", label: "Slide #15 — Vena Cava (intima)", entries: [
            e(_pA, "Vena Cava", image: ImageCDN.slide("tunica-intima-vena-cava_histo_1.jpeg", magnification: 4, caption: "Vena Cava")),
            e(_pB, "Tunica Intima"),
            e(_pC, "Endothelium/Simple squamous epithelium"),
            e(_pD, "Minimizes blood flow resistance"),
        ]),
        // SLIDE #16 — Testis
        HistoScenario(slideId: "16", label: "Slide #16 — Testis (spermatogenesis)", entries: [
            e(_pA, "Testis"),
            e(_pB, "Seminiferous Tubule"),
            // Any spermatogenic stage counts (C graded independently of D), with each stage's
            // simple function accepted for D.
            e(_pC, "Spermatogonia", alsoAccept: ["Spermatocyte", "Primary spermatocyte", "Secondary spermatocyte", "Spermatid", "Spermatozoa", "Spermatozoon", "Sperm", "Sperm cell"]),
            e(_pD, "Mitosis to produce sperm cells", alsoAccept: [
                "Mitosis", "Stem cells for sperm production", "Renews the sperm supply",     // spermatogonia
                "Undergo meiosis", "Meiosis", "Halve the chromosome number",                 // spermatocyte
                "Mature into spermatozoa", "Mature into sperm", "Spermiogenesis",             // spermatid
                "Fertilize the egg", "Fertilization", "Fertilize the ovum",                   // spermatozoa
                "Spermatogenesis", "Produce sperm"]),
        ]),
        HistoScenario(slideId: "16", label: "Slide #16 — Testis (Leydig)", entries: [
            e(_pA, "Testis"),
            e(_pB, "Seminiferous Tubule"),        // B=tubule; C=adjacent Leydig cells
            e("C. What cells are clustered between each B?", "Leydig Cells"),
            e(_pD, "Testosterone secretion"),
        ]),
        // SLIDE #18 — Gall Bladder
        HistoScenario(slideId: "18", label: "Slide #18 — Gall Bladder (muscle)", entries: [
            e(_pA, "Gall Bladder"),
            e(_pB, "Muscularis"),
            e(_pC, "Smooth muscle"),
            e(_pD, "Bile ejection/Bile release"),
        ]),
        // SLIDE #19 — Blood Smear
        HistoScenario(slideId: "19", label: "Slide #19 — Blood Smear (RBC/platelet)", entries: [
            e(_pA, "Blood smear/Blood"),
            e(_pB, "Erythrocyte"),
            e("C. What is the small dot present besides B?", "Platelet"),
            e(_pD, "Hemostasis/Blood clotting"),
        ]),
        HistoScenario(slideId: "19", label: "Slide #19 — Blood Smear (WBC)", entries: [
            e(_pA, "Blood smear/Blood"),
            e(_pB, "Neutrophil"),
            e(_pC, "Lymphocyte"),
            e(_pD, "Immune response/Phagocytosis"),
        ]),
        // SLIDE #20 — Mammal Pyloric Stomach
        HistoScenario(slideId: "20", label: "Slide #20 — Pyloric Stomach (glands)", entries: [
            e(_pA, "Pyloric Stomach", image: ImageCDN.slide("gastric-pits-pyloric-stomach_histo_1.jpeg", magnification: 4, caption: "Pyloric Stomach")),
            e(_pB, "Gastric Pits"),
            e(_pC, "Pyloric Glands"),
            e(_pD, "Mucus secretion"),
        ]),
        HistoScenario(slideId: "20", label: "Slide #20 — Pyloric Stomach (gastrin)", entries: [
            e(_pA, "Pyloric Stomach"),
            // The arrow region can reasonably be called the pyloric mucosa too, so accept both.
            e(_pB, "Pyloric Glands", alsoAccept: ["Mucosa (Pyloric Stomach)", "Mucosa"]),  // B=gland; C=G cells within it
            e(_pC, "G Cells"),                    // G cells → gastrin secretion ✓
            e(_pD, "Gastrin secretion"),
        ]),
    ]
}()

// MARK: - Real Exam Mode

struct ExamHostView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var examSession: ExamSession?
    @Environment(\.dismiss) var dismiss

    let numStations: Int
    let timePerStation: Int
    var gradeAtEnd: Bool = true

    var body: some View {
        Group {
            if let session = examSession {
                if session.isComplete {
                    ExamResultsView(session: session, dismiss: dismiss, onOverride: { sIdx, iIdx in
                        guard var s = examSession, sIdx < s.stations.count,
                              iIdx < s.stations[sIdx].items.count,
                              !s.stations[sIdx].items[iIdx].wasCorrect else { return }
                        s.stations[sIdx].items[iIdx].wasCorrect = true
                        s.score += 1
                        if let name = s.stations[sIdx].items[iIdx].structure?.name {
                            StatsManager.shared.overrideLastToCorrect(structureName: name)
                        }
                        examSession = s
                        StatsManager.shared.recordExamScore(s.score)
                    })
                    .onAppear { StatsManager.shared.recordExamScore(session.score) }
                } else {
                    ExamStationView(examSession: $examSession)
                }
            } else {
                ProgressView("Building your exam…")
                    .onAppear(perform: buildExam)
            }
        }
        .navigationTitle("Exam")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func buildExam() {
        let tl = TimeInterval(timePerStation)
        let cats = dataManager.categories

        // MARK: Helpers

        // Gross-anatomy filter: exclude pure spaces/regions a TA cannot pin,
        // and abstract circulatory-pathway concepts that aren't physical structures.
        func isPinnable(_ name: String) -> Bool {
            let n = name.lowercased()
            return !n.hasSuffix(" cavity")       // pericardial/peritoneal/pleural cavity
                && !n.hasSuffix(" space")
                && n != "mediastinum"
                && !n.contains("circulation")    // Systemic Adult Circulation, Portal Circulation
                && !n.contains("trace")          // Maternal-to-Fetal Circulatory Trace
        }

        // Return all structures from the named categories.
        func structs(in catNames: [String]) -> [AnatomyStructure] {
            cats.filter { catNames.contains($0.name) }
                .flatMap { dataManager.structures(in: $0) }
        }

        // Build one station from an already-filtered pool (shuffles internally).
        func station(from pool: [AnatomyStructure]) -> ExamStation {
            let shuffled = pool.shuffled()
            guard !shuffled.isEmpty else { return ExamStation(items: [], timeLimit: tl) }
            // Take up to 5 DISTINCT structures — never repeat an ID within a station.
            // (Pools are sized ≥5; if one is ever smaller the station just shows fewer IDs
            // rather than duplicating a structure.)
            let items = shuffled.prefix(5).map { ExamItem(structure: $0) }
            return ExamStation(items: Array(items), timeLimit: tl)
        }

        // Build one gross station: applies isPinnable, then optional name exclusions.
        func grossStation(from catNames: [String],
                          exclude: Set<String> = []) -> ExamStation {
            var pool = structs(in: catNames).filter { !exclude.contains($0.name) }
            let pinnable = pool.filter { isPinnable($0.name) }
            if pinnable.count >= 3 { pool = pinnable }
            return station(from: pool)
        }

        // MARK: External sub-pools
        // The External category spans head, limbs, and ventral/fetal surface —
        // very different viewing angles. Split so each station sees one region.
        let extAll = structs(in: ["External"])
        let extHeadNames: Set<String> = [
            "Rostral Plate", "External Nostril", "Auricle", "External Acoustic Meatus",
            "Eyelid", "Nictitating Membrane"
        ]
        let extHead = extAll.filter {  extHeadNames.contains($0.name) }
        let extBody = extAll.filter { !extHeadNames.contains($0.name) }

        // MARK: Circulatory sub-pools
        // All structures in Circulatory System, with abstract concepts removed.
        let circAll = structs(in: ["Circulatory System"]).filter { isPinnable($0.name) }

        // Two cardiac preparation contexts — fundamentally different specimens.
        //
        // Cow heart (isolated adult, cut open): internal anatomy is visible.
        // Valves, chordae, and chamber detail only seen when heart is sectioned.
        let cowHeartNames: Set<String> = [
            "Heart", "Right Atrium", "Left Atrium", "Right Ventricle", "Left Ventricle",
            "Auricles", "Tricuspid Valve", "Bicuspid Valve", "Pulmonary Valve",
            "Aortic Valve", "Chordae Tendineae",
            "Pulmonary Trunk", "Ascending Aorta",      // truncated vessel stumps on isolated heart
            "Left Coronary Artery", "Great Cardiac Vein", "Coronary Sinus"
        ]
        // Fetal pig heart in situ (not cut open): only external anatomy visible.
        // Valves and chordae are inaccessible without opening the heart, so excluded.
        // The surrounding thoracic vessels (aorta, vena cava, etc.) are the focus here.
        let fetalPigCardiacNames: Set<String> = [
            "Heart", "Right Atrium", "Left Atrium", "Right Ventricle", "Left Ventricle",
            "Auricles", "Left Coronary Artery", "Great Cardiac Vein", "Coronary Sinus",
            "Left Azygos Vein"
        ]
        let thoracicVesselNames: Set<String> = [
            "Left Azygos Vein", "Ascending Aorta", "Arch of the Aorta",
            "Descending Aorta", "Brachiocephalic Trunk", "Common Carotid Arteries",
            "External Jugular Veins", "Internal Jugular Veins", "Brachiocephalic Veins",
            "Pulmonary Trunk", "Pulmonary Arteries", "Pulmonary Veins",
            "Cranial Vena Cava", "Caudal Vena Cava", "Subclavian Arteries",
            "Subclavian Veins", "Axillary Arteries", "Axillary Veins", "Thyrocervical Trunk",
            "Internal Thoracic Arteries", "Internal Thoracic Veins", "External Thoracic Arteries",
            "Subscapular Veins", "Costocervical Veins"
        ]
        let abdominalVesselNames: Set<String> = [
            "Celiac Artery", "Hepatic Artery", "Hepatic Portal Vein", "Liver Sinusoids",
            "Hepatic Vein", "Cranial Mesenteric Artery", "Caudal Mesenteric Artery",
            "Mesenteric Vein", "Jejunal Arteries", "Jejunal Veins",
            "Gastric Artery", "Gastric Vein", "Gastroepiploic Artery", "Gastroepiploic Vein",
            "Splenic Artery", "Splenic Vein", "Splenogastric Vein", "Renal Arteries", "Renal Veins"
        ]
        // Pelvic vessels split: sex-neutral vessels shared by both sexes,
        // plus gonadal vessels that are sex-exclusive — never mix male + female
        // gonadal vessels in the same station (one pig is one sex).
        let pelvicNeutralNames: Set<String> = [
            "Common Iliac Vein", "Internal Iliac Artery", "Internal Iliac Vein",
            "External Iliac Artery", "External Iliac Vein",
            "Deep Femoral Artery", "Deep Femoral Vein",
            "Deep Circumflex Iliac Artery", "Deep Circumflex Iliac Vein"
        ]
        let pelvicMaleNames:   Set<String> = ["Testicular Artery", "Testicular Vein"]
        let pelvicFemaleNames: Set<String> = ["Ovarian Artery", "Ovarian Vein"]

        let circCowHeart     = circAll.filter { cowHeartNames.contains($0.name) }
        let circFetalCardiac = circAll.filter { fetalPigCardiacNames.contains($0.name) }
        let circThoracic     = circAll.filter { thoracicVesselNames.contains($0.name) }
        let circAbdominal    = circAll.filter { abdominalVesselNames.contains($0.name) }
        let pelvicNeutral    = circAll.filter { pelvicNeutralNames.contains($0.name) }
        let pelvicMaleOnly   = circAll.filter { pelvicMaleNames.contains($0.name) }
        let pelvicFemaleOnly = circAll.filter { pelvicFemaleNames.contains($0.name) }
        // At station build time, pick one sex for the gonadal vessels.
        let makePelvicStation: () -> ExamStation = {
            let gonadal = Bool.random() ? pelvicMaleOnly : pelvicFemaleOnly
            return station(from: pelvicNeutral + gonadal)
        }

        // MARK: Urinary sub-pools
        // Two completely different preparation contexts — never mix them.
        //
        // 1) Intact fetal pig dissection: kidney exterior + urinary tract (external view).
        //    "Kidney" lives in Peritoneal Cavity in our data, so pull it explicitly.
        // Sex-neutral structures visible on the intact dissection WITHOUT sectioning the
        // kidney: kidney exterior, ureter, bladder, adrenal gland, and the renal vessels
        // at the hilum. ("Kidney" lives in Peritoneal Cavity; the renal vessels in Circulatory.)
        let urinaryIntactNeutralNames: Set<String> = ["Adrenal Gland", "Ureter", "Urinary Bladder"]
        let urinaryIntactNeutral =
              structs(in: ["Urinary System"]).filter { urinaryIntactNeutralNames.contains($0.name) }
            + structs(in: ["Peritoneal Cavity"]).filter { $0.name == "Kidney" }
            + structs(in: ["Circulatory System"]).filter { ["Renal Arteries", "Renal Veins"].contains($0.name) }
        // Urethra is sex-specific — one specimen is one sex, so pick one at build time
        // (mirrors the pelvic gonadal-vessel handling).
        let urethraMale   = structs(in: ["Urinary System"]).filter { $0.name == "Urethra (Male)" }
        let urethraFemale = structs(in: ["Urinary System"]).filter { $0.name == "Urethra (Female)" }
        let makeUrinaryIntactStation: () -> ExamStation = {
            station(from: urinaryIntactNeutral + (Bool.random() ? urethraMale : urethraFemale))
        }

        // 2) Adult/cut kidney cross-section: internal collecting anatomy.
        //    Renal Medulla lives in Kidney Histology; Renal Arteries in Circulatory.
        //    Both are visible in a sectioned specimen, so pull them cross-category.
        let urinarySectionedNames: Set<String> = [
            "Renal Cortex", "Renal Pelvis", "Renal Calyx", "Renal Pyramid"
        ]
        let urinarySectioned = structs(in: ["Urinary System"]).filter { urinarySectionedNames.contains($0.name) }
                             + structs(in: ["Kidney Histology"]).filter { $0.name == "Renal Medulla" }
                             + structs(in: ["Circulatory System"]).filter { $0.name == "Renal Arteries" }

        // MARK: Histology scenario station builder
        // Each call picks one random scenario from the provided list, resolves each
        // entry to a structure-backed or free-text ExamItem, then appends a random
        // Microscope part as item E.

        func resolveItem(answer: String, prompt: String, imageOverride: AnatomyImage? = nil, alsoAccept: [String] = []) -> ExamItem {
            // First try an exact name match across all structures.
            if let s = dataManager.structures.first(where: {
                $0.name.caseInsensitiveCompare(answer) == .orderedSame
            }) {
                return ExamItem(structure: s, questionPrompt: prompt, imageOverride: imageOverride, alsoAccept: alsoAccept)
            }
            // Fall back to free-text answer (slash-delimited alternatives accepted).
            return ExamItem(freeText: answer, questionPrompt: prompt, imageOverride: imageOverride, alsoAccept: alsoAccept)
        }

        func makeHistoStation(from pool: [HistoScenario]) -> ExamStation {
            guard let scenario = pool.randomElement() else {
                return ExamStation(items: [], timeLimit: tl)
            }
            let microscope = structs(in: ["Microscope"]).shuffled().first
            // A histology station = ONE slide viewed through the scope; A–D are all questions
            // about THAT single image (only E is the microscope part). So show the SAME image on
            // every A–D card: prefer an explicit slideImage, else A's per-entry image, else A's
            // structure's own image. This also removes the "message symbol" placeholder that used
            // to appear on free-text (write-in) cards.
            // Resolve an answer (by NAME or ALIAS, tolerating slash-delimited alternatives) to a
            // structure — so e.g. "Gall Bladder" finds the "Gallbladder" structure.
            func structFor(_ answer: String) -> AnatomyStructure? {
                for part in answer.split(separator: "/").map({ $0.trimmingCharacters(in: .whitespaces) }) where !part.isEmpty {
                    if let s = dataManager.structures.first(where: {
                        $0.name.caseInsensitiveCompare(part) == .orderedSame
                        || $0.aliases.contains { $0.caseInsensitiveCompare(part) == .orderedSame }
                    }) { return s }
                }
                return nil
            }
            func histoOnly(_ answer: String) -> AnatomyImage? {
                structFor(answer)?.images.first { $0.magnification != nil }
            }
            // A must ALWAYS show a HISTOLOGY image ("what tissue is this?" on a gross photo or a
            // blank card makes no sense). Since A–D are all the SAME slide, prefer in order: an
            // explicit slide image, A's per-entry override, A's own histo image, a histo image
            // from ANY A–D structure, and only then a gross image as a last resort. This auto-fixes
            // organs whose A structure has only a gross photo but whose B–D layers are histology
            // (liver, pancreas, kidney, testis, gall bladder…).
            let slideImg: AnatomyImage? = scenario.slideImage
                ?? scenario.entries.first?.image
                ?? histoOnly(scenario.entries.first?.answer ?? "")
                ?? scenario.entries.lazy.compactMap { $0.image ?? histoOnly($0.answer) }.first
                ?? structFor(scenario.entries.first?.answer ?? "")?.images.first
                ?? scenario.entries.lazy.compactMap { $0.image ?? structFor($0.answer)?.images.first }.first
            let abcd = scenario.entries.map { resolveItem(answer: $0.answer, prompt: $0.prompt, imageOverride: slideImg, alsoAccept: $0.alsoAccept) }
            let eItem: ExamItem = {
                if let m = microscope { return ExamItem(structure: m, questionPrompt: "E. Name this microscope part.") }
                return ExamItem(freeText: "Microscope part", questionPrompt: "E. Name this microscope part.")
            }()
            return ExamStation(items: abcd + [eItem], timeLimit: tl)
        }

        func slides(_ id: String) -> [HistoScenario] {
            allHistoScenarios.filter { $0.slideId == id }
        }

        // MARK: Pool tables (closures, each call = fresh shuffle of its fixed pool)

        // Gross pool — each closure = one coherent specimen/viewing-angle context.
        // Circulatory is split by region so heart stations don't mix pelvic vessels.
        // External is split head vs. body so eye structures don't share a station
        //   with umbilical/ventral structures.
        // Bronchioles excluded from Respiratory gross pool: they're microscopic.
        let grossPool: [() -> ExamStation] = [
            // Isolated adult cow heart (×1): cut open, internal anatomy visible —
            // valves, chordae, chambers, truncated vessel stumps.
            { station(from: circCowHeart) },
            // Fetal pig heart in situ (×2): heart still in thorax, NOT cut open —
            // only external chamber surfaces and coronary vessels visible; no valves.
            { station(from: circFetalCardiac) },
            { station(from: circFetalCardiac) },
            // Thoracic great vessels (×2)
            { station(from: circThoracic) },
            { station(from: circThoracic) },
            // Abdominal vessels (×2)
            { station(from: circAbdominal) },
            { station(from: circAbdominal) },
            // Pelvic vessels (×1) — randomly male or female gonadal vessels, never mixed
            { makePelvicStation() },
            // Peritoneal cavity + Digestive (×3)
            { grossStation(from: ["Peritoneal Cavity", "Digestive System"]) },
            { grossStation(from: ["Peritoneal Cavity", "Digestive System"]) },
            { grossStation(from: ["Peritoneal Cavity", "Digestive System"]) },
            // Upper Thoracic (×2)
            { grossStation(from: ["Upper Thoracic"]) },
            { grossStation(from: ["Upper Thoracic"]) },
            // External — head / face region (×1)
            { station(from: extHead) },
            // External — body, limbs, ventral surface (×1)
            { station(from: extBody) },
            // Urinary — intact fetal pig prep (×1): externally visible urinary tract
            // + renal vessels at the hilum; urethra sex picked per build.
            { makeUrinaryIntactStation() },
            // Urinary — adult kidney cross-section (×1): internal collecting anatomy
            { station(from: urinarySectioned) },
            // Reproductive (×2)
            { grossStation(from: ["Male Reproductive"]) },
            { grossStation(from: ["Female Reproductive"]) },
            // Buccal Cavity (×1)
            { grossStation(from: ["Buccal Cavity"]) },
            // Respiratory — bronchioles excluded (too small to pin grossly) (×1)
            { grossStation(from: ["Respiratory System"], exclude: ["Bronchioles"]) },
            // Fetal Structures + Adult Maternal Pig (×1)
            { grossStation(from: ["Fetal Structures", "Adult Maternal Pig"]) },
            // Cow Eye (×1)
            { grossStation(from: ["Cow Eye"]) },
        ]

        // Histo pool — one entry per slide.  Each call picks ONE random scenario
        // from that slide's scenario list, so every station is contextually coherent.
        // GI gets extra entries to match its higher frequency on the real exam.
        let histoPool: [() -> ExamStation] = [
            // Vessel slides (3 slides)
            { makeHistoStation(from: slides("01")) },   // Artery/Vein/Nerve
            { makeHistoStation(from: slides("07")) },   // Human Aorta
            { makeHistoStation(from: slides("15")) },   // Human Vena Cava
            // Respiratory slides (2 slides)
            { makeHistoStation(from: slides("02")) },   // Trachea/Esophagus
            { makeHistoStation(from: slides("14")) },   // Lung section
            // GI slides (8 slides — more entries to match real-exam frequency)
            { makeHistoStation(from: slides("03")) },   // Mammal Ileum
            { makeHistoStation(from: slides("04")) },   // Cardiac Stomach
            { makeHistoStation(from: slides("05")) },   // Large Intestine
            { makeHistoStation(from: slides("06")) },   // Mammal Jejunum
            { makeHistoStation(from: slides("11")) },   // Mammal Duodenum
            { makeHistoStation(from: slides("12")) },   // Mammal Fundic Stomach
            { makeHistoStation(from: slides("18")) },   // Gall Bladder
            { makeHistoStation(from: slides("20")) },   // Mammal Pyloric Stomach
            // Accessory organ slides
            { makeHistoStation(from: slides("08")) },   // Liver
            { makeHistoStation(from: slides("09")) },   // Mammal Pancreas
            // Kidney
            { makeHistoStation(from: slides("10")) },   // Kidney
            // Blood
            { makeHistoStation(from: slides("19")) },   // Blood Smear
            // Reproductive slides (separate male/female slides)
            { makeHistoStation(from: slides("13")) },   // Mammal Ovary
            { makeHistoStation(from: slides("16")) },   // Testis
        ]

        // MARK: Build
        let histoCount = max(1, Int((Double(numStations) * 8.0 / 30.0).rounded()))
        let grossCount = numStations - histoCount

        let shuffledGross = grossPool.shuffled()
        let shuffledHisto = histoPool.shuffled()
        var stations: [ExamStation] = []

        for i in 0..<grossCount { stations.append(shuffledGross[i % shuffledGross.count]()) }
        for i in 0..<histoCount { stations.append(shuffledHisto[i % shuffledHisto.count]()) }

        examSession = ExamSession(stations: stations.shuffled(), timePerStation: tl, gradeAtEnd: gradeAtEnd)
    }
}

struct ExamStationView: View {
    @Binding var examSession: ExamSession?
    @StateObject private var dataManager = AnatomyDataManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var answers: [String] = Array(repeating: "", count: 5)
    @State private var isSubmitted = false
    @State private var timer: Timer?
    @State private var timeRemaining: TimeInterval = 90
    @State private var stationStartDate = Date()
    // Fairness: the station clock doesn't start until the first ID photo is on screen,
    // so slow Wi-Fi can't burn time before you can see anything.
    @State private var timerStarted = false
    // Which of the 5 ID cards is showing (drives the swipe pager).
    @State private var currentCard = 0
    // Which answer field has the keyboard, so Return can hop to the next card (and submit
    // from the last one) — matching the write-answer quiz.
    @FocusState private var focusedField: Int?
    // The station index we've already set up. Re-appearing (e.g. returning from an ID card
    // the user opened in the submitted review) must NOT re-init the station.
    @State private var preparedStationIndex: Int?
    @State private var showEndConfirm = false
    // True only when the ON-SCREEN keyboard is up (tall). With a hardware keyboard (iPad Magic
    // Keyboard / Mac) there's no software keyboard, so we don't show a "hide keyboard" button.
    // Direction of the last card change, so the iPhone card slides the right way.
    @State private var goingForward = true
    // iPhone uses ONE persistent field with a STABLE focus identity (not keyed to the card),
    // so advancing to the next ID only swaps the bound text — the keyboard never dips down/up.
    @FocusState private var phoneFieldFocused: Bool

    var body: some View {
        if let session = examSession, let station = session.currentStation {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Station \(session.currentStationIndex + 1) / \(session.stations.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    // Which card of 5 you're on.
                    Text("ID \(currentCard + 1) / \(station.items.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    // Hide the running score in realistic mode so per-station correctness
                    // isn't leaked before the final results.
                    if !session.gradeAtEnd {
                        Spacer()
                        Text("Score: \(session.score) / \(session.currentStationIndex * 5)")
                            .font(.subheadline.bold())
                    }
                }
                .padding(.horizontal)

                // Timer bar
                if station.timeLimit > 0 {
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.2)).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(examTimerColor)
                                    .frame(width: max(0, CGFloat(timeRemaining / station.timeLimit)) * geo.size.width, height: 8)
                            }
                        }
                        .frame(height: 8)
                        Text(isSubmitted ? "Submitted"
                             : timerStarted ? "\(Int(ceil(timeRemaining)))s remaining"
                             : "Loading image…")
                            .font(.caption.monospacedDigit()).foregroundStyle(examTimerColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }

                // iPhone (answering): a SINGLE full-size image that reliably fills the space,
                // with the answer field docked directly below it. A paged TabView won't expand
                // under the keyboard (leaving dead space), so iPhone answering skips it. iPad —
                // and the submitted review on every device — keep the swipeable TabView cards.
                if !UIDevice.isPad, !isSubmitted {
                    phoneAnsweringArea(station: station)
                } else {
                    TabView(selection: $currentCard) {
                        ForEach(Array(station.items.enumerated()), id: \.element.id) { idx, item in
                            ExamCardView(
                                index: idx,
                                total: station.items.count,
                                item: item,
                                answer: idx < answers.count ? $answers[idx] : .constant(""),
                                isSubmitted: isSubmitted,
                                focus: $focusedField,
                                isLastCard: idx == station.items.count - 1,
                                onSubmitField: { handleFieldSubmit(idx, count: station.items.count) },
                                onImageLoaded: { if idx == 0 { beginTimerIfNeeded() } },
                                onOverride: { overrideItemCorrect(idx) },
                                showInlineField: UIDevice.isPad
                            )
                            .padding(.horizontal)
                            .padding(.bottom, UIDevice.isPad ? 46 : 6)
                            .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: UIDevice.isPad ? .always : .never))
                    .frame(maxHeight: .infinity)

                    // Action button
                    if isSubmitted {
                        Button(session.currentStationIndex + 1 < session.stations.count
                               ? "Next Station →"
                               : "See Results") { advance() }
                            .buttonStyle(.borderedProminent).tint(.indigo)
                            .frame(maxWidth: .infinity)
                            .keyboardShortcut(.defaultAction)   // Return advances to the next station
                    } else if UIDevice.isPad {
                        // iPad/Mac: one button that walks ID → ID, and only submits the whole
                        // station from the last card (prevents an accidental early submit).
                        Button(primaryButtonLabel(session: session, count: station.items.count)) {
                            primaryAdvance(count: station.items.count)
                        }
                            .buttonStyle(.borderedProminent).tint(.indigo)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.vertical, 8)
            .onAppear { prepareStationIfNeeded(); resumeTimer() }
            .onChange(of: session.currentStationIndex) { prepareStationIfNeeded() }
            // Keep the keyboard on the visible card: if it was already up, move focus to the
            // newly-swiped card's field; if it was down, don't pop it up on a browse swipe.
            .onChange(of: currentCard) { if !isSubmitted, focusedField != nil { focusedField = currentCard } }
            // Safety net: if a photo never resolves, don't hold the clock forever — start it
            // after 15s regardless. Re-arms per station (keyed on the index).
            .task(id: session.currentStationIndex) {
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                if !Task.isCancelled { beginTimerIfNeeded() }
            }
            // Freeze the clock while off-screen (tab switch / pushed ID card); resumeTimer()
            // on re-appear rebases it so no time is lost while away.
            .onDisappear { stopTimer() }
            .toolbar {
                // Close (X) replaces the old system back button, since a full-screen cover has
                // no back chevron. Dismisses the whole exam.
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { pauseTimer(); showEndConfirm = true }
                }
            }
            .confirmationDialog("Finish the exam now?", isPresented: $showEndConfirm, titleVisibility: .visible) {
                Button("See Results", role: .destructive) { finishEarly() }
                Button("Keep Going", role: .cancel) { resumeTimer() }
            } message: {
                Text("Only stations you've already submitted are scored. Unsubmitted and unreached stations are dropped, not marked wrong.")
            }
        } else {
            ProgressView()
        }
    }

    private var examTimerColor: Color {
        guard let session = examSession, let station = session.currentStation, station.timeLimit > 0 else { return .blue }
        let ratio = timeRemaining / station.timeLimit
        if ratio > 0.5 { return .green }
        if ratio > 0.25 { return .orange }
        return .red
    }

    /// Set up a station only the first time we land on it. Guards against `.onAppear` firing
    /// again when the view re-appears after a pushed detail (the ID card) is popped — which
    /// would otherwise clear the submitted answers and restart the timer.
    private func prepareStationIfNeeded() {
        guard let session = examSession, let station = session.currentStation else { return }
        guard preparedStationIndex != session.currentStationIndex else { return }
        preparedStationIndex = session.currentStationIndex
        resetForStation(station)
    }

    private func resetForStation(_ station: ExamStation) {
        stopTimer()
        answers = Array(repeating: "", count: station.items.count)
        isSubmitted = false
        timeRemaining = station.timeLimit
        timerStarted = false
        currentCard = 0
        focusedField = nil
        phoneFieldFocused = false
        stationStartDate = Date()
        // Start the clock once the FIRST card's photo is on screen (its onImageLoaded fires
        // beginTimerIfNeeded); if that card has no photo, start immediately.
        if station.timeLimit > 0, station.items.first?.displayImages.isEmpty ?? true {
            beginTimerIfNeeded()
        }
        focusFirstFieldSoon()
    }

    /// Put the cursor in the first answer field (and raise the keyboard) on each new station,
    /// so keyboard-only users can start typing immediately. Deferred because a synchronous
    /// @FocusState set on appear/change is usually dropped before the view is ready. Only on
    /// a fresh station (not on re-appear), so returning from an ID card won't yank focus.
    /// SKIPPED on iPhone: there the software keyboard would cover the image on load — the user
    /// wants to see the ID first and tap the floating field to start typing.
    private func focusFirstFieldSoon() {
        guard UIDevice.isPad else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isSubmitted, currentCard == 0 { focusedField = 0 }
        }
    }

    /// Start the station countdown from NOW, exactly once (guarded so the first-card-loaded
    /// path and the 15s safety net can't both start it).
    private func beginTimerIfNeeded() {
        guard !timerStarted, !isSubmitted,
              let station = examSession?.currentStation, station.timeLimit > 0 else { return }
        timerStarted = true
        timeRemaining = station.timeLimit
        stationStartDate = Date()
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            guard let session = examSession, let station = session.currentStation else { return }
            let elapsed = Date().timeIntervalSince(stationStartDate)
            let remaining = station.timeLimit - elapsed
            if remaining <= 0 {
                timeRemaining = 0
                timer?.invalidate()
                if !isSubmitted { submitStation() }
            } else {
                timeRemaining = remaining
            }
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func submitStation() {
        guard var session = examSession, let station = session.currentStation, !isSubmitted else { return }
        stopTimer()
        isSubmitted = true
        var updatedStation = station
        for idx in 0..<updatedStation.items.count {
            let typed = idx < answers.count ? answers[idx] : ""
            let correct = updatedStation.items[idx].accepts(typed: typed)
            updatedStation.items[idx].givenAnswer = typed.isEmpty ? "(blank)" : typed
            updatedStation.items[idx].wasCorrect = correct
            if correct { session.score += 1 }
            // Feed exam performance into Stats (structure-backed items) so it counts toward the
            // leaderboard practice score and per-structure accuracy, like the quiz does.
            if let name = updatedStation.items[idx].structure?.name {
                StatsManager.shared.record(structureName: name, correct: correct)
            }
        }
        updatedStation.isSubmitted = true
        session.stations[session.currentStationIndex] = updatedStation
        examSession = session
        // Realistic mode: no per-station review — go straight to the next station (or, on the
        // last one, to the final results, since currentStationIndex then passes the end).
        if session.gradeAtEnd { advance() }
    }

    // "I got it right" override for a station item the matcher marked wrong.
    private func overrideItemCorrect(_ idx: Int) {
        guard var session = examSession, isSubmitted,
              session.currentStationIndex < session.stations.count else { return }
        var station = session.stations[session.currentStationIndex]
        guard idx < station.items.count, !station.items[idx].wasCorrect else { return }
        station.items[idx].wasCorrect = true
        session.score += 1
        if let name = station.items[idx].structure?.name {
            StatsManager.shared.overrideLastToCorrect(structureName: name)
        }
        session.stations[session.currentStationIndex] = station
        examSession = session
    }

    private func advance() {
        stopTimer()
        if var session = examSession {
            session.currentStationIndex += 1
            examSession = session
        }
    }

    /// Return key in an answer field: swipe to the next ID card (and focus it), or submit the
    /// station from the last card.
    private func handleFieldSubmit(_ idx: Int, count: Int) {
        if idx < count - 1 {
            goingForward = true
            withAnimation { currentCard = idx + 1 }
            focusedField = idx + 1
        } else {
            focusedField = nil
            submitStation()
        }
    }

    /// iPhone answering view: one full-size ID image that FILLS all space between the timer and
    /// the answer field, plus the single docked field + Next/Submit. No paged TabView (it won't
    /// expand under the keyboard) and no keyboard-down button. Tap the image once to drop the
    /// keyboard, again to open it fullscreen; swipe left/right to move between IDs 1–5. The exam
    /// is a full-screen cover (no back-swipe pop), so a back-swipe just moves to an earlier ID and
    /// can never exit. Cards slide in/out directionally so the set-of-5 paging reads clearly.
    @ViewBuilder
    private func phoneAnsweringArea(station: ExamStation) -> some View {
        let item = station.items[min(currentCard, station.items.count - 1)]
        let onLast = currentCard >= station.items.count - 1
        VStack(spacing: 10) {
            // Card area: only the current ID's card slides; the gestures live on this stable
            // wrapper so they survive the transition.
            ZStack {
                examCard(item: item)
                    .id(currentCard)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingForward ? .trailing : .leading),
                        removal: .move(edge: goingForward ? .leading : .trailing)
                    ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .contentShape(Rectangle())
            // Tap anywhere on the card (image or padding) drops the keyboard first.
            .onTapGesture { if phoneFieldFocused { phoneFieldFocused = false } }
            // Swipe between IDs, clamped to 1–5 (never exits). Simultaneous so it won't block taps.
            .simultaneousGesture(
                DragGesture(minimumDistance: 40)
                    .onEnded { v in
                        guard abs(v.translation.width) > abs(v.translation.height) else { return }
                        goToCard(v.translation.width < 0 ? currentCard + 1 : currentCard - 1,
                                 count: station.items.count)
                    }
            )
            .padding(.horizontal)

            // Single docked answer field + Next/Submit (rides above the keyboard when it opens).
            // Its focus is a STABLE Bool (not keyed to the card), so advancing keeps the keyboard up.
            HStack(spacing: 8) {
                TextField("Answer…", text: currentCard < answers.count ? $answers[currentCard] : .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($phoneFieldFocused)
                    .submitLabel(onLast ? .done : .next)
                    .onSubmit { phoneSubmit(count: station.items.count) }
                Button(onLast ? "Submit" : "Next") { phoneSubmit(count: station.items.count) }
                    .buttonStyle(.borderedProminent).tint(.indigo)
            }
            .padding(.horizontal)
        }
    }

    /// iPhone Next/Submit (button or keyboard Return): advance to the next ID KEEPING the keyboard
    /// up (focus state is unchanged, so no pull-down/pull-up), or on the last card drop the keyboard
    /// and submit the station.
    private func phoneSubmit(count: Int) {
        if currentCard >= count - 1 {
            phoneFieldFocused = false
            submitStation()
        } else {
            goingForward = true
            withAnimation { currentCard += 1 }
        }
    }

    /// The prompt + big filling image for the current ID (no gestures — those live on the stable
    /// wrapper so they persist across the slide transition).
    @ViewBuilder
    private func examCard(item: ExamItem) -> some View {
        VStack(spacing: 8) {
            Text(item.questionPrompt ?? "ID \(currentCard + 1)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Group {
                if !item.displayImages.isEmpty {
                    ExamCardImage(
                        images: item.displayImages,
                        onLoaded: { if currentCard == 0 { beginTimerIfNeeded() } },
                        onImageTap: {
                            if phoneFieldFocused { phoneFieldFocused = false; return true }
                            return false
                        }
                    )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.08))
                        Image(systemName: item.structure != nil ? "camera" : "text.bubble")
                            .font(.system(size: 44)).foregroundStyle(.secondary.opacity(0.4))
                    }
                    .onAppear { if currentCard == 0 { beginTimerIfNeeded() } }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.gray.opacity(0.15)))
    }

    /// Move to another ID card (clamped to the station's range — never past the ends, so a
    /// back-swipe on ID 1 or forward-swipe on ID 5 just stays put), sliding in the right
    /// direction. Focus follows via `.onChange(of: currentCard)` when the keyboard is up.
    private func goToCard(_ target: Int, count: Int) {
        guard target >= 0, target < count, target != currentCard else { return }
        goingForward = target > currentCard
        withAnimation(.easeInOut(duration: 0.28)) { currentCard = target }
    }

    /// The primary button (bottom bar / iPad button): walk to the next ID card, and only
    /// submit the whole station from the LAST card — so pressing it after ID 1 no longer
    /// submits everything. Focus follows via `.onChange(of: currentCard)` when typing.
    private func primaryAdvance(count: Int) {
        if currentCard >= count - 1 {
            focusedField = nil
            submitStation()
        } else {
            goingForward = true
            withAnimation { currentCard += 1 }
        }
    }

    private func primaryButtonLabel(session: ExamSession, count: Int) -> String {
        if currentCard < count - 1 { return "Next ID →" }
        if session.gradeAtEnd {
            return session.currentStationIndex + 1 < session.stations.count ? "Submit & Next →" : "Submit & See Results"
        }
        return "Submit Station"
    }

    private func pauseTimer() { stopTimer() }

    /// Resume the station clock from where it froze (rebases the start so no time is lost
    /// while off-screen or while the Done dialog is up). No-op if nothing is running.
    private func resumeTimer() {
        guard timerStarted, !isSubmitted, timer == nil,
              let station = examSession?.currentStation,
              station.timeLimit > 0, timeRemaining > 0 else { return }
        stationStartDate = Date().addingTimeInterval(-(station.timeLimit - timeRemaining))
        startTimer()
    }

    /// End the exam now, scoring ONLY stations already submitted. The current station (if not
    /// submitted) and every station not yet reached are dropped — never attempted, so never
    /// graded wrong. Submitted stations are contiguous from the start, so a prefix keeps them.
    private func finishEarly() {
        stopTimer()
        guard var session = examSession else { return }
        let gradedCount = session.stations.filter { $0.isSubmitted }.count
        session.stations = Array(session.stations.prefix(gradedCount))
        session.currentStationIndex = session.stations.count   // → isComplete
        examSession = session
    }
}

/// One big, swipeable ID card for the Real Exam: prompt + large image (tap to zoom) + the
/// answer field (before submit) or the graded feedback (after).
struct ExamCardView: View {
    let index: Int
    let total: Int
    let item: ExamItem
    @Binding var answer: String
    let isSubmitted: Bool
    var focus: FocusState<Int?>.Binding
    var isLastCard: Bool = false
    var onSubmitField: (() -> Void)? = nil
    var onImageLoaded: (() -> Void)? = nil
    var onOverride: (() -> Void)? = nil
    // iPhone routes the answer field into a bottom bar (so the keyboard doesn't shove the
    // image off-screen), so the in-card field is suppressed there.
    var showInlineField: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            Text(item.questionPrompt ?? "ID \(index + 1)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Big image (or a placeholder for concept-only items).
            Group {
                if !item.displayImages.isEmpty {
                    ExamCardImage(images: item.displayImages, onLoaded: onImageLoaded)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(.gray.opacity(0.08))
                        Image(systemName: item.structure != nil ? "camera" : "text.bubble")
                            .font(.system(size: 44)).foregroundStyle(.secondary.opacity(0.4))
                    }
                    .onAppear { onImageLoaded?() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isSubmitted {
                feedback
            } else if showInlineField {
                TextField("Answer…", text: $answer)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused(focus, equals: index)
                    .submitLabel(isLastCard ? .done : .next)
                    .onSubmit { onSubmitField?() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.gray.opacity(0.15)))
        // Tap an empty part of the card to drop the keyboard (it shrinks the image). The
        // image (tap = zoom) and the field (tap = focus) handle their own taps first.
        .onTapGesture { focus.wrappedValue = nil }
    }

    @ViewBuilder private var feedback: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: item.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(item.wasCorrect ? .green : .red)
                if let s = item.structure {
                    NavigationLink { StructureDetailView(structure: s) } label: {
                        HStack(spacing: 3) {
                            Text(item.correctAnswerDisplay).fontWeight(.semibold)
                                .foregroundStyle(item.wasCorrect ? Color.primary : Color.red)
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(item.correctAnswerDisplay).fontWeight(.semibold)
                        .foregroundStyle(item.wasCorrect ? Color.primary : Color.red)
                }
                Spacer(minLength: 0)
            }
            WrongAnswerFeedback(item: item)
            // Override for the conceptual B/C/D slots (arrow structure, cell type, function) where
            // valid phrasing varies — NOT for the "what organ is this?" (A) / microscope / gross
            // photo IDs, which are unambiguous.
            if !item.wasCorrect && item.allowsSelfOverride {
                Button { onOverride?() } label: {
                    Label("I got it right", systemImage: "checkmark.circle").font(.caption)
                }
                .buttonStyle(.bordered).tint(.green).controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The large, zoomable image inside an ExamCardView. Shows the WHOLE image (scaledToFit)
/// with retry-on-failure via RemoteImageView; tap to open the fullscreen viewer.
struct ExamCardImage: View {
    let images: [AnatomyImage]
    var onLoaded: (() -> Void)? = nil
    /// Optional first-tap handler. Return true if the tap was consumed (e.g. it dismissed the
    /// keyboard) so the image should NOT fullscreen; return false to fullscreen as usual.
    var onImageTap: (() -> Bool)? = nil
    @State private var fullscreenImage: AnatomyImage?

    var body: some View {
        Group {
            if let img = images.first {
                if img.isRemote {
                    RemoteImageView(urlString: img.source, fillsFrame: false, onLoaded: onLoaded)
                        .id(img.source)
                } else {
                    Image(img.source).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear { onLoaded?() }
                }
            } else {
                Color.clear.onAppear { onLoaded?() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottomTrailing) {
            if !images.isEmpty {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(5)
                    .background(.black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(6)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Let a caller consume the first tap (e.g. drop the keyboard); only fullscreen
            // when it doesn't handle it — so on iPhone one tap hides the keyboard, the next
            // opens fullscreen.
            if let onImageTap, onImageTap() { return }
            fullscreenImage = images.randomElement()
        }
        .fullScreenCover(item: $fullscreenImage) { img in
            ExamImageFullscreen(image: img)
        }
    }
}

/// "You wrote …" / "You likely meant …" feedback for a wrong exam item, shared by the
/// per-station review and the final results. If the typed answer EXACTLY matches a real
/// structure (case-insensitive), "You wrote" itself is the tappable link — no guessing,
/// since it's 100% clear what was meant. Otherwise a fuzzy "You likely meant" link is shown.
struct WrongAnswerFeedback: View {
    let item: ExamItem
    var structures: [AnatomyStructure] = AnatomyDataManager.shared.structures

    var body: some View {
        if !item.wasCorrect, item.givenAnswer != "(blank)" {
            if let exact = item.exactMatch(among: structures) {
                link("You wrote: \(item.givenAnswer)", to: exact)
            } else {
                Text("You wrote: \(item.givenAnswer)")
                    .font(.caption2).foregroundStyle(.secondary)
                if let guess = item.likelyMeant(among: structures) {
                    link("You likely meant: \(guess.name)", to: guess)
                }
            }
        }
    }

    @ViewBuilder private func link(_ text: String, to s: AnatomyStructure) -> some View {
        NavigationLink { StructureDetailView(structure: s) } label: {
            HStack(spacing: 3) {
                Text(text).font(.caption2).foregroundStyle(.blue)
                Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(.blue.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
}

/// Fullscreen zoomable viewer for one exam ID image (single, no multi-image paging).
struct ExamImageFullscreen: View {
    let image: AnatomyImage
    @Environment(\.dismiss) private var dismiss
    @State private var isZoomed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                // Use a single-page TabView — gives ZoomableUIImage a proper full-screen
                // frame the same way FullscreenImageSheet does. Direct ZStack placement
                // leaves UIViewRepresentable with zero proposed size → black screen.
                TabView {
                    FullscreenPageView(image: image, structureName: "", isZoomed: $isZoomed)
                        .ignoresSafeArea()
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let mag = image.magnification {
                        Text("\(mag)×")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.white.opacity(0.2))
                            .foregroundStyle(.white)
                            .cornerRadius(6)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

struct ExamResultsView: View {
    let session: ExamSession
    let dismiss: DismissAction
    /// (stationIndex, itemIndex) → bump the score and mark that item correct.
    var onOverride: ((Int, Int) -> Void)? = nil
    @StateObject private var dataManager = AnatomyDataManager.shared

    var total: Int { session.totalItems }
    var pct: Int { total > 0 ? Int(Double(session.score) / Double(total) * 100) : 0 }
    var grade: String {
        switch pct {
        case 90...100: return "Excellent! 🎉"
        case 75..<90:  return "Good work!"
        case 60..<75:  return "Getting there"
        default:       return "Keep studying"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Score card
                VStack(spacing: 6) {
                    Text(grade).font(.title2).fontWeight(.semibold)
                    Text("\(session.score) / \(total)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(pct >= 75 ? .green : pct >= 60 ? .orange : .red)
                    Text("\(pct)%").font(.title3).foregroundStyle(.secondary)
                    Text("\(session.stations.count) stations · \(total) items")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.gray.opacity(0.08))
                .cornerRadius(16)

                // Station breakdown
                VStack(alignment: .leading, spacing: 10) {
                    Label("By Station", systemImage: "list.number")
                        .font(.headline).foregroundStyle(.indigo)

                    ForEach(Array(session.stations.enumerated()), id: \.element.id) { idx, station in
                        let correct = station.items.filter { $0.wasCorrect }.count
                        let total = station.items.count
                        DisclosureGroup {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(station.items.enumerated()), id: \.element.id) { itemIdx, item in
                                    HStack(spacing: 8) {
                                        Image(systemName: item.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(item.wasCorrect ? .green : .red)
                                            .font(.caption)
                                        VStack(alignment: .leading, spacing: 1) {
                                            // Correct answer — tappable to its ID card (right or wrong) when it's a real structure.
                                            if let s = item.structure {
                                                NavigationLink { StructureDetailView(structure: s) } label: {
                                                    HStack(spacing: 3) {
                                                        Text(item.correctAnswerDisplay).font(.caption).fontWeight(.semibold)
                                                            .foregroundStyle(.primary)
                                                        Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(.secondary)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            } else {
                                                Text(item.correctAnswerDisplay).font(.caption).fontWeight(.semibold)
                                            }
                                            WrongAnswerFeedback(item: item, structures: dataManager.structures)
                                            // Self-override for the conceptual B/C/D slots marked wrong.
                                            if !item.wasCorrect && item.allowsSelfOverride {
                                                Button { onOverride?(idx, itemIdx) } label: {
                                                    Label("I got it right", systemImage: "checkmark.circle").font(.caption2)
                                                }
                                                .buttonStyle(.bordered).tint(.green).controlSize(.mini)
                                                .padding(.top, 2)
                                            }
                                        }
                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                            .padding(.top, 4)
                        } label: {
                            HStack {
                                Text("Station \(idx + 1)").font(.subheadline)
                                Spacer()
                                Text("\(correct)/\(total)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(correct == total ? .green : correct == 0 ? .red : .orange)
                            }
                        }
                    }
                }
                .padding()
                .background(.indigo.opacity(0.06))
                .cornerRadius(12)

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Exam Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Search

struct SearchView: View {
    /// Reports nav-stack depth to ContentView so the Search tab-swipe disables while
    /// paging through results (otherwise the result pager's swipe changes tabs).
    @Binding var isAtRoot: Bool
    @State private var searchText = ""
    @State private var navPath = NavigationPath()
    @StateObject private var dataManager = AnatomyDataManager.shared

    var results: [AnatomyStructure] {
        searchText.isEmpty ? [] : dataManager.searchStructures(query: searchText)
    }

    /// Fill-in questions whose sentence, answers, explanation, or category contain the query.
    var fillBlankResults: [FillBlankQuestion] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return dataManager.fillBlanks.filter { fb in
            fb.prompt.lowercased().contains(q)
            || fb.answers.contains { $0.lowercased().contains(q) }
            || fb.explanation.lowercased().contains(q)
            || fb.category.lowercased().contains(q)
        }
    }

    private func categoryName(for structure: AnatomyStructure) -> String {
        dataManager.categories.first { $0.id == structure.categoryId }?.name ?? ""
    }

    /// The fill-in sentence with its blanks filled in, so the matched keyword is visible in the hit.
    private func filledPrompt(_ q: FillBlankQuestion) -> String {
        var s = q.prompt
        for a in q.answers {
            if let r = s.range(of: "___") { s.replaceSubrange(r, with: a) }
        }
        return s
    }

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if results.isEmpty && fillBlankResults.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "magnifyingglass").font(.largeTitle)
                        Text(searchText.isEmpty ? "Search structures & fill-ins" : "No matches")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        if !results.isEmpty {
                            Section("Structures") {
                                ForEach(results) { s in
                                    NavigationLink(value: s) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(s.name).font(.body)
                                            let cat = categoryName(for: s)
                                            if !cat.isEmpty {
                                                Label(cat, systemImage: "folder")
                                                    .font(.caption).foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if !fillBlankResults.isEmpty {
                            Section("Fill-in Questions") {
                                ForEach(fillBlankResults) { q in
                                    NavigationLink(value: q) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(filledPrompt(q))
                                                .font(.subheadline).lineLimit(3)
                                            Label(q.category, systemImage: "text.badge.plus")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .navigationDestination(for: AnatomyStructure.self) { s in
                        // Page through the CURRENT results, starting at the tapped one.
                        StructurePagerView(
                            allStructures: results,
                            initialIndex: results.firstIndex(where: { $0.id == s.id }) ?? 0
                        )
                    }
                    .navigationDestination(for: FillBlankQuestion.self) { q in
                        FillBlankDetailView(question: q)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search structures & fill-ins")
            .navigationTitle("Search")
        }
        .onChange(of: navPath.count) { _, count in
            isAtRoot = (count == 0)
        }
    }
}

// MARK: - Upload / Contribute

struct UploadView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: UploadPhotoView()) {
                        Label("Contribute a Photo", systemImage: "camera.fill")
                    }
                } footer: {
                    Text("Help improve the app by submitting clear dissection photos. Multiple angles, different specimens, and various zoom levels are all useful.")
                }

                Section("Tips for Good Photos") {
                    Label("Good lighting — use a bright lamp or window", systemImage: "lightbulb")
                    Label("One structure clearly in frame", systemImage: "viewfinder")
                    Label("Include a scale reference if possible", systemImage: "ruler")
                    Label("For histology: note the magnification (4x / 10x / 40x)", systemImage: "magnifyingglass")
                    Label("Multiple photos per structure are encouraged", systemImage: "photo.stack")
                }
            }
            .navigationTitle("Contribute")
        }
    }
}

struct UploadPhotoView: View {
    @State private var selectedStructure: AnatomyStructure?
    @State private var notes: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @StateObject private var contributor = ContributionManager()
    @StateObject private var dataManager = AnatomyDataManager.shared
    @Environment(\.dismiss) var dismiss
    @FocusState private var notesFocused: Bool

    var activeImage: UIImage? { selectedImage ?? cameraImage }
    var canSubmit: Bool { selectedStructure != nil && activeImage != nil }

    var body: some View {
        Form {
            Section("Structure") {
                if let s = selectedStructure {
                    HStack {
                        Text(s.name).fontWeight(.medium)
                        Spacer()
                        Button("Change") { selectedStructure = nil }.foregroundStyle(.blue)
                    }
                } else {
                    NavigationLink("Choose structure") {
                        SelectStructureView(selectedStructure: $selectedStructure)
                    }
                }
            }

            Section("Photo") {
                if let img = activeImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .cornerRadius(10)
                }

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(selectedImage != nil ? "Change Photo from Library" : "Choose from Library", systemImage: "photo.on.rectangle")
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImg = UIImage(data: data) {
                            selectedImage = uiImg
                            cameraImage = nil
                        }
                    }
                }

                Button(action: { showCamera = true }) {
                    Label("Take a Photo", systemImage: "camera")
                }
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            }

            Section("Notes (optional)") {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .focused($notesFocused)
                    .overlay(
                        Group {
                            if notes.isEmpty {
                                Text("Angle, magnification, specimen details...")
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { notesFocused = false }
                        }
                    }
            }

            Section {
                SubmitButton(state: contributor.state, enabled: canSubmit) {
                    notesFocused = false
                    contributor.submit(
                        structureName: selectedStructure?.name ?? "",
                        image: activeImage!,
                        notes: notes
                    )
                }
            }
        }
        .navigationTitle("Contribute Photo")
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showCamera) {
            CameraView(image: $cameraImage).ignoresSafeArea()
        }
        .alert("Thank you!", isPresented: .constant(contributor.state == .success)) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your photo was submitted successfully and will be reviewed before being added to the app.")
        }
        .alert("Submission Failed", isPresented: .constant({
            if case .failure = contributor.state { return true }
            return false
        }())) {
            Button("OK") { contributor.reset() }
        } message: {
            if case .failure(let msg) = contributor.state { Text(msg) }
        }
    }
}

struct UploadPhotoForStructureView: View {
    let structure: AnatomyStructure
    @State private var notes = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @StateObject private var contributor = ContributionManager()
    @Environment(\.dismiss) var dismiss
    @FocusState private var notesFocused: Bool

    var activeImage: UIImage? { selectedImage ?? cameraImage }

    var body: some View {
        Form {
            Section("Structure") {
                Text(structure.name).fontWeight(.medium)
            }

            Section("Photo") {
                if let img = activeImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .cornerRadius(10)
                }

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(selectedImage != nil ? "Change Photo" : "Choose from Library", systemImage: "photo.on.rectangle")
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImg = UIImage(data: data) {
                            selectedImage = uiImg
                            cameraImage = nil
                        }
                    }
                }

                Button(action: { showCamera = true }) {
                    Label("Take a Photo", systemImage: "camera")
                }
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
            }

            Section("Notes (optional)") {
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .focused($notesFocused)
                    .overlay(
                        Group {
                            if notes.isEmpty {
                                Text("Angle, magnification, specimen details...")
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { notesFocused = false }
                        }
                    }
            }

            Section {
                SubmitButton(state: contributor.state, enabled: activeImage != nil) {
                    notesFocused = false
                    contributor.submit(
                        structureName: structure.name,
                        image: activeImage!,
                        notes: notes
                    )
                }
            }
        }
        .navigationTitle("Photo for \(structure.name)")
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showCamera) {
            CameraView(image: $cameraImage).ignoresSafeArea()
        }
        .alert("Thank you!", isPresented: .constant(contributor.state == .success)) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your photo was submitted and will be reviewed before being added to the app.")
        }
        .alert("Submission Failed", isPresented: .constant({
            if case .failure = contributor.state { return true }
            return false
        }())) {
            Button("OK") { contributor.reset() }
        } message: {
            if case .failure(let msg) = contributor.state { Text(msg) }
        }
    }
}

// UIImagePickerController wrapper for camera access
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Shared submit button that reflects ContributionManager upload state
struct SubmitButton: View {
    let state: ContributionManager.State
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if state == .uploading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(state == .uploading ? "Uploading…" : "Submit")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
        }
        .disabled(!enabled || state == .uploading)
    }
}

struct SelectStructureView: View {
    @Binding var selectedStructure: AnatomyStructure?
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var searchText = ""

    var list: [AnatomyStructure] {
        searchText.isEmpty ? dataManager.structures : dataManager.searchStructures(query: searchText)
    }

    var body: some View {
        List(list) { s in
            Button(action: { selectedStructure = s }) {
                HStack {
                    Text(s.name)
                    Spacer()
                    if selectedStructure?.id == s.id { Image(systemName: "checkmark") }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Choose Structure")
    }
}

// MARK: - Diagrams

struct DiagramsView: View {
    /// Reports nav-stack depth to ContentView so the Diagrams tab-swipe disables while
    /// the diagram image pager is open (otherwise the internal swipe changes tabs).
    @Binding var isAtRoot: Bool
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if dataManager.diagramGroups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.stack").font(.system(size: 52)).foregroundStyle(.secondary)
                        Text("No diagrams yet").font(.headline)
                        Text("Reference diagrams and labeled overviews will appear here.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(dataManager.diagramGroups) { group in
                        NavigationLink(value: group.id) {
                            Label {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group.title).font(.body)
                                    Text(group.description).font(.caption).foregroundStyle(.secondary)
                                    Text("\(group.images.count) image\(group.images.count == 1 ? "" : "s")")
                                        .font(.caption2).foregroundStyle(.tertiary)
                                }
                            } icon: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.blue)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: group.systemImage)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .navigationDestination(for: UUID.self) { groupID in
                        DiagramPagerView(
                            allGroups: dataManager.diagramGroups,
                            initialIndex: dataManager.diagramGroups.firstIndex(where: { $0.id == groupID }) ?? 0
                        )
                    }
                }
            }
            .navigationTitle("Diagrams")
        }
        .onChange(of: navPath.count) { _, count in
            isAtRoot = (count == 0)
        }
    }
}

// Swipe between all diagram groups — mirrors StructurePagerView for diagrams
struct DiagramPagerView: View {
    let allGroups: [DiagramGroup]
    @State private var currentIndex: Int

    init(allGroups: [DiagramGroup], initialIndex: Int) {
        self.allGroups = allGroups
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(allGroups.enumerated()), id: \.element.id) { idx, group in
                DiagramDetailView(group: group, allGroups: allGroups)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationTitle(allGroups[currentIndex].title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DiagramDetailView: View {
    let group: DiagramGroup
    var allGroups: [DiagramGroup] = []
    @State private var currentIndex = 0

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(group.images.enumerated()), id: \.element.id) { idx, img in
                AnatomyImageView(image: img, fillsFrame: false, title: group.title,
                                 fullscreenMode: .diagram(allGroups.isEmpty ? [group] : allGroups))
                    .tag(idx)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .navigationTitle(group.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !group.images.isEmpty {
                let img = group.images[min(currentIndex, group.images.count - 1)]
                VStack(spacing: 4) {
                    if !img.caption.isEmpty {
                        Text(img.caption)
                            .font(.headline)
                    }
                    Text("\(currentIndex + 1) of \(group.images.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
            }
        }
    }
}

// MARK: - Stats

enum StatsMode: String, CaseIterable {
    case quiz = "Quiz"
    case flashcards = "Cards"
    case fillins = "Fill-Ins"
    case ranking = "Ranking"
}

struct StatsView: View {
    @StateObject private var stats = StatsManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared
    @StateObject private var fillProgress = FillBlankProgressManager.shared
    @State private var showResetConfirm = false
    @State private var showFillResetConfirm = false
    @State private var mode: StatsMode = .quiz

    var body: some View {
        NavigationStack {
            // Page-style TabView so you can swipe left/right between the segments; the picker
            // below drives the same selection (and is a stable toolbar host, so it won't glitch).
            TabView(selection: $mode) {
                quizStats.tag(StatsMode.quiz)
                FlashcardStatsContent().tag(StatsMode.flashcards)
                fillinStats.tag(StatsMode.fillins)
                LeaderboardContent().tag(StatsMode.ranking)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle("Stats & Ranking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Stats", selection: $mode) {
                        ForEach(StatsMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                }
            }
        }
    }

    @ViewBuilder
    private var quizStats: some View {
        Group {
                if stats.totalAnswered == 0 {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.xaxis").font(.system(size: 52)).foregroundStyle(.secondary)
                        Text("No quiz data yet").font(.headline)
                        Text("Take a quiz to start tracking your performance").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        // Overall
                        Section("Overall") {
                            HStack {
                                Label("Questions Answered", systemImage: "number.circle.fill")
                                Spacer()
                                Text("\(stats.totalAnswered)").fontWeight(.semibold)
                            }
                            HStack {
                                Label("Overall Accuracy", systemImage: "percent")
                                Spacer()
                                Text("\(Int(stats.overallAccuracy * 100))%")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(stats.overallAccuracy >= 0.75 ? .green : stats.overallAccuracy >= 0.6 ? .orange : .red)
                            }
                        }

                        // Category breakdown
                        let catBreakdown = stats.categoryAccuracy(structures: dataManager.structures, categories: dataManager.categories)
                        if !catBreakdown.isEmpty {
                            Section("By Category (weakest first)") {
                                ForEach(catBreakdown, id: \.category) { row in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(row.category).font(.subheadline)
                                            Spacer()
                                            Text("\(Int(row.accuracy * 100))%")
                                                .font(.subheadline.monospacedDigit())
                                                .foregroundStyle(row.accuracy >= 0.75 ? .green : row.accuracy >= 0.6 ? .orange : .red)
                                        }
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 3).fill(.gray.opacity(0.15)).frame(height: 5)
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(row.accuracy >= 0.75 ? Color.green : row.accuracy >= 0.6 ? Color.orange : Color.red)
                                                    .frame(width: geo.size.width * row.accuracy, height: 5)
                                            }
                                        }
                                        .frame(height: 5)
                                        Text("\(row.attempts) attempts").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }

                        // Weakest structures
                        let weak = stats.weakest.prefix(15)
                        if !weak.isEmpty {
                            Section("Weak Spots — Study These") {
                                ForEach(Array(weak), id: \.name) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name).font(.subheadline)
                                            Text("\(item.stat.correctCount) correct, \(item.stat.incorrectCount) wrong")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(item.stat.accuracyPercent)%")
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundStyle(.red)
                                    }
                                }
                            }
                        }

                        // Strongest structures
                        let strong = stats.strongest.prefix(10)
                        if !strong.isEmpty {
                            Section("Strongest") {
                                ForEach(Array(strong), id: \.name) { item in
                                    HStack {
                                        Text(item.name).font(.subheadline)
                                        Spacer()
                                        Text("\(item.stat.accuracyPercent)%")
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }

                        Section {
                            Button("Reset All Stats", role: .destructive) {
                                showResetConfirm = true
                            }
                        }
                    }
                }
        }
        .confirmationDialog("Reset all quiz history?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { stats.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: Fill-in stats
    @ViewBuilder
    private var fillinStats: some View {
        let all = dataManager.fillBlanks
        let studied = all.filter { (fillProgress.progress[$0.prompt]?.seen ?? 0) > 0 }
        Group {
            if studied.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "text.badge.plus").font(.system(size: 52)).foregroundStyle(.secondary)
                    Text("No fill-in data yet").font(.headline)
                    Text("Use Smart Review on the Fill-In tab to start tracking mastery.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    // Overall
                    let summary = fillProgress.summary(for: all)
                    let stages = fillProgress.stageCounts(for: all)
                    let seenTotal = studied.reduce(0) { $0 + (fillProgress.progress[$1.prompt]?.seen ?? 0) }
                    let correctTotal = studied.reduce(0) { $0 + (fillProgress.progress[$1.prompt]?.correct ?? 0) }
                    let acc = seenTotal > 0 ? Double(correctTotal) / Double(seenTotal) : 0
                    Section("Overall") {
                        HStack {
                            Label("Studied", systemImage: "book.closed.fill")
                            Spacer()
                            Text("\(summary.studied) / \(summary.total)").fontWeight(.semibold)
                        }
                        HStack {
                            Label("Learning (multiple choice)", systemImage: "checklist")
                            Spacer()
                            Text("\(stages.mc)").fontWeight(.semibold).foregroundStyle(.blue)
                        }
                        HStack {
                            Label("Recall (write-in)", systemImage: "pencil.line")
                            Spacer()
                            Text("\(stages.write)").fontWeight(.semibold).foregroundStyle(.indigo)
                        }
                        HStack {
                            Label("Mastered", systemImage: "checkmark.seal.fill")
                            Spacer()
                            Text("\(summary.mastered) / \(summary.total)")
                                .fontWeight(.semibold).foregroundStyle(.green)
                        }
                        HStack {
                            Label("Sentence Accuracy", systemImage: "percent")
                            Spacer()
                            Text("\(Int(acc * 100))%")
                                .fontWeight(.semibold)
                                .foregroundStyle(acc >= 0.75 ? .green : acc >= 0.6 ? .orange : .red)
                        }
                    }

                    // By category (mastered / studied)
                    let cats = Array(Set(all.map { $0.category })).sorted()
                    let catRows: [(cat: String, mastered: Int, studied: Int, total: Int)] = cats.map { c in
                        let qs = all.filter { $0.category == c }
                        let s = fillProgress.summary(for: qs)
                        let st = qs.filter { (fillProgress.progress[$0.prompt]?.seen ?? 0) > 0 }.count
                        return (c, s.mastered, st, s.total)
                    }.filter { $0.studied > 0 }.sorted { $0.mastered * $1.total < $1.mastered * $0.total }
                    if !catRows.isEmpty {
                        Section("By Category (least mastered first)") {
                            ForEach(catRows, id: \.cat) { row in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(row.cat).font(.subheadline)
                                        Spacer()
                                        Text("\(row.mastered)/\(row.total) mastered")
                                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                    }
                                    GeometryReader { geo in
                                        let frac = row.total > 0 ? Double(row.mastered) / Double(row.total) : 0
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 3).fill(.gray.opacity(0.15)).frame(height: 5)
                                            RoundedRectangle(cornerRadius: 3).fill(Color.green)
                                                .frame(width: geo.size.width * frac, height: 5)
                                        }
                                    }
                                    .frame(height: 5)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    // Weak spots: seen but not yet mastered, lowest accuracy first
                    let weak = studied
                        .filter { fillProgress.entry(for: $0.prompt).stage != .mastered }
                        .sorted { a, b in
                            let pa = fillProgress.entry(for: a.prompt), pb = fillProgress.entry(for: b.prompt)
                            let aa = pa.seen > 0 ? Double(pa.correct) / Double(pa.seen) : 0
                            let ab = pb.seen > 0 ? Double(pb.correct) / Double(pb.seen) : 0
                            return aa < ab
                        }
                        .prefix(15)
                    if !weak.isEmpty {
                        Section("Keep Practicing") {
                            ForEach(Array(weak), id: \.prompt) { q in
                                let p = fillProgress.entry(for: q.prompt)
                                let stageLabel = p.stage == .mc ? "multiple choice" : "write-in"
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(q.prompt.replacingOccurrences(of: "___", with: "____"))
                                        .font(.subheadline).lineLimit(2)
                                    Text("\(p.correct)/\(p.seen) correct · \(stageLabel) · \(q.category)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 1)
                            }
                        }
                    }

                    Section {
                        Button("Reset Fill-in Progress", role: .destructive) { showFillResetConfirm = true }
                    }
                }
            }
        }
        .confirmationDialog("Reset all fill-in progress?", isPresented: $showFillResetConfirm, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { fillProgress.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears mastery and scheduling for every fill-in. This cannot be undone.")
        }
    }
}

// MARK: - Guide

struct GuideView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("App Tabs") {
                    Label("IDs — Browse all anatomy categories. Tap a structure for details, or swipe left/right to move through every structure in order — even across categories.", systemImage: "photo.on.rectangle")
                    Label("Traces — Practice tracing molecules step by step through organ systems. Reveal each step one at a time and check key points at the end.", systemImage: "arrow.right.circle")
                    Label("Fill-In — Fill-in-the-blank questions with instant feedback. Smart Review schedules new, missed, and stale questions first so you cycle through and master all of them; Browse All goes straight through by topic. Each fill-in begins as multiple choice and graduates to write-in once mastered (a missed write-in drops it back). Track mastery under Stats › Fill-Ins.", systemImage: "text.badge.plus")
                    Label("Quiz — Timed multiple-choice or write-your-own-answer practice, filterable by category.", systemImage: "pencil")
                    Label("Search — Find any structure instantly by name, alias, or description.", systemImage: "magnifyingglass")
                    Label("Diagrams — Swipeable reference diagrams for arterial, venous, and digestive systems.", systemImage: "photo.stack.fill")
                    Label("Stats — Track your quiz performance over time and see which categories need the most work.", systemImage: "chart.bar.fill")
                    Label("Real Exam — Simulate the actual BIOL 2501 lab practical: timed stations with gross anatomy IDs and histology slides.", systemImage: "clock.badge.checkmark")
                }
                Section("Real Exam Mode") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How It Works").font(.headline)
                        Text("Each station has 5 questions (A–E) and mirrors the format of the actual final practical. You get 1.5 minutes per station. Submit before time runs out — you can't go back.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Histology Stations").font(.headline)
                        Text("Questions A–D follow a logical chain: organ → pointer structure → cell type → function. Question E is always a microscope component. 37 curated scenarios across all 19 BIOL 2501 histology slides.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Answer Matching").font(.headline)
                        Text("Spelling doesn't have to be perfect — the app uses fuzzy matching and accepts common alternate spellings. Slash-separated terms (e.g. \"Light Source/Illuminator\") can be answered with either part.")
                    }.padding(.vertical, 4)
                }
                Section("Study Tips") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fetal Pig IDs").font(.headline)
                        Text("Focus on high-yield structures marked ★. These appear most frequently on practical exams. Use the swipe pager to drill through structures quickly without going back to the list.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Circulatory System").font(.headline)
                        Text("Learn the three fetal shunts: ductus venosus → ligamentum venosum, foramen ovale → fossa ovalis, ductus arteriosus → ligamentum arteriosum.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Heart Valves").font(.headline)
                        Text("\"Try before you buy!\" — TRIcuspid comes BEFORE BIcuspid (mitral) in the direction of blood flow.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Traces (≈22% of exam)").font(.headline)
                        Text("Practice tracing carbohydrates, oxygen, urea, and hormones from origin to destination. Know every organ and vessel along the path — the Traces tab walks you through each one.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Histology").font(.headline)
                        Text("Know the tissue layer, what it looks like under the microscope, and why that epithelium fits that organ. Real Exam mode drills the exact slides from class.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sex Identification").font(.headline)
                        Text("Fetal pigs: females have a genital papilla near the anus/vulva; males have a larger urogenital papilla farther from the anus with a urethral opening at the tip.")
                    }.padding(.vertical, 4)
                }
            }
            .navigationTitle("Study Guide")
        }
    }
}

// MARK: - About

// MARK: - Offline Images

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        OfflineDownloadsView()
                    } label: {
                        Label("Offline Images", systemImage: "arrow.down.circle")
                    }
                    NavigationLink {
                        CloudSyncView()
                    } label: {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                } footer: {
                    Text("Save images for offline use, and manage iCloud sync of your progress across your devices.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct OfflineDownloadsView: View {
    @StateObject private var store = OfflineImageStore.shared
    @State private var showDeleteConfirm = false

    private var isComplete: Bool { store.totalCount > 0 && store.savedCount >= store.totalCount }

    var body: some View {
        List {
            Section {
                if store.isDownloading {
                    VStack(alignment: .leading, spacing: 10) {
                        ProgressView(value: store.progress)
                        Text("Downloading… \(Int(store.progress * 100))%")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Button("Cancel", role: .destructive) { store.cancelDownload() }
                    }
                    .padding(.vertical, 4)
                } else if isComplete {
                    Label("All images downloaded", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button {
                        store.downloadAll()
                    } label: {
                        Label(store.savedCount > 0 ? "Resume download" : "Download all images  (~\(Self.estimatedSizeMB) MB)",
                              systemImage: "arrow.down.circle")
                    }
                }
            } header: {
                Text("Offline Access")
            } footer: {
                Text("Save every photo and histology slide to this device so the app works with no internet — on the subway, in lab, or on airplane mode. About \(store.totalCount) images, roughly \(Self.estimatedSizeMB) MB total. Downloads over Wi-Fi or cellular; stored only on this device.")
            }

            Section("On This Device") {
                LabeledContent("Downloaded", value: "\(store.savedCount) of \(store.totalCount)")
                LabeledContent(store.savedCount > 0 ? "Storage used" : "Estimated size",
                               value: store.savedCount > 0 ? Self.byteString(store.bytesOnDisk) : "~\(Self.estimatedSizeMB) MB")
                if store.lastRunFailures > 0 && !store.isDownloading {
                    Text("\(store.lastRunFailures) image\(store.lastRunFailures == 1 ? "" : "s") couldn't be downloaded. Tap Download again to retry.")
                        .font(.footnote).foregroundStyle(.orange)
                }
            }

            if store.savedCount > 0 {
                Section {
                    Button("Delete downloaded images", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } footer: {
                    Text("Frees up space. The app streams images again as needed.")
                }
            }
        }
        .navigationTitle("Offline Images")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { store.refreshUsage() }
        .confirmationDialog("Delete all downloaded images?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { store.deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This frees \(Self.byteString(store.bytesOnDisk)). You can download them again anytime.")
        }
    }

    /// Rounded estimate shown BEFORE downloading, so users can gauge the size first.
    /// Currently ~414 images ≈ 298 MB (Sep 2026); rounded so it survives content changes.
    private static let estimatedSizeMB = 300

    private static func byteString(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - iCloud Sync

struct CloudSyncView: View {
    @State private var lastSync: Date? = CloudSync.lastSyncDate
    @State private var justSynced = false
    @State private var showResetConfirm = false

    private var lastSyncText: String {
        guard let d = lastSync else { return "Never" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f.localizedString(for: d, relativeTo: Date())
    }

    var body: some View {
            List {
                Section {
                    HStack {
                        Text("iCloud account")
                        Spacer()
                        if CloudSync.isSignedIn {
                            Label("Signed in", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green).labelStyle(.titleAndIcon)
                        } else {
                            Label("Not signed in", systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange).labelStyle(.titleAndIcon)
                        }
                    }
                    LabeledContent("Last synced", value: lastSyncText)
                } header: {
                    Text("Status")
                } footer: {
                    Text("Your stats, flashcard progress, and decks sync across your devices through your own iCloud — no account or backend needed. Sync Now is a two-way merge: it uploads AND downloads, and for each item the most recently changed version wins (nothing gets wiped). Tap it after a study session and again when you pick up another device so the newest progress carries over.")
                }

                Section {
                    Button {
                        syncNow()
                    } label: {
                        HStack {
                            Label("Sync Now  ·  merge with iCloud", systemImage: "arrow.triangle.2.circlepath")
                            if justSynced {
                                Spacer()
                                Image(systemName: "checkmark").foregroundStyle(.green)
                            }
                        }
                    }
                    .disabled(!CloudSync.isSignedIn)
                } footer: {
                    if !CloudSync.isSignedIn {
                        Text("Sign into iCloud in the Settings app to enable syncing. Until then, your progress is saved on this device only.")
                    }
                }

                Section {
                    Button("Reset All Progress", role: .destructive) { showResetConfirm = true }
                } footer: {
                    Text("Erases your quiz stats, flashcard progress, and fill-in mastery on this device and from iCloud, so you can start fresh. Custom decks are kept. If another signed-in device syncs afterward, its progress can return — reset while your other devices are closed.")
                }
            }
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { lastSync = CloudSync.lastSyncDate }
            .confirmationDialog("Reset all progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset Everything", role: .destructive) { resetAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently erases your quiz stats, flashcard progress, and fill-in mastery on this device and in iCloud. This cannot be undone.")
            }
    }

    private func resetAll() {
        StatsManager.shared.reset()
        FlashcardManager.shared.resetAll()
        FillBlankProgressManager.shared.reset()
        TraceProgressManager.shared.reset()
        CloudSync.recordSync()
        _ = CloudSync.flush()
        lastSync = CloudSync.lastSyncDate
    }

    private func syncNow() {
        StatsManager.shared.syncNow()
        FlashcardManager.shared.syncNow()
        DeckManager.shared.syncNow()
        FillBlankProgressManager.shared.syncNow()
        TraceProgressManager.shared.syncNow()
        CloudSync.recordSync()
        _ = CloudSync.flush()
        lastSync = CloudSync.lastSyncDate
        withAnimation { justSynced = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { justSynced = false } }
    }
}

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // App icon + title header
                    VStack(spacing: 12) {
                        Image("AppIconDisplay")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        Text("Dig a Pig Too")
                            .font(.title).fontWeight(.bold)
                        Text("Version 1.5  •  2026")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)

                    Divider()

                    VStack(alignment: .leading, spacing: 20) {

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About This App").font(.headline)
                            Text("Dig a Pig Too is the unofficial sequel to the original Dig a Pig app, rebuilt from the ground up for Columbia University's Contemporary Biology Lab (BIOL 2501). It covers identification, histology, circulatory traces, and fill-in-the-blank practice across all major organ systems.")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("The Original Dig a Pig").font(.headline)
                            Text("This app pays homage to the original Dig a Pig, first released in 2015 and updated in 2017. That app helped thousands of students prepare for dissection lab practicals and already covered gross anatomy, the cow eye, the adult maternal pig uterus station, and the fetal heart.")
                            Text("Dig a Pig Too is the 2026 rebuild, designed for modern iOS and the updated BIOL 2501 curriculum.")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's New in 1.5").font(.headline)
                            Group {
                                Label("Friendly class leaderboard powered by Game Center — see the top 3 right on the IDs page, plus achievements for mastering each area", systemImage: "trophy.fill")
                                Label("A single Mastery Score (Stats & Ranking) weighted like the real practical — physical IDs, then traces, then fill-ins — with bonus points for practicing quizzes and exams", systemImage: "chart.bar.fill")
                                Label("Fill-in Smart Review schedules new, missed, and stale questions first, and graduates each one from multiple choice to write-in as you master it", systemImage: "brain.head.profile")
                                Label("Many more traces — lipid digestion, waste out the GI tract, oxygen from mother to fetal heart, nitrogen to urine — plus short \"Building Blocks\" chunks to memorize in pieces", systemImage: "arrow.right.circle")
                                Label("Traces rewritten to match how the practical is graded: one structure per step, consistent left/right, and full capillary → venule → vein detail", systemImage: "checkmark.seal.fill")
                                Label("New MCAT-tagged fill-ins (adrenal gland, tubular secretion, and more), searchable alongside ID results", systemImage: "text.badge.plus")
                                Label("New Settings tab for offline images and iCloud sync; hardware-keyboard shortcuts on Mac/iPad — number keys pick choices, Return/Space to advance and reveal", systemImage: "keyboard")
                            }
                            .font(.subheadline)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's New in 1.4").font(.headline).foregroundStyle(.secondary)
                            Group {
                                Label("Offline mode: download every photo and histology slide to study with no internet — on the subway, in lab, or on airplane mode", systemImage: "arrow.down.circle")
                                Label("iCloud sync keeps your stats, flashcard progress, and decks in step across your iPhone, iPad, and Mac", systemImage: "icloud")
                                Label("Traces now have a card-based practice mode with step-by-step images and multiple-choice or write-in recall", systemImage: "arrow.right.circle")
                                Label("Real Exam rebuilt: swipeable ID cards, an overhauled set of histology stations, and an \"I got it right\" self-check", systemImage: "clock.badge.checkmark")
                                Label("Quiz difficulty levels — Hard mode serves trickier look-alike options", systemImage: "pencil")
                                Label("Fill-in-the-Blank study mode: multiple-choice or write-in, filterable by topic, with MCAT-relevant tags", systemImage: "text.badge.plus")
                                Label("Photo coverage is complete — every structure in the atlas now has a real dissection or histology image", systemImage: "photo.stack.fill")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's New in 1.3").font(.headline).foregroundStyle(.secondary)
                            Group {
                                Label("Many more real dissection and histology photos: over 65% of structures now have images, with more added throughout the semester", systemImage: "photo.stack.fill")
                                Label("Circulatory System organized into browsable sections for faster navigation", systemImage: "square.grid.2x2.fill")
                                Label("Expanded content from the lab handout: fetal membranes & placenta, femoral vessels, and vessel relationships", systemImage: "checkmark.seal.fill")
                                Label("Write-Answer mode now accepts small wording differences", systemImage: "checkmark.circle.fill")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's New in 1.2").font(.headline).foregroundStyle(.secondary)
                            Group {
                                Label("Launch screen with app icon", systemImage: "iphone")
                                Label("iOS 18 compatibility and Mac availability", systemImage: "checkmark.seal.fill")
                                Label("Search results now swipe within results, not the full atlas", systemImage: "magnifyingglass")
                                Label("First-time swipe hint so new users discover structure browsing", systemImage: "hand.draw.fill")
                                Label("Structure counter in nav bar while browsing (e.g. 3 / 47)", systemImage: "number")
                                Label("Structure counts on each category row in the IDs page", systemImage: "list.number")
                                Label("Swipe up or down to dismiss fullscreen images", systemImage: "arrow.up.and.down")
                                Label("Umbilical vessels and Allantoic Stalk moved to their correct categories", systemImage: "folder.fill")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's New in 1.1").font(.headline).foregroundStyle(.secondary)
                            Group {
                                Label("Real Exam mode: simulate the actual BIOL 2501 lab practical with timed stations, gross anatomy IDs, and 37 curated histology scenarios across all 19 class slides", systemImage: "clock.badge.checkmark")
                                Label("Swipe between structures: browse every anatomy structure left/right in the IDs tab, even across categories, seamlessly", systemImage: "hand.draw.fill")
                                Label("Diagrams tab: swipeable arterial, venous, and digestive system reference diagrams", systemImage: "photo.stack.fill")
                                Label("Improved answer matching: slash-separated terms (e.g. \"Light Source/Illuminator\") accepted as either component individually", systemImage: "checkmark.circle.fill")
                                Label("Category icons throughout the IDs page", systemImage: "square.grid.2x2.fill")
                                Label("Performance and navigation improvements", systemImage: "bolt.fill")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contribute").font(.headline)
                            Text("Help improve the app by contributing dissection and histology photos. Tap the Contribute tab to upload photos for specific structures; submissions are reviewed before being added.")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact & Links").font(.headline)
                            Link(destination: URL(string: "https://instagram.com/cometzfly")!) {
                                Label("@cometzfly on Instagram", systemImage: "camera.fill")
                                    .font(.subheadline)
                            }
                            Link(destination: URL(string: "mailto:ak4906@columbia.edu")!) {
                                Label("ak4906@columbia.edu", systemImage: "envelope.fill")
                                    .font(.subheadline)
                            }
                            Link(destination: URL(string: "https://github.com/ak4906/DigAPigToo")!) {
                                Label("github.com/ak4906/DigAPigToo", systemImage: "chevron.left.forwardslash.chevron.right")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
        }
    }
}

#Preview {
    ContentView()
}
