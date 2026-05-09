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

    var body: some View {
        NavigationStack {
            List(dataManager.categories) { category in
                NavigationLink(category.name) {
                    StructureListView(category: category)
                }
            }
            .navigationTitle("Dig a Pig Too")
        }
    }
}

struct StructureListView: View {
    let category: AnatomyCategory
    @StateObject private var dataManager = AnatomyDataManager.shared

    var body: some View {
        List(dataManager.structures(in: category)) { structure in
            NavigationLink(structure.name) {
                StructureDetailView(structure: structure)
            }
        }
        .navigationTitle(category.name)
    }
}

struct StructureDetailView: View {
    let structure: AnatomyStructure

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image gallery
                if !structure.images.isEmpty {
                    TabView {
                        ForEach(structure.images) { img in
                            AnatomyImageView(image: img)
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
        .navigationTitle(structure.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Renders a single AnatomyImage — local asset or remote URL, with zoom label
struct AnatomyImageView: View {
    let image: AnatomyImage

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if image.isRemote {
                AsyncImage(url: URL(string: image.source)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        Color.gray.opacity(0.2).overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    default:
                        Color.gray.opacity(0.1).overlay(ProgressView())
                    }
                }
            } else if let uiImg = UIImage(named: image.source) {
                Image(uiImage: uiImg).resizable().scaledToFill()
            } else {
                Color.gray.opacity(0.15)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }

            VStack(alignment: .trailing, spacing: 2) {
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
        .onChange(of: question.id) { _ in revealed = false }
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
    @State private var shuffledChoices: [String] = []
    @State private var selectedAnswer: String?
    @State private var isAnswered = false
    @State private var timer: Timer?
    @State private var timeRemaining: TimeInterval = 0

    var body: some View {
        if let session = quizSession, let question = session.currentQuestion {
            VStack(spacing: 16) {
                HStack {
                    Text("Question \(session.currentQuestionIndex + 1)/\(session.questions.count)")
                    Spacer()
                    Text("Score: \(session.score)")
                }

                if timeRemaining > 0 {
                    Text("Time: \(Int(timeRemaining))s")
                        .font(.headline)
                }

                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 220)
                    .overlay(Image(systemName: "photo").font(.system(size: 44)).foregroundStyle(.secondary))

                Text("What structure is this?")
                    .font(.headline)

                VStack(spacing: 10) {
                    ForEach(shuffledChoices, id: \.self) { choice in
                        Button(action: { answer(choice) }) {
                            Text(choice)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(buttonColor(choice: choice))
                                .foregroundStyle(.white)
                                .cornerRadius(8)
                        }
                        .disabled(isAnswered)
                    }
                }

                Spacer()
            }
            .padding()
            .onChange(of: session.currentQuestionIndex) { _ in resetForNewQuestion() }
            .onAppear {
                if shuffledChoices.isEmpty { resetForNewQuestion() }
            }
            .onDisappear { stopTimer() }
        } else {
            ProgressView()
        }
    }

    private func resetForNewQuestion() {
        stopTimer()
        if let session = quizSession, let q = session.currentQuestion {
            shuffledChoices = q.allChoices
            timeRemaining = session.timePerQuestion
            isAnswered = false
            selectedAnswer = nil
            if timeRemaining > 0 { startTimer() }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeRemaining -= 1
            if timeRemaining <= 0 { timer?.invalidate(); advance() }
        }
    }

    private func stopTimer() { timer?.invalidate(); timer = nil }

    private func answer(_ choice: String) {
        guard var session = quizSession, let q = session.currentQuestion else { return }
        isAnswered = true
        selectedAnswer = choice
        if choice == q.structure.name { session.score += 1 }
        quizSession = session
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { advance() }
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
        return .blue.opacity(0.4)
    }
}

struct QuizResultsView: View {
    let quizSession: QuizSession
    let dismiss: DismissAction

    var percentageScore: Int { Int(Double(quizSession.score) / Double(quizSession.questions.count) * 100) }

    var body: some View {
        VStack(spacing: 20) {
            Text("Quiz Complete!").font(.largeTitle).fontWeight(.bold)
            Text("\(quizSession.score)/\(quizSession.questions.count)").font(.largeTitle).foregroundStyle(.blue)
            Text("\(percentageScore)%").foregroundStyle(.secondary)
            Spacer()
            Button("Back") { dismiss() }.buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Search

struct SearchView: View {
    @State private var searchText = ""
    @StateObject private var dataManager = AnatomyDataManager.shared

    var results: [AnatomyStructure] {
        searchText.isEmpty ? [] : dataManager.searchStructures(query: searchText)
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
                    List(results) { s in
                        NavigationLink(s.name) { StructureDetailView(structure: s) }
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
            }

            Section {
                SubmitButton(state: contributor.state, enabled: canSubmit) {
                    contributor.submit(
                        structureName: selectedStructure?.name ?? "",
                        image: activeImage!,
                        notes: notes
                    )
                }
            }
        }
        .navigationTitle("Contribute Photo")
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
            }

            Section {
                SubmitButton(state: contributor.state, enabled: activeImage != nil) {
                    contributor.submit(
                        structureName: structure.name,
                        image: activeImage!,
                        notes: notes
                    )
                }
            }
        }
        .navigationTitle("Photo for \(structure.name)")
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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dig a Pig Too").font(.largeTitle).fontWeight(.bold)
                        Text("Version 1.0 • 2026").foregroundStyle(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("About This App").font(.headline)
                        Text("Dig a Pig Too is a comprehensive fetal pig anatomy study app built for biology and anatomy students preparing for lab practicals. It covers identification, histology, circulatory traces, and fill-in-the-blank practice across all major organ systems.")
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("The Original Dig a Pig").font(.headline)
                        Text("This app pays homage to the original **Dig a Pig** app, first released in **2015** and updated in **2017**. That app pioneered the digital fetal pig anatomy study experience and helped thousands of students prepare for dissection labs.")
                        Text("Dig a Pig Too builds on that legacy with a fully rebuilt 2026 structure — new trace practice, fill-in-the-blank questions, detailed histology descriptions, and expanded content covering the Cow Eye dissection, Adult Maternal Pig station, and Epithelial Types.")
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Content Coverage").font(.headline)
                        Group {
                            Label("24 anatomy categories", systemImage: "folder")
                            Label("Circulatory system with all named vessels and fetal shunts", systemImage: "heart")
                            Label("Cow Eye dissection structures", systemImage: "eye")
                            Label("Male and Female Reproductive systems", systemImage: "figure.2")
                            Label("Adult Maternal Pig station", systemImage: "leaf")
                            Label("Epithelial Types with mnemonics", systemImage: "square.grid.2x2")
                            Label("Trace practice questions (≈22% of exam)", systemImage: "arrow.right.circle")
                            Label("Fill-in-the-blank questions", systemImage: "text.badge.plus")
                        }
                        .font(.subheadline)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Contribute").font(.headline)
                        Text("Help improve the app by contributing high-quality dissection photos. Tap the Contribute tab to upload photos for specific structures.")
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
        }
    }
}

#Preview {
    ContentView()
}
