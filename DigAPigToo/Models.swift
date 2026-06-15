//
//  Models.swift
//  DigAPigToo
//
//  Created by Alexander Knue on 5/8/26.
//

import Foundation

// MARK: - Diagram / Reference Models

struct DiagramGroup: Identifiable {
    let id = UUID()
    let title: String           // e.g. "Arterial System"
    let description: String     // brief context shown under the title
    let systemImage: String     // SF Symbol for the row icon
    let images: [AnatomyImage]
}

// MARK: - Histology Slides

/// One of the 19 histology slides from the BIOL2501 handout. Used to group the
/// structures inside histology categories by the slide they appear on.
struct HistologySlide: Identifiable, Hashable {
    let number: Int             // 1...19, the handout's slide number
    let handoutName: String     // name as printed in the handout, e.g. "Cardiac stomach"
    let slideName: String       // label on the real physical slide, e.g. "mammal cardiac stomach"
    var id: Int { number }

    /// Section header shown in the slide-grouped list, e.g. "Slide 7/19 · Cardiac Stomach".
    var displayTitle: String { "Slide \(number)/19 · \(handoutName)" }

    /// Section header scoped to the category showing it. Slide 5 ("Trachea & Esophagus")
    /// is split across two categories, so it reads "Trachea" in Respiratory Histology and
    /// "Esophagus" in Gastrointestinal Histology rather than the shared handout name.
    func displayTitle(in categoryName: String) -> String {
        if number == 5 {
            if categoryName == "Gastrointestinal Histology" { return "Slide \(number)/19 · Esophagus" }
            if categoryName == "Respiratory Histology" { return "Slide \(number)/19 · Trachea" }
        }
        return displayTitle
    }
}

// MARK: - Core Anatomy Models

struct AnatomyCategory: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    
    init(name: String, description: String = "") {
        self.id = UUID()
        self.name = name
        self.description = description
    }
}

// Image entry supporting local assets, remote URLs, and microscope magnification levels
struct AnatomyImage: Identifiable, Hashable {
    let id: UUID
    let source: String        // local asset name OR full "https://..." URL
    let magnification: Int?   // 4, 10, 40 for histology slides; nil for gross anatomy
    let caption: String

    var isRemote: Bool { source.hasPrefix("http") }

    init(source: String, magnification: Int? = nil, caption: String = "") {
        self.id = UUID()
        self.source = source
        self.magnification = magnification
        self.caption = caption
    }
}

struct AnatomyStructure: Identifiable, Hashable {
    let id: UUID
    let categoryId: UUID
    let name: String
    let aliases: [String]
    let function: String
    let commonConfusions: [String]
    let examTips: [String]
    let images: [AnatomyImage]
    let imageNames: [String]  // legacy: kept for backward compat, derived from images
    let histology: String
    let connections: String
    let highYield: Bool

    init(
        categoryId: UUID,
        name: String,
        aliases: [String] = [],
        function: String = "",
        commonConfusions: [String] = [],
        examTips: [String] = [],
        imageNames: [String] = [],
        images: [AnatomyImage] = [],
        histology: String = "",
        connections: String = "",
        highYield: Bool = false
    ) {
        self.id = UUID()
        self.categoryId = categoryId
        self.name = name
        self.aliases = aliases
        self.function = function
        self.commonConfusions = commonConfusions
        self.examTips = examTips
        self.images = images
        self.imageNames = imageNames
        self.histology = histology
        self.connections = connections
        self.highYield = highYield
    }
}

// MARK: - Quiz Models

enum QuizMode: String, CaseIterable, Identifiable {
    case multipleChoice = "Multiple Choice"
    case writeAnswer    = "Write Answer"
    case realExam       = "Real Exam"
    var id: String { rawValue }
}

struct QuizQuestion: Identifiable {
    let id: UUID
    let structure: AnatomyStructure
    let imageIndex: Int // which image from structure.imageNames
    let distractors: [String] // wrong answer choices
    
    var allChoices: [String] {
        var choices = [structure.name] + distractors
        choices.shuffle()
        return choices
    }
    
    init(structure: AnatomyStructure, imageIndex: Int = 0, distractors: [String]) {
        self.id = UUID()
        self.structure = structure
        self.imageIndex = imageIndex
        self.distractors = distractors
    }
}

// MARK: - Trace Models

struct TraceStep: Identifiable, Hashable {
    let id: UUID
    let text: String
    let isHighlight: Bool  // key structures to emphasize

    init(_ text: String, highlight: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isHighlight = highlight
    }
}

struct TraceQuestion: Identifiable {
    let id: UUID
    let title: String        // short label, e.g. "Carbohydrate: Mouth → Shoulder Muscle"
    let scenario: String     // full question as it might appear on an exam
    let category: String     // "Digestive", "Circulatory", "Fetal", "Renal", etc.
    let steps: [TraceStep]
    let keyPoints: [String]  // common mistakes / things to remember
    let highYield: Bool

    init(title: String, scenario: String, category: String, steps: [TraceStep], keyPoints: [String] = [], highYield: Bool = false) {
        self.id = UUID()
        self.title = title
        self.scenario = scenario
        self.category = category
        self.steps = steps
        self.keyPoints = keyPoints
        self.highYield = highYield
    }
}

// MARK: - Fill-in-the-Blank Models

struct FillBlankQuestion: Identifiable {
    let id: UUID
    let prompt: String       // sentence with "___" markers
    let answers: [String]    // in order of blanks
    let explanation: String
    let category: String

    init(prompt: String, answers: [String], explanation: String = "", category: String = "General") {
        self.id = UUID()
        self.prompt = prompt
        self.answers = answers
        self.explanation = explanation
        self.category = category
    }
}

