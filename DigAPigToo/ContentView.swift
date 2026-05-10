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
        .ignoresSafeArea(edges: .bottom)
    }
}

// Renders a single AnatomyImage — local asset or remote URL, with zoom label
// Tap anywhere on the image to open a fullscreen pinch-to-zoom viewer.
struct AnatomyImageView: View {
    let image: AnatomyImage
    var fillsFrame: Bool = true        // false → scaledToFit (show full image, no cropping)
    var title: String = ""             // shown in fullscreen nav bar
    var fullscreenMode: FullscreenMode = .structure
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
            .padding(8)
        }
        .background(Color.gray.opacity(0.1))
        .onTapGesture { showFullscreen = true }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageSheet(image: image, title: title, mode: fullscreenMode)
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
            .navigationTitle(currentEntry?.title ?? title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let mag = currentEntry?.image?.magnification {
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

struct QuizCustomizationView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var numQuestions = 10
    @State private var timePerQuestion = 20
    @State private var selectedCategory: AnatomyCategory?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Number of Questions")) {
                    Picker("Questions", selection: $numQuestions) {
                        ForEach([5,10,15,20], id: \.self) { Text("\($0)") }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Time Per Question")) {
                    Picker("Time", selection: $timePerQuestion) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("30").tag(30)
                        Text("Unlimited").tag(0)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Category (Optional)")) {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(Optional<AnatomyCategory>(nil))
                        ForEach(dataManager.categories) { cat in
                            Text(cat.name).tag(Optional(cat))
                        }
                    }
                }

                Section {
                    NavigationLink("Start Quiz") {
                        QuizView(numQuestions: numQuestions, timePerQuestion: timePerQuestion, selectedCategory: selectedCategory)
                    }
                }
            }
            .navigationTitle("Quiz")
        }
    }
}

struct QuizView: View {
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var quizSession: QuizSession?
    @Environment(\.dismiss) var dismiss

    let numQuestions: Int
    let timePerQuestion: Int
    let selectedCategory: AnatomyCategory?

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
        var pool: [AnatomyStructure]
        if let category = selectedCategory {
            pool = dataManager.structures(in: category)
        } else {
            pool = dataManager.structures
        }
        pool.shuffle()
        let chosen = Array(pool.prefix(numQuestions))

        var questions: [QuizQuestion] = []
        for s in chosen {
            let distractorPool = selectedCategory != nil ? pool : dataManager.structures
            let distractors = Array(distractorPool.filter { $0.id != s.id }.shuffled().prefix(3)).map { $0.name }
            questions.append(QuizQuestion(structure: s, distractors: distractors))
        }

        quizSession = QuizSession(questions: questions, timePerQuestion: TimeInterval(timePerQuestion))
    }
}

struct QuizQuestionView: View {
    @Binding var quizSession: QuizSession?
    @StateObject private var statsManager = StatsManager.shared
    @StateObject private var dataManager = AnatomyDataManager.shared
    @State private var shuffledChoices: [String] = []
    @State private var selectedAnswer: String?
    @State private var isAnswered = false
    @State private var timer: Timer?
    @State private var timeRemaining: TimeInterval = 0
    @State private var questionStartDate: Date = Date()

    var body: some View {
        if let session = quizSession, session.currentQuestion != nil {
            VStack(spacing: 16) {
                HStack {
                    Text("Question \(session.currentQuestionIndex + 1)/\(session.questions.count)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Text("Score: \(session.score)")
                        .font(.subheadline.bold())
                }

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

                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.15))
                    .frame(height: 180)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo").font(.system(size: 40)).foregroundStyle(.secondary)
                            Text("What structure is shown?").font(.caption).foregroundStyle(.secondary)
                        }
                    )

                VStack(spacing: 10) {
                    ForEach(shuffledChoices, id: \.self) { choice in
                        Button(action: { answer(choice) }) {
                            Text(choice)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor(choice: choice))
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isAnswered)
                    }
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
        questionStartDate = Date()
        if timeRemaining > 0 { startTimer() }
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

    private func answer(_ choice: String) {
        guard var session = quizSession, let q = session.currentQuestion else { return }
        stopTimer()
        isAnswered = true
        selectedAnswer = choice
        let correct = choice == q.structure.name

        // Find category name for this structure
        let catName = dataManager.categories.first { $0.id == q.structure.categoryId }?.name ?? "Unknown"

        if correct { session.score += 1 }
        session.answerHistory.append(AnswerRecord(
            structureName: q.structure.name,
            categoryName: catName,
            givenAnswer: choice
        ))
        quizSession = session

        // Record to long-term stats
        statsManager.record(structureName: q.structure.name, correct: correct)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { advance() }
    }

    private func advance() {
        stopTimer()
        if var session = quizSession {
            session.currentQuestionIndex += 1
            quizSession = session
        }
    }

    private func buttonColor(choice: String) -> Color {
        guard let session = quizSession, let q = session.currentQuestion else { return .blue }
        if !isAnswered { return .blue }
        if choice == q.structure.name { return .green }
        if choice == selectedAnswer { return .red }
        return .blue.opacity(0.35)
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
                            DiagramDetailView(group: group, allGroups: dataManager.diagramGroups)
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

struct DiagramDetailView: View {
    let group: DiagramGroup
    var allGroups: [DiagramGroup] = []
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            // Full-screen swipeable image gallery
            TabView(selection: $currentIndex) {
                ForEach(Array(group.images.enumerated()), id: \.element.id) { idx, img in
                    AnatomyImageView(image: img, fillsFrame: false, title: group.title,
                                     fullscreenMode: .diagram(allGroups.isEmpty ? [group] : allGroups))
                        .tag(idx)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Caption bar
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
        .navigationTitle(group.title)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .bottom)
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
