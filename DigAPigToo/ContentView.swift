//
//  ContentView.swift
//  DigAPigToo
//
//  Created by Alexander Knue on 5/8/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    var body: some View {
        TabView {
            AtlasView()
                .tabItem { Label("IDs", systemImage: "photo.on.rectangle") }

            TracesView()
                .tabItem { Label("Traces", systemImage: "arrow.right.circle") }

            FillBlankListView()
                .tabItem { Label("Fill-In", systemImage: "text.badge.plus") }

            QuizCustomizationView()
                .tabItem { Label("Quiz", systemImage: "pencil") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            DiagramsView()
                .tabItem { Label("Diagrams", systemImage: "photo.stack.fill") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            GuideView()
                .tabItem { Label("Guide", systemImage: "book") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }

            UploadView()
                .tabItem { Label("Contribute", systemImage: "plus.app") }
        }
    }
}

// MARK: - Atlas

struct AtlasView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared

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
        NavigationStack {
            List {
                ForEach(groups, id: \.title) { group in
                    Section {
                        ForEach(group.categories) { category in
                            NavigationLink {
                                StructureListView(category: category)
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(category.name)
                                            .font(.body)
                                        if !category.description.isEmpty {
                                            Text(category.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                } icon: {
                                    let info = categoryIcon(category.name)
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(info.color)
                                            .frame(width: 32, height: 32)
                                        Image(systemName: info.symbol)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.white)
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
            .navigationTitle("Dig a Pig Too")
        }
    }

    struct IconInfo {
        let symbol: String
        let color: Color
    }

    private func categoryIcon(_ name: String) -> IconInfo {
        switch name {
        // Terminology
        case "Anatomical Planes":           return IconInfo(symbol: "square.split.2x2",                  color: .blue)
        case "Directional Terminology":     return IconInfo(symbol: "arrow.up.left.and.arrow.down.right", color: .blue)
        // Gross anatomy
        case "External":                    return IconInfo(symbol: "pawprint.fill",                      color: Color(red: 0.6, green: 0.35, blue: 0.1))
        case "Buccal Cavity":               return IconInfo(symbol: "mouth.fill",                         color: .pink)
        case "Upper Thoracic":              return IconInfo(symbol: "figure.arms.open",                   color: .indigo)
        case "Peritoneal Cavity":           return IconInfo(symbol: "circle.inset.filled",                color: .orange)
        case "Digestive System":            return IconInfo(symbol: "fork.knife",                         color: .orange)
        case "Respiratory System":          return IconInfo(symbol: "lungs.fill",                         color: .cyan)
        case "Circulatory System":          return IconInfo(symbol: "heart.fill",                         color: .red)
        case "Urinary System":              return IconInfo(symbol: "drop.fill",                          color: Color(red: 0.9, green: 0.7, blue: 0.1))
        case "Male Reproductive":           return IconInfo(symbol: "figure.stand",                       color: .blue)
        case "Female Reproductive":         return IconInfo(symbol: "figure.stand.dress",                 color: .purple)
        case "Fetal Structures":            return IconInfo(symbol: "figure.2.and.child.holdinghands",    color: .teal)
        case "Adult Maternal Pig":          return IconInfo(symbol: "pawprint.fill",                      color: Color(red: 0.5, green: 0.25, blue: 0.05))
        case "Cow Eye":                     return IconInfo(symbol: "eye.fill",                           color: .green)
        // Histology — all use a consistent deep purple
        case "Blood Histology":             return IconInfo(symbol: "drop.fill",                          color: .purple)
        case "Vessel Histology":            return IconInfo(symbol: "waveform.path.ecg",                  color: .purple)
        case "Respiratory Histology":       return IconInfo(symbol: "lungs.fill",                         color: .purple)
        case "Gastrointestinal Histology":  return IconInfo(symbol: "fork.knife",                         color: .purple)
        case "Liver Histology":             return IconInfo(symbol: "leaf.fill",                          color: .purple)
        case "Pancreas Histology":          return IconInfo(symbol: "cross.case.fill",                    color: .purple)
        case "Kidney Histology":            return IconInfo(symbol: "drop.circle.fill",                   color: .purple)
        case "Reproductive Histology":      return IconInfo(symbol: "figure.2",                           color: .purple)
        // Other
        case "Epithelial Types":            return IconInfo(symbol: "square.grid.2x2.fill",               color: .indigo)
        case "Microscope":                  return IconInfo(symbol: "magnifyingglass.circle.fill",         color: .gray)
        default:                            return IconInfo(symbol: "circle.fill",                        color: .gray)
        }
    }
}

struct StructureListView: View {
    let category: AnatomyCategory
    @StateObject private var dataManager = AnatomyDataManager.shared

    var body: some View {
        let ordered = dataManager.orderedStructures
        List(dataManager.structures(in: category)) { structure in
            NavigationLink(structure.name) {
                StructurePagerView(
                    allStructures: ordered,
                    initialIndex: ordered.firstIndex(where: { $0.id == structure.id }) ?? 0
                )
            }
        }
        .navigationTitle(category.name)
    }
}

struct StructureDetailView: View {
    let structure: AnatomyStructure
    @StateObject private var dataManager = AnatomyDataManager.shared

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
                            AnatomyImageView(image: img, fillsFrame: false, title: structure.name)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 300)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.gray.opacity(0.15))
                        .frame(height: 220)
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
    }
}

// MARK: - Structure Pager (swipe left/right between all structures in atlas order)

struct StructurePagerView: View {
    let allStructures: [AnatomyStructure]
    @State private var currentIndex: Int

    init(allStructures: [AnatomyStructure], initialIndex: Int) {
        self.allStructures = allStructures
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(allStructures.enumerated()), id: \.element.id) { idx, structure in
                StructureDetailView(structure: structure)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationTitle(allStructures[currentIndex].name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Renders a single AnatomyImage — local asset or remote URL, with zoom label
// Tap anywhere on the image to open a fullscreen pinch-to-zoom viewer.
struct AnatomyImageView: View {
    let image: AnatomyImage
    var fillsFrame: Bool = true        // false → scaledToFit (show full image, no cropping)
    var title: String = ""             // shown in fullscreen nav bar
    var fullscreenMode: FullscreenMode = .structure
    var hideFullscreenTitle: Bool = false  // true in quiz context — shows "?" instead of answer
    @State private var showFullscreen = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if image.isRemote {
                AsyncImage(url: URL(string: image.source)) { phase in
                    switch phase {
                    case .success(let img):
                        if fillsFrame {
                            img.resizable().scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            img.resizable().scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    case .failure:
                        Color.gray.opacity(0.2).overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    default:
                        Color.gray.opacity(0.1).overlay(ProgressView())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let uiImg = UIImage(named: image.source) {
                if fillsFrame {
                    Image(uiImage: uiImg).resizable().scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Image(uiImage: uiImg).resizable().scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                Color.gray.opacity(0.15)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
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
                                 hideTitle: hideFullscreenTitle)
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

    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var currentIndex = 0

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
                TabView(selection: $currentIndex) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                        FullscreenPageView(image: entry.image, structureName: entry.title)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
            }
            .navigationTitle(hideTitle ? "?" : (currentEntry?.title ?? title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !hideTitle, let mag = currentEntry?.image?.magnification {
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
        .onAppear { currentIndex = initialIndex }
    }
}

/// One page in the fullscreen pager — zoomable image or "no photo" placeholder.
private struct FullscreenPageView: View {
    let image: AnatomyImage?
    let structureName: String

    var body: some View {
        if let img = image {
            if img.isRemote, let url = URL(string: img.source) {
                AsyncZoomableImage(url: url)
            } else if let uiImg = UIImage(named: img.source) {
                ZoomableUIImage(uiImage: uiImg)
            } else {
                noPhotoPlaceholder
            }
        } else {
            noPhotoPlaceholder
        }
    }

    private var noPhotoPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.slash")
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
    @State private var loadedImage: UIImage?

    var body: some View {
        Group {
            if let img = loadedImage {
                ZoomableUIImage(uiImage: img)
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

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        weak var scrollView: UIScrollView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            self.scrollView = scrollView
            return imageView
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
    @State private var practiceMode = false
    @State private var revealedCount = 0

    var body: some View {
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

                if !practiceMode {
                    // Study mode: show full trace
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Full Trace")
                            .font(.headline)
                            .padding(.bottom, 8)

                        ForEach(Array(trace.steps.enumerated()), id: \.element.id) { idx, step in
                            TraceStepRow(step: step, index: idx, isLast: idx == trace.steps.count - 1)
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.05))
                    .cornerRadius(10)
                } else {
                    // Practice mode: reveal steps one by one
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("Practice Mode")
                                .font(.headline)
                            Spacer()
                            Text("\(revealedCount) / \(trace.steps.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.bottom, 8)

                        ForEach(Array(trace.steps.enumerated()), id: \.element.id) { idx, step in
                            if idx < revealedCount {
                                TraceStepRow(step: step, index: idx, isLast: idx == trace.steps.count - 1)
                            } else if idx == revealedCount {
                                Button {
                                    withAnimation(.easeIn(duration: 0.2)) { revealedCount += 1 }
                                } label: {
                                    HStack {
                                        Image(systemName: "eye.slash").foregroundStyle(.secondary)
                                        Text("Tap to reveal next step")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 4)
                                    .background(.blue.opacity(0.07))
                                    .cornerRadius(6)
                                }
                                .padding(.vertical, 2)
                            } else {
                                EmptyView()
                            }
                        }

                        if revealedCount >= trace.steps.count {
                            Label("All steps revealed!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                                .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.05))
                    .cornerRadius(10)

                    if revealedCount > 0 {
                        Button("Reveal All") {
                            withAnimation { revealedCount = trace.steps.count }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                }

                // Key Points
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
        .navigationTitle(trace.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(practiceMode ? "Study Mode" : "Practice Mode") {
                    practiceMode.toggle()
                    revealedCount = 0
                }
                .font(.subheadline)
            }
        }
    }
}

struct TraceStepRow: View {
    let step: TraceStep
    let index: Int
    let isLast: Bool

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
                        .frame(minHeight: 24)
                }
            }
            .frame(width: 28)

            Text(step.text)
                .font(step.isHighlight ? .body.weight(.semibold) : .body)
                .foregroundStyle(step.isHighlight ? .primary : .secondary)
                .padding(.leading, 8)
                .padding(.bottom, isLast ? 0 : 8)
                .padding(.top, 1)
        }
    }
}

// MARK: - Fill-in-the-Blank

struct FillBlankListView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var selectedCategory: String = "All"

    var categories: [String] {
        ["All"] + Array(Set(dataManager.fillBlanks.map { $0.category })).sorted()
    }

    var filtered: [FillBlankQuestion] {
        selectedCategory == "All" ? dataManager.fillBlanks :
            dataManager.fillBlanks.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
                }
                ForEach(filtered) { q in
                    NavigationLink { FillBlankDetailView(question: q) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(q.prompt)
                                .font(.subheadline)
                                .lineLimit(2)
                            Text(q.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Fill-in-the-Blank")
        }
    }
}

struct FillBlankDetailView: View {
    let question: FillBlankQuestion
    @State private var revealed = false

    var highlightedPrompt: AttributedString {
        var result = AttributedString(question.prompt)
        if let range = result.range(of: "___") {
            result[range].foregroundColor = .blue
            result[range].font = .body.bold()
        }
        return result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question")
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text(question.prompt)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.07))
                .cornerRadius(10)

                if revealed {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Answers", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                        ForEach(Array(question.answers.enumerated()), id: \.offset) { i, ans in
                            HStack(alignment: .top, spacing: 6) {
                                Text("Blank \(i + 1):")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                Text(ans)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }
                        }
                        if !question.explanation.isEmpty {
                            Divider()
                            Text(question.explanation)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.green.opacity(0.08))
                    .cornerRadius(10)
                } else {
                    Button {
                        withAnimation { revealed = true }
                    } label: {
                        Label("Reveal Answer", systemImage: "eye.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .cornerRadius(10)
                    }
                }

                Label(question.category, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Fill-in-the-Blank")
        .navigationBarTitleDisplayMode(.inline)
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
    @StateObject private var dataManager = AnatomyDataManager.shared

    // Regular quiz state
    @State private var numQuestions = 10
    @State private var timeSelection = 20   // -1 = custom, 0 = unlimited
    @State private var customTime = 18
    @State private var quizMode: QuizMode = .multipleChoice
    @State private var selectedCategoryIDs: Set<UUID> = []

    // Real Exam state
    @State private var numStations = 30
    @State private var stationTimeSelection = 90   // -1 = custom
    @State private var stationCustomTime = 90

    var effectiveQuizTime: Int   { timeSelection == -1 ? customTime : timeSelection }
    var effectiveStationTime: Int { stationTimeSelection == -1 ? stationCustomTime : stationTimeSelection }

    private var allIDs: Set<UUID> { Set(dataManager.categories.map { $0.id }) }

    var body: some View {
        NavigationStack {
            Form {
                // ── Quiz Mode ──────────────────────────────────────────────
                Section {
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
                } header: { Text("Quiz Mode") }

                // ── Real Exam settings ─────────────────────────────────────
                if quizMode == .realExam {
                    Section {
                        Picker("Stations", selection: $numStations) {
                            ForEach([5, 10, 20, 30], id: \.self) { Text("\($0)") }
                        }
                        .pickerStyle(.segmented)
                        Text("\(numStations) stations × 5 IDs = \(numStations * 5) total items")
                            .font(.caption).foregroundStyle(.secondary)
                    } header: { Text("Number of Stations") }

                    Section {
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
                    } header: { Text("Time Per Station") }

                    Section {
                        let gross = Int((Double(numStations) * 22.0 / 30.0).rounded())
                        let histo = numStations - gross
                        Label("~\(gross) gross anatomy stations, ~\(histo) histology/microscope stations — structures grouped by organ system within each station", systemImage: "chart.pie")
                            .font(.caption).foregroundStyle(.secondary)
                    } header: { Text("Exam Structure") }

                    Section {
                        NavigationLink("Start Exam") {
                            ExamHostView(numStations: numStations, timePerStation: effectiveStationTime)
                        }
                    }

                // ── Regular quiz settings ──────────────────────────────────
                } else {
                    Section {
                        Picker("Questions", selection: $numQuestions) {
                            ForEach([5, 10, 15, 20], id: \.self) { Text("\($0)") }
                        }
                        .pickerStyle(.segmented)
                    } header: { Text("Number of Questions") }

                    Section {
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
                    } header: { Text("Time Per Question") }

                    Section {
                        // Preset toggles: computed inline at press-time to avoid
                        // SwiftUI closure-capture issues with computed properties.
                        // Each preset REPLACES the selection (not additive), and
                        // pressing the same preset a second time clears it.
                        HStack(spacing: 8) {
                            // All
                            let allSet = allIDs
                            QuizPresetButton("All") {
                                selectedCategoryIDs = (selectedCategoryIDs == allSet) ? [] : allSet
                            }
                            // Gross anatomy (excludes histology, microscope, epithelial types,
                            // and the pure reference/terminology categories)
                            let grossSet = Set(dataManager.categories.filter { cat in
                                !cat.name.contains("Histology")
                                    && cat.name != "Microscope"
                                    && cat.name != "Epithelial Types"
                                    && cat.name != "Anatomical Planes"
                                    && cat.name != "Directional Terminology"
                            }.map { $0.id })
                            QuizPresetButton("Gross") {
                                selectedCategoryIDs = (selectedCategoryIDs == grossSet) ? [] : grossSet
                            }
                            // Histology: slide-based categories + Microscope only
                            // (Epithelial Types excluded — they're embedded in histo stations,
                            //  not a standalone quiz category)
                            let histoSet = Set(dataManager.categories.filter { cat in
                                cat.name.contains("Histology")
                                    || cat.name == "Microscope"
                            }.map { $0.id })
                            QuizPresetButton("Histology") {
                                selectedCategoryIDs = (selectedCategoryIDs == histoSet) ? [] : histoSet
                            }
                        }
                        .buttonStyle(.borderless)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                        ForEach(dataManager.categories) { cat in
                            Button {
                                if selectedCategoryIDs.contains(cat.id) {
                                    selectedCategoryIDs.remove(cat.id)
                                } else {
                                    selectedCategoryIDs.insert(cat.id)
                                }
                            } label: {
                                HStack {
                                    Text(cat.name).foregroundStyle(.primary)
                                    Spacer()
                                    if selectedCategoryIDs.contains(cat.id) {
                                        Image(systemName: "checkmark").foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: { Text("Categories") }

                    Section {
                        NavigationLink("Start Quiz") {
                            QuizView(
                                numQuestions: numQuestions,
                                timePerQuestion: effectiveQuizTime,
                                selectedCategoryIDs: selectedCategoryIDs,
                                quizMode: quizMode
                            )
                        }
                        .disabled(selectedCategoryIDs.isEmpty)
                    }
                }
            }
            .navigationTitle("Quiz")
            .onAppear {
                if selectedCategoryIDs.isEmpty { selectedCategoryIDs = allIDs }
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

        // Always draw distractors from the full structure list for variety
        let distractorPool = dataManager.structures
        var questions: [QuizQuestion] = []
        for s in chosen {
            let distractors = Array(distractorPool.filter { $0.id != s.id }.shuffled().prefix(3)).map { $0.name }
            questions.append(QuizQuestion(structure: s, distractors: distractors))
        }

        quizSession = QuizSession(questions: questions, timePerQuestion: TimeInterval(timePerQuestion), quizMode: quizMode)
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

    // Multiple-choice state
    @State private var shuffledChoices: [String] = []
    @State private var selectedAnswer: String?

    // Free-write state
    @State private var typedAnswer = ""
    @State private var freeWriteCorrect = false
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

                // Photo
                Group {
                    if let q = session.currentQuestion, !q.structure.images.isEmpty {
                        let img = q.structure.images[min(q.imageIndex, q.structure.images.count - 1)]
                        AnatomyImageView(image: img, fillsFrame: false, title: q.structure.name,
                                         hideFullscreenTitle: true)
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
                .frame(height: 180)
                .clipped()

                // Answer area — branches on quiz mode
                if session.quizMode == .writeAnswer {
                    freeWriteAnswerArea(session: session)
                } else {
                    multipleChoiceAnswerArea(session: session)
                }

                Spacer()
            }
            .padding()
            .onChange(of: session.currentQuestionIndex) { resetForNewQuestion() }
            .onAppear {
                if shuffledChoices.isEmpty { resetForNewQuestion() }
                else { restartTimerFromDate() }
            }
            .onDisappear { stopTimer() }
        } else {
            ProgressView()
        }
    }

    // MARK: Multiple-choice answer buttons
    @ViewBuilder
    private func multipleChoiceAnswerArea(session: QuizSession) -> some View {
        VStack(spacing: 10) {
            ForEach(shuffledChoices, id: \.self) { choice in
                Button(action: { answerMultipleChoice(choice) }) {
                    Text(choice)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(mcButtonColor(choice: choice, session: session))
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(isAnswered)
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
        questionStartDate = Date()
        if timeRemaining > 0 { startTimer() }
        if session.quizMode == .writeAnswer { fieldFocused = true }
    }

    private func restartTimerFromDate() {
        guard let session = quizSession, session.timePerQuestion > 0, !isAnswered else { return }
        let elapsed = Date().timeIntervalSince(questionStartDate)
        timeRemaining = max(0, session.timePerQuestion - elapsed)
        if timeRemaining <= 0 { advance(); return }
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
                advance()
            } else {
                timeRemaining = remaining
            }
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

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
            structureName: q.structure.name,
            categoryName: catName,
            givenAnswer: typedAnswer.isEmpty ? "(no answer)" : typedAnswer,
            wasCorrect: correct
        ))
        quizSession = s
        statsManager.record(structureName: q.structure.name, correct: correct)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { advance() }
    }

    private func dontKnow(session: QuizSession) {
        guard var s = quizSession, let q = s.currentQuestion, !isAnswered else { return }
        stopTimer()
        fieldFocused = false
        isAnswered = true
        freeWriteCorrect = false
        let catName = dataManager.categories.first { $0.id == q.structure.categoryId }?.name ?? "Unknown"
        s.answerHistory.append(AnswerRecord(
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

    var pct: Int { Int(Double(quizSession.score) / Double(quizSession.questions.count) * 100) }
    var grade: String {
        switch pct {
        case 90...100: return "Excellent! 🎉"
        case 75..<90:  return "Good work!"
        case 60..<75:  return "Getting there"
        default:       return "Keep studying"
        }
    }

    // Missed questions
    var missed: [AnswerRecord] { quizSession.answerHistory.filter { !$0.wasCorrect } }

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
                    Text("\(quizSession.score) / \(quizSession.questions.count)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(pct >= 75 ? .green : pct >= 60 ? .orange : .red)
                    Text("\(pct)%").font(.title3).foregroundStyle(.secondary)
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

                // Missed questions
                if !missed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Missed (\(missed.count))", systemImage: "xmark.circle.fill")
                            .font(.headline).foregroundStyle(.red)
                        ForEach(missed) { record in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.red).font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.structureName).font(.subheadline).fontWeight(.semibold)
                                    Text("You answered: \(record.givenAnswer)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.red.opacity(0.06))
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

// MARK: - Real Exam Mode

struct ExamHostView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var examSession: ExamSession?
    @Environment(\.dismiss) var dismiss

    let numStations: Int
    let timePerStation: Int

    var body: some View {
        Group {
            if let session = examSession {
                if session.isComplete {
                    ExamResultsView(session: session, dismiss: dismiss)
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
            let items = (0..<5).map { ExamItem(structure: shuffled[$0 % shuffled.count]) }
            return ExamStation(items: items, timeLimit: tl)
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
            "Cranial Vena Cava", "Caudal Vena Cava", "Subclavian Arteries and Veins",
            "Axillary Arteries and Veins", "Thyrocervical Trunk",
            "Internal Thoracic Arteries and Veins", "External Thoracic Arteries",
            "Subscapular Veins", "Costocervical Veins"
        ]
        let abdominalVesselNames: Set<String> = [
            "Celiac Artery", "Hepatic Artery", "Hepatic Portal Vein", "Liver Sinusoids",
            "Hepatic Vein", "Cranial Mesenteric Artery", "Caudal Mesenteric Artery",
            "Mesenteric Vein", "Jejunal Arteries and Veins", "Gastric Artery and Vein",
            "Gastroepiploic Artery and Vein", "Splenic Artery and Vein",
            "Splenogastric Vein", "Renal Arteries", "Renal Veins"
        ]
        // Pelvic vessels split: sex-neutral vessels shared by both sexes,
        // plus gonadal vessels that are sex-exclusive — never mix male + female
        // gonadal vessels in the same station (one pig is one sex).
        let pelvicNeutralNames: Set<String> = [
            "Common Iliac Vein", "Internal Iliac Artery and Vein",
            "External Iliac Artery and Vein",
            "Deep Femoral Artery and Vein", "Deep Circumflex Iliac Artery and Vein"
        ]
        let pelvicMaleNames:   Set<String> = ["Testicular Artery", "Testicular Vein"]
        let pelvicFemaleNames: Set<String> = ["Ovarian Artery and Vein"]

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
        let urinaryIntactNames: Set<String> = [
            "Adrenal Gland", "Ureter", "Urinary Bladder", "Urethra"
        ]
        let urinaryIntact = structs(in: ["Urinary System"]).filter { urinaryIntactNames.contains($0.name) }
                          + structs(in: ["Peritoneal Cavity"]).filter { $0.name == "Kidney" }

        // 2) Adult/cut kidney cross-section: internal collecting anatomy.
        //    Renal Medulla lives in Kidney Histology; Renal Arteries in Circulatory.
        //    Both are visible in a sectioned specimen, so pull them cross-category.
        let urinarySectionedNames: Set<String> = [
            "Renal Cortex", "Renal Pelvis", "Renal Calyx", "Renal Pyramid"
        ]
        let urinarySectioned = structs(in: ["Urinary System"]).filter { urinarySectionedNames.contains($0.name) }
                             + structs(in: ["Kidney Histology"]).filter { $0.name == "Renal Medulla" }
                             + structs(in: ["Circulatory System"]).filter { $0.name == "Renal Arteries" }

        // MARK: Reproductive histology sub-pools
        // Male (testis) and female (ovary) are different slides — never mix them.
        let reproAll = structs(in: ["Reproductive Histology"])
        let maleReproNames: Set<String> = [
            "Seminiferous Tubule", "Spermatogonia", "Spermatocytes",
            "Spermatids", "Spermatozoa", "Leydig Cells"
        ]
        let reproMale   = reproAll.filter {  maleReproNames.contains($0.name) }
        let reproFemale = reproAll.filter { !maleReproNames.contains($0.name) }

        // MARK: Histology station builders

        // Slides that visibly feature a distinctive epithelium get a 30% chance of
        // an Epithelial Types bonus; all others always get a Microscope component.
        let epithelialSlides: Set<String> = [
            "Gastrointestinal Histology", "Vessel Histology", "Respiratory Histology"
        ]

        func makeHistoStation(mainCatNames: [String]) -> ExamStation {
            let slidePool = structs(in: mainCatNames).shuffled()
            guard !slidePool.isEmpty else { return ExamStation(items: [], timeLimit: tl) }

            let canUseEpithelial = mainCatNames.contains { epithelialSlides.contains($0) }
            let useMicroscope = !canUseEpithelial || Double.random(in: 0...1) < 0.7
            let bonusCatName = useMicroscope ? "Microscope" : "Epithelial Types"
            let bonusPool = structs(in: [bonusCatName]).shuffled()

            let slideItems = (0..<4).map { ExamItem(structure: slidePool[$0 % slidePool.count]) }
            let bonusItem: ExamItem = bonusPool.isEmpty
                ? ExamItem(structure: slidePool[4 % slidePool.count])
                : ExamItem(structure: bonusPool[0])

            return ExamStation(items: (slideItems + [bonusItem]).shuffled(), timeLimit: tl)
        }

        // Reproductive histology: pick one sex at random per station,
        // always pair with a Microscope component (epithelium not distinctive here).
        func makeReproHistoStation() -> ExamStation {
            let pool = (Bool.random() ? reproMale : reproFemale).shuffled()
            guard !pool.isEmpty else { return ExamStation(items: [], timeLimit: tl) }
            let bonusPool = structs(in: ["Microscope"]).shuffled()
            let slideItems = (0..<4).map { ExamItem(structure: pool[$0 % pool.count]) }
            let bonusItem: ExamItem = bonusPool.isEmpty
                ? ExamItem(structure: pool[4 % pool.count])
                : ExamItem(structure: bonusPool[0])
            return ExamStation(items: (slideItems + [bonusItem]).shuffled(), timeLimit: tl)
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
            { station(from: urinaryIntact) },
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

        // Histo pool — each histology station draws from ONE slide context.
        // GI gets double weight to match the two GI stations on the real exam.
        let histoPool: [() -> ExamStation] = [
            { makeHistoStation(mainCatNames: ["Gastrointestinal Histology"]) },
            { makeHistoStation(mainCatNames: ["Gastrointestinal Histology"]) },
            { makeHistoStation(mainCatNames: ["Kidney Histology"]) },
            { makeHistoStation(mainCatNames: ["Blood Histology"]) },
            { makeHistoStation(mainCatNames: ["Vessel Histology"]) },
            { makeHistoStation(mainCatNames: ["Liver Histology"]) },
            { makeHistoStation(mainCatNames: ["Pancreas Histology"]) },
            { makeHistoStation(mainCatNames: ["Respiratory Histology"]) },
            { makeReproHistoStation() },
        ]

        // MARK: Build
        let histoCount = max(1, Int((Double(numStations) * 8.0 / 30.0).rounded()))
        let grossCount = numStations - histoCount

        let shuffledGross = grossPool.shuffled()
        let shuffledHisto = histoPool.shuffled()
        var stations: [ExamStation] = []

        for i in 0..<grossCount { stations.append(shuffledGross[i % shuffledGross.count]()) }
        for i in 0..<histoCount { stations.append(shuffledHisto[i % shuffledHisto.count]()) }

        examSession = ExamSession(stations: stations.shuffled(), timePerStation: tl)
    }
}

struct ExamStationView: View {
    @Binding var examSession: ExamSession?
    @StateObject private var dataManager = AnatomyDataManager.shared

    @State private var answers: [String] = Array(repeating: "", count: 5)
    @State private var isSubmitted = false
    @State private var timer: Timer?
    @State private var timeRemaining: TimeInterval = 90
    @State private var stationStartDate = Date()

    var body: some View {
        if let session = examSession, let station = session.currentStation {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Station \(session.currentStationIndex + 1) / \(session.stations.count)")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text("Score: \(session.score) / \(session.currentStationIndex * 5)")
                            .font(.subheadline.bold())
                    }

                    // Timer bar
                    if station.timeLimit > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(.gray.opacity(0.2)).frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(examTimerColor)
                                    .frame(width: max(0, CGFloat(timeRemaining / station.timeLimit)) * geo.size.width, height: 8)
                            }
                        }
                        .frame(height: 8)
                        Text(isSubmitted ? "Submitted" : "\(Int(ceil(timeRemaining)))s remaining")
                            .font(.caption.monospacedDigit()).foregroundStyle(examTimerColor)
                    }

                    // 5 item rows
                    VStack(spacing: 10) {
                        ForEach(Array(station.items.enumerated()), id: \.element.id) { idx, item in
                            ExamItemRow(
                                index: idx,
                                item: item,
                                answer: idx < answers.count ? $answers[idx] : .constant(""),
                                isSubmitted: isSubmitted
                            )
                        }
                    }

                    // Action button
                    if isSubmitted {
                        Button(session.currentStationIndex + 1 < session.stations.count
                               ? "Next Station →"
                               : "See Results") { advance() }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Submit Station") { submitStation() }
                            .buttonStyle(.borderedProminent)
                            .tint(.indigo)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .onAppear { resetForStation(station) }
            .onChange(of: session.currentStationIndex) {
                if let s = examSession, let st = s.currentStation { resetForStation(st) }
            }
            .onDisappear { stopTimer() }
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

    private func resetForStation(_ station: ExamStation) {
        stopTimer()
        answers = Array(repeating: "", count: station.items.count)
        isSubmitted = false
        timeRemaining = station.timeLimit
        stationStartDate = Date()
        if timeRemaining > 0 { startTimer() }
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
            let correct = updatedStation.items[idx].structure.accepts(answer: typed)
            updatedStation.items[idx].givenAnswer = typed.isEmpty ? "(blank)" : typed
            updatedStation.items[idx].wasCorrect = correct
            if correct { session.score += 1 }
        }
        updatedStation.isSubmitted = true
        session.stations[session.currentStationIndex] = updatedStation
        examSession = session
    }

    private func advance() {
        stopTimer()
        if var session = examSession {
            session.currentStationIndex += 1
            examSession = session
        }
    }
}

struct ExamItemRow: View {
    let index: Int
    let item: ExamItem
    @Binding var answer: String
    let isSubmitted: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Small thumbnail
            ExamItemThumbnail(images: item.structure.images)

            VStack(alignment: .leading, spacing: 4) {
                Text("ID \(index + 1)").font(.caption2).foregroundStyle(.tertiary)

                if isSubmitted {
                    HStack(spacing: 6) {
                        Image(systemName: item.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.wasCorrect ? .green : .red)
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.structure.name)
                                .font(.subheadline)
                                .fontWeight(item.wasCorrect ? .regular : .semibold)
                                .foregroundStyle(item.wasCorrect ? Color.primary : Color.red)
                            if !item.wasCorrect && item.givenAnswer != "(blank)" {
                                Text("You wrote: \(item.givenAnswer)")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                } else {
                    TextField("Structure name…", text: $answer)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.subheadline)
                }
            }
        }
        .padding(10)
        .background(.gray.opacity(0.06))
        .cornerRadius(10)
    }
}

struct ExamItemThumbnail: View {
    let images: [AnatomyImage]
    // Use item-based fullScreenCover so the image is guaranteed non-nil when the
    // sheet opens — avoids the isPresented + separate state timing race.
    @State private var fullscreenImage: AnatomyImage?

    var body: some View {
        Group {
            if let img = images.first {
                if img.isRemote {
                    AsyncImage(url: URL(string: img.source)) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color.gray.opacity(0.12)
                        }
                    }
                } else {
                    Image(img.source).resizable().scaledToFill()
                }
            } else {
                Color.gray.opacity(0.12)
                    .overlay(Image(systemName: "camera").foregroundStyle(.secondary.opacity(0.5)))
            }
        }
        .frame(width: 65, height: 65)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        // Zoom-hint badge (only when an image exists)
        .overlay(alignment: .bottomTrailing) {
            if !images.isEmpty {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 7, weight: .semibold))
                    .padding(3)
                    .background(.black.opacity(0.6))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .padding(3)
            }
        }
        .onTapGesture {
            // randomElement() picks one image; setting it triggers the sheet.
            fullscreenImage = images.randomElement()
        }
        .fullScreenCover(item: $fullscreenImage) { img in
            ExamImageFullscreen(image: img)
        }
    }
}

/// Fullscreen zoomable viewer for one exam ID image (single, no multi-image paging).
struct ExamImageFullscreen: View {
    let image: AnatomyImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                // Use a single-page TabView — gives ZoomableUIImage a proper full-screen
                // frame the same way FullscreenImageSheet does. Direct ZStack placement
                // leaves UIViewRepresentable with zero proposed size → black screen.
                TabView {
                    FullscreenPageView(image: image, structureName: "")
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
                                ForEach(station.items) { item in
                                    HStack(spacing: 8) {
                                        Image(systemName: item.wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(item.wasCorrect ? .green : .red)
                                            .font(.caption)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.structure.name).font(.caption).fontWeight(.semibold)
                                            if !item.wasCorrect {
                                                Text("You wrote: \(item.givenAnswer)").font(.caption2).foregroundStyle(.secondary)
                                            }
                                        }
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
    @State private var searchText = ""
    @StateObject private var dataManager = AnatomyDataManager.shared

    var results: [AnatomyStructure] {
        searchText.isEmpty ? [] : dataManager.searchStructures(query: searchText)
    }

    private func categoryName(for structure: AnatomyStructure) -> String {
        dataManager.categories.first { $0.id == structure.categoryId }?.name ?? ""
    }

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass").font(.largeTitle)
                        Text("Search for structures").foregroundStyle(.secondary)
                    }
                } else {
                    let ordered = dataManager.orderedStructures
                    List(results) { s in
                        NavigationLink(destination: StructurePagerView(
                            allStructures: ordered,
                            initialIndex: ordered.firstIndex(where: { $0.id == s.id }) ?? 0
                        )) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(s.name)
                                    .font(.body)
                                let cat = categoryName(for: s)
                                if !cat.isEmpty {
                                    Label(cat, systemImage: "folder")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search structures")
            .navigationTitle("Search")
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
    @StateObject private var dataManager = AnatomyDataManager.shared

    var body: some View {
        NavigationStack {
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
                        NavigationLink {
                            DiagramPagerView(
                                allGroups: dataManager.diagramGroups,
                                initialIndex: dataManager.diagramGroups.firstIndex(where: { $0.id == group.id }) ?? 0
                            )
                        } label: {
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
                }
            }
            .navigationTitle("Diagrams")
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

struct StatsView: View {
    @StateObject private var stats = StatsManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
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
            .navigationTitle("My Stats")
            .confirmationDialog("Reset all quiz history?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { stats.reset() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
}

// MARK: - Guide

struct GuideView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Getting Started") {
                    Label("IDs — Browse anatomy categories and structures with detailed descriptions, histology, and connections.", systemImage: "photo.on.rectangle")
                    Label("Traces — Practice tracing molecules and substances through organ systems step by step.", systemImage: "arrow.right.circle")
                    Label("Fill-In — Complete fill-in-the-blank anatomy questions with instant feedback.", systemImage: "text.badge.plus")
                    Label("Quiz — Test yourself with timed multiple-choice questions by category.", systemImage: "pencil")
                    Label("Search — Find any structure by name or alias instantly.", systemImage: "magnifyingglass")
                }
                Section("Study Tips") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fetal Pig Dissection").font(.headline)
                        Text("Focus on high-yield structures marked ★. These appear most frequently on practical exams.")
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
                        Text("Traces (22% of exam)").font(.headline)
                        Text("Practice tracing carbohydrates, oxygen, urea, and hormones from origin to destination. Know every organ and vessel along the path.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Epithelial Types").font(.headline)
                        Text("Memorize which epithelium lines each organ. Histology slides often appear on practicals — know the tissue layer and why it suits that location.")
                    }.padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sex Identification").font(.headline)
                        Text("Fetal pigs: females have a genital papilla near the anus/vulva; males have a larger urogenital papilla farther from the anus with a urethral opening at the tip.")
                    }.padding(.vertical, 4)
                }
                Section("Cow Eye") {
                    Text("The tapetum lucidum is the iridescent reflective layer in the choroid — gives animals night vision and causes 'eyeshine.' This is a high-yield ID structure.")
                    Text("Light path: Cornea → Aqueous humor → Pupil → Lens → Vitreous body → Retina → Optic nerve → Brain")
                }
            }
            .navigationTitle("Study Guide")
        }
    }
}

// MARK: - About

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
                        Text("Version 1.0  •  2026")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)

                    Divider()

                    VStack(alignment: .leading, spacing: 20) {

                        VStack(alignment: .leading, spacing: 8) {
                            Text("About This App").font(.headline)
                            Text("Dig a Pig Too is the unofficial sequel to the original Dig a Pig app — rebuilt from the ground up for Columbia University's Contemporary Biology Lab (BIOL 2501). It covers identification, histology, circulatory traces, and fill-in-the-blank practice across all major organ systems.")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("The Original Dig a Pig").font(.headline)
                            Text("This app pays homage to the original Dig a Pig, first released in 2015 and updated in 2017. That app helped thousands of students prepare for dissection lab practicals and already covered gross anatomy, the cow eye, the adult maternal pig uterus station, and the fetal heart.")
                            Text("Dig a Pig Too is the 2026 rebuild — designed for modern iOS and the updated BIOL 2501 curriculum.")
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's New in This Version").font(.headline)
                            Group {
                                Label("Full histology coverage — blood, vessel, respiratory, GI, liver, pancreas, kidney, and reproductive slides", systemImage: "magnifyingglass.circle.fill")
                                Label("Microscope component IDs", systemImage: "scope")
                                Label("Trace practice questions covering ≈22% of the exam", systemImage: "arrow.right.circle.fill")
                                Label("Fill-in-the-blank questions", systemImage: "text.badge.plus")
                                Label("Long-term quiz stats and weak spot tracking", systemImage: "chart.bar.fill")
                                Label("300+ structures across 24 categories", systemImage: "folder.fill")
                                Label("Rebuilt for iOS 26", systemImage: "iphone")
                            }
                            .font(.subheadline)
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contribute").font(.headline)
                            Text("Help improve the app by contributing dissection and histology photos. Tap the Contribute tab to upload photos for specific structures — submissions are reviewed before being added.")
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