// Records one answered question for the results screen
struct AnswerRecord: Identifiable {
    let id = UUID()
    let structureName: String
    let categoryName: String
    let givenAnswer: String
    let wasCorrect: Bool   // stored so fuzzy-match wins are counted correctly
}

struct QuizSession: Identifiable {
    let id: UUID
    let questions: [QuizQuestion]
    let timePerQuestion: TimeInterval // seconds; 0 = unlimited
    let quizMode: QuizMode
    var currentQuestionIndex: Int = 0
    var score: Int = 0
    var answerHistory: [AnswerRecord] = []

    var isComplete: Bool {
        currentQuestionIndex >= questions.count
    }

    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    init(questions: [QuizQuestion], timePerQuestion: TimeInterval = 20, quizMode: QuizMode = .multipleChoice) {
        self.id = UUID()
        self.questions = questions
        self.timePerQuestion = timePerQuestion
        self.quizMode = quizMode
    }
}

// MARK: - Fuzzy Answer Matching

extension AnatomyStructure {
    /// Returns true if `typed` is close enough to match this structure's name or any alias.
    /// Case-insensitive; allows 1–3 character differences scaling with word length.
    /// Also accepts slash-separated terms in either order (e.g. "dorsal/ventral" matches
    /// "Ventral/Dorsal") since the exam accepts either ordering for paired terms.
    func accepts(answer typed: String) -> Bool {
        let typed = typed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !typed.isEmpty else { return false }

        // Build candidate list: name + aliases, each also with slash-parts reversed
        // and each individual slash-component (e.g., "Light Source" from "Light Source/Illuminator").
        var candidates: [String] = []
        for raw in ([name] + aliases).map({ $0.lowercased() }) {
            candidates.append(raw)
            if raw.contains("/") {
                let parts = raw.split(separator: "/", omittingEmptySubsequences: false)
                    .map { String($0).trimmingCharacters(in: .whitespaces) }
                candidates.append(parts.reversed().joined(separator: "/"))
                candidates.append(contentsOf: parts)   // each part individually
            }
        }

        for target in candidates {
            if typed == target { return true }
            let maxLen = max(typed.count, target.count)
            let threshold = maxLen <= 5 ? 1 : maxLen <= 10 ? 2 : 3
            if levenshteinDistance(typed, target) <= threshold { return true }
        }
        return false
    }
}

private func levenshteinDistance(_ s: String, _ t: String) -> Int {
    let s = Array(s), t = Array(t)
    if s.isEmpty { return t.count }
    if t.isEmpty { return s.count }
    var d = Array(repeating: Array(repeating: 0, count: t.count + 1), count: s.count + 1)
    for i in 0...s.count { d[i][0] = i }
    for j in 0...t.count { d[0][j] = j }
    for i in 1...s.count {
        for j in 1...t.count {
            d[i][j] = s[i-1] == t[j-1]
                ? d[i-1][j-1]
                : 1 + min(d[i-1][j], d[i][j-1], d[i-1][j-1])
        }
    }
    return d[s.count][t.count]
}

// MARK: - Real Exam Models

struct ExamItem: Identifiable {
    let id = UUID()
    /// For structure-backed items (most gross anatomy + many histo items).
    let structure: AnatomyStructure?
    /// For concept-only items (D answers like "Mucus secretion").
    /// Slash-separated alternatives are all accepted (e.g. "Vasoconstriction/vasodilation").
    let freeText: String?
    /// Custom question label shown instead of "ID N".
    /// nil → gross anatomy default ("ID 1", "ID 2", …)
    /// non-nil → histology sticky-note style ("A. What organ / tissue is this?", …)
    let questionPrompt: String?
    var givenAnswer: String = ""
    var wasCorrect: Bool = false

    /// Text shown in submitted feedback and results list.
    var correctAnswerDisplay: String {
        structure?.name ?? freeText ?? "?"
    }

    /// Primary init — backed by a named AnatomyStructure.
    init(structure: AnatomyStructure, questionPrompt: String? = nil) {
        self.structure = structure
        self.freeText = nil
        self.questionPrompt = questionPrompt
    }

    /// Secondary init — free-text answer (no matching structure in the DB).
    /// `answer` may contain "/" to list alternative accepted spellings.
    init(freeText: String, questionPrompt: String? = nil) {
        self.structure = nil
        self.freeText = freeText
        self.questionPrompt = questionPrompt
    }

    /// Unified answer checker — delegates to structure fuzzy matching OR
    /// slash-split free-text matching.
    func accepts(typed: String) -> Bool {
        let t = typed.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !t.isEmpty else { return false }
        if let s = structure { return s.accepts(answer: t) }
        guard let answer = freeText else { return false }
        // Build candidate list from slash-separated alternatives.
        var candidates: [String] = [answer.lowercased()]
        let parts = answer.lowercased()
            .split(separator: "/")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
        candidates.append(contentsOf: parts)
        for target in candidates {
            if t == target { return true }
            let maxLen = max(t.count, target.count)
            let threshold = maxLen <= 5 ? 1 : maxLen <= 10 ? 2 : 3
            if levenshteinDistance(t, target) <= threshold { return true }
        }
        return false
    }
}

struct ExamStation: Identifiable {
    let id = UUID()
    var items: [ExamItem]       // always 5
    let timeLimit: TimeInterval
    var isSubmitted: Bool = false
}

struct ExamSession: Identifiable {
    let id = UUID()
    var stations: [ExamStation]
    let timePerStation: TimeInterval
    var currentStationIndex: Int = 0
    var score: Int = 0

    var isComplete: Bool { currentStationIndex >= stations.count }

    var currentStation: ExamStation? {
        guard currentStationIndex < stations.count else { return nil }
        return stations[currentStationIndex]
    }

    var totalItems: Int { stations.reduce(0) { $0 + $1.items.count } }
}
