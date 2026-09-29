//
//  FillBlankStudyView.swift
//  DigAPigToo
//
//  Active-recall study mode for fill-in-the-blank questions. Works through ONE full sentence at
//  a time, filling its gaps IN ORDER: answer the active gap (multiple choice or write-in), it
//  locks into the sentence, and the next gap becomes active — until the whole sentence is filled,
//  then on to the next question. Launched from the Fill-In list with the current category/MCAT filter.
//

import SwiftUI

struct FillBlankStudyView: View {
    let questions: [FillBlankQuestion]
    /// Smart Review orders by weakest + least-recently-seen (and varies each session);
    /// Browse All keeps the original topic order for a straight pass.
    var useSmartOrder: Bool = true

    enum Mode: String, CaseIterable, Identifiable {
        case multipleChoice = "Multiple Choice"
        case writeIn = "Write-In"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .multipleChoice
    @State private var deck: [FillBlankQuestion] = []   // valid questions, shuffled
    @State private var qIndex = 0
    @State private var blankIndex = 0                   // active gap within the current sentence
    @State private var results: [Bool] = []            // per-gap correct/wrong for the current sentence
    @State private var answeredCurrent = false         // the active gap has been answered
    @State private var options: [String] = []
    @State private var selected: String? = nil
    @State private var typed = ""
    @State private var gotBlanks = 0
    @State private var totalBlanks = 0
    @FocusState private var fieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private var currentQuestion: FillBlankQuestion? {
        (qIndex >= 0 && qIndex < deck.count) ? deck[qIndex] : nil
    }

