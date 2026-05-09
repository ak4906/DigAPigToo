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
    var wasCorrect: Bool { givenAnswer == structureName }
}

struct QuizSession: Identifiable {
    let id: UUID
    let questions: [QuizQuestion]
    let timePerQuestion: TimeInterval // seconds
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

    init(questions: [QuizQuestion], timePerQuestion: TimeInterval = 20) {
        self.id = UUID()
        self.questions = questions
        self.timePerQuestion = timePerQuestion
    }
}