    var body: some View {
        Group {
            if deck.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "text.badge.plus").font(.largeTitle).foregroundStyle(.secondary)
                    Text("No fill-ins in this selection.").foregroundStyle(.secondary)
                }
            } else if qIndex >= deck.count {
                completion
            } else if let q = currentQuestion {
                runner(q)
            }
        }
        .navigationTitle("Study Fill-Ins")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        .onAppear { if deck.isEmpty { rebuild() } }
    }

    // MARK: Runner
    private func runner(_ q: FillBlankQuestion) -> some View {
        let isLastBlank = blankIndex >= q.answers.count - 1
        return VStack(spacing: 14) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: mode) { startQuestion() }

            HStack {
                Text("Sentence \(qIndex + 1) of \(deck.count)")
                Spacer()
                Text("Gap \(min(blankIndex + 1, q.answers.count)) of \(q.answers.count)")
            }
            .font(.caption).foregroundStyle(.secondary).padding(.horizontal)

            ProgressView(value: Double(qIndex), total: Double(deck.count)).padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(renderedSentence(q))
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.blue.opacity(0.07))
                        .cornerRadius(10)

                    if !answeredCurrent {
                        // Prompt for the ACTIVE gap only.
                        if mode == .multipleChoice {
                            ForEach(Array(options.enumerated()), id: \.element) { i, opt in
                                Button { choose(opt, correct: q.answers[blankIndex]) } label: {
                                    Text(opt)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                                // Hardware keyboard: number keys 1–N pick the choice, top to bottom.
                                .numberKeyShortcut(i)
                            }
                        } else {
                            TextField("Fill gap \(blankIndex + 1)…", text: $typed)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .focused($fieldFocused)
                                .submitLabel(.done)
                                .onSubmit { checkWriteIn(q.answers[blankIndex]) }
                            Button("Check") { checkWriteIn(q.answers[blankIndex]) }
                                .buttonStyle(.borderedProminent).tint(.indigo)
                                .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    } else {
                        // Feedback for the gap just answered (+ explanation once the sentence is done).
                        let ok = results.indices.contains(blankIndex) && results[blankIndex]
                        VStack(alignment: .leading, spacing: 8) {
                            Label(ok ? "Correct" : "Answer: \(q.answers[blankIndex])",
                                  systemImage: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(ok ? .green : .red).font(.subheadline.bold())
                            if mode == .writeIn && !ok {
                                Button { markGotItRight() } label: {
                                    Label("I got it right", systemImage: "checkmark.circle").font(.caption)
                                }
                                .buttonStyle(.bordered).tint(.green).controlSize(.small)
                            }
                            if isLastBlank && !q.explanation.isEmpty {
                                Divider()
                                Text(q.explanation).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((ok ? Color.green : Color.red).opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }

            if answeredCurrent {
                Button(nextButtonTitle(isLastBlank: isLastBlank)) { advance(isLastBlank: isLastBlank) }
                    .buttonStyle(.borderedProminent).tint(.indigo)
                    .frame(maxWidth: .infinity)
                    .padding([.horizontal, .bottom])
                    // Hardware keyboard: Return advances to the next gap / sentence.
                    .keyboardShortcut(.return, modifiers: [])
            }
        }
    }

    private func nextButtonTitle(isLastBlank: Bool) -> String {
        if !isLastBlank { return "Next Gap →" }
        return qIndex + 1 < deck.count ? "Next Sentence →" : "Finish"
    }

    private var completion: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 52)).foregroundStyle(.green)
            Text("\(gotBlanks) / \(totalBlanks) gaps").font(.title2.bold())
            Text("Nice work!").foregroundStyle(.secondary)
            Button("Study Again") { rebuild() }.buttonStyle(.borderedProminent).tint(.indigo)
            Button("Done") { dismiss() }.buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: Rendering
    private func renderedSentence(_ q: FillBlankQuestion) -> AttributedString {
        let parts = q.prompt.components(separatedBy: "___")
        var s = AttributedString()
        for j in parts.indices {
            s += AttributedString(parts[j])
            guard j < q.answers.count else { continue }
            if j < blankIndex || (j == blankIndex && answeredCurrent) {
                // Filled gap: show the correct answer, green if gotten / orange if missed.
                let ok = results.indices.contains(j) && results[j]
                var a = AttributedString(q.answers[j])
                a.foregroundColor = ok ? .green : .orange
                a.font = .body.bold()
                s += a
            } else if j == blankIndex {
                var b = AttributedString(" ______ ")
                b.foregroundColor = .blue
                b.font = .body.bold()
                s += b
            } else {
                var b = AttributedString(" ____ ")
                b.foregroundColor = .secondary
                s += b
            }
        }
        return s
    }

    // MARK: Logic
    private func choose(_ opt: String, correct: String) {
        guard !answeredCurrent else { return }
        selected = opt
        recordResult(opt == correct)
    }

    private func checkWriteIn(_ correct: String) {
        guard !answeredCurrent, !typed.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        fieldFocused = false
        let t = typed.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        recordResult(ExamItem.matchesLeniently(t, against: correct))
    }

    private func recordResult(_ ok: Bool) {
        if results.indices.contains(blankIndex) { results[blankIndex] = ok }
        if ok { gotBlanks += 1 }
        answeredCurrent = true
    }

    private func markGotItRight() {
        guard results.indices.contains(blankIndex), !results[blankIndex] else { return }
        results[blankIndex] = true
        gotBlanks += 1
    }

    private func advance(isLastBlank: Bool) {
        if isLastBlank {
            // Log the whole-sentence attempt (drives mastery + smart order): all gaps right?
            if qIndex < deck.count {
                let allCorrect = !results.isEmpty && results.allSatisfy { $0 }
                FillBlankProgressManager.shared.record(prompt: deck[qIndex].prompt, allCorrect: allCorrect)
            }
            qIndex += 1
            if qIndex < deck.count { startQuestion() }
        } else {
            blankIndex += 1
            answeredCurrent = false
            selected = nil
            typed = ""
            prepareGap()
        }
    }

    private func rebuild() {
        let valid = questions.filter { q in
            q.answers.count > 0 && q.prompt.components(separatedBy: "___").count - 1 == q.answers.count
        }
        deck = useSmartOrder ? FillBlankProgressManager.shared.smartOrder(valid) : valid
        totalBlanks = deck.reduce(0) { $0 + $1.answers.count }
        qIndex = 0
        gotBlanks = 0
        startQuestion()
    }

    private func startQuestion() {
        guard qIndex < deck.count else { return }
        blankIndex = 0
        answeredCurrent = false
        selected = nil
        typed = ""
        results = Array(repeating: false, count: deck[qIndex].answers.count)
        prepareGap()
    }

    private func prepareGap() {
        if mode == .multipleChoice {
            buildOptions()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { fieldFocused = true }
        }
    }

    private func buildOptions() {
        guard let q = currentQuestion, blankIndex < q.answers.count else { options = []; return }
        let correct = q.answers[blankIndex]
        // Distractor pool = every answer in the selection; prefer ones from the same category.
        let sameCat = questions.filter { $0.category == q.category }.flatMap { $0.answers }
        var distractors = Array(Set(sameCat).subtracting([correct])).shuffled().prefix(3).map { $0 }
        if distractors.count < 3 {
            let all = questions.flatMap { $0.answers }
            let rest = Array(Set(all).subtracting(Set(distractors + [correct]))).shuffled()
            distractors += rest.prefix(3 - distractors.count)
        }
        options = ([correct] + distractors).shuffled()
    }
}
