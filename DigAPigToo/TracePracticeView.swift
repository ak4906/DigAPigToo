//
//  TracePracticeView.swift
//  DigAPigToo
//
//  Card-based active-recall practice for a circulatory/digestive/etc. trace. One step per
//  card: recall the next step (multiple choice OR write-in), then the step is revealed with a
//  BIG image and the card slides away to the next. This is the default view for a trace; the
//  full read-through ("Study") is secondary.
//

import SwiftUI
import UIKit

enum TracePracticeStyle: String, CaseIterable, Identifiable {
    case multipleChoice = "Multiple Choice"
    case writeIn        = "Write-In"
    var id: String { rawValue }
}

struct TracePracticeView: View {
    let trace: TraceQuestion
    /// Image-backed structures resolved per step (passed in from TraceDetailView).
    let stepStructures: [UUID: [AnatomyStructure]]

    @State private var style: TracePracticeStyle = .multipleChoice
    @State private var stepIndex = 0
    @State private var answered = false          // the step's answer is revealed
    @State private var scored = false            // this step has been counted (right/wrong)
    @State private var selected: String? = nil   // MC choice
    @State private var typed = ""                // write-in text
    @State private var gotCount = 0
    @State private var missedSteps: [Int] = []   // step indices answered wrong / missed
    @State private var options: [String] = []    // MC options for the current step
    @State private var showAllPrev = false       // expand the "previous steps" context
    @State private var fullscreenImage: AnatomyImage?   // tapped previous-step thumbnail
    @FocusState private var fieldFocused: Bool

    private var steps: [TraceStep] { trace.steps }
    private var isComplete: Bool { stepIndex >= steps.count }

    var body: some View {
        VStack(spacing: 14) {
            // Practice style + progress.
            Picker("Style", selection: $style) {
                ForEach(TracePracticeStyle.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: style) { resetStepInput() }
            .disabled(answered)

            if !isComplete {
                ProgressView(value: Double(stepIndex), total: Double(max(steps.count, 1)))
                    .tint(.indigo)
            }

            ZStack {
                if isComplete {
                    ScrollView { completionCard }
                        .transition(.opacity)
                } else {
                    ScrollView {
                        card(for: steps[stepIndex])
                    }
                    .id(steps[stepIndex].id)   // new identity per step → slide transition fires
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)))
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding()
        .onAppear { if options.isEmpty { buildOptions() } }
        .fullScreenCover(item: $fullscreenImage) { img in
            ExamImageFullscreen(image: img)
        }
    }

    // MARK: One step's card

    @ViewBuilder private func card(for step: TraceStep) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Step \(stepIndex + 1) of \(steps.count)")
                .font(.caption).foregroundStyle(.secondary)

            // The goal — always visible, in blue so it's clearly the scenario.
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "flag.checkered").font(.caption).foregroundStyle(.blue)
                Text(trace.scenario)
                    .font(.subheadline).fontWeight(.medium).foregroundStyle(.blue)
            }

            // Where you've been — previous steps (last 3, expandable), in orange, with small images.
            if stepIndex > 0 {
                previousSteps
            }

            Divider()

            if answered {
                revealArea(step)
            } else {
                Text(stepIndex == 0 ? "What's the FIRST step?" : "What comes NEXT?")
                    .font(.headline).foregroundStyle(.green)
                if style == .multipleChoice {
                    ForEach(Array(options.enumerated()), id: \.element) { i, opt in
                        Button { chooseMC(opt, correct: step.text) } label: {
                            Text(opt)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(.blue.opacity(0.08))
                                .cornerRadius(10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        // Hardware keyboard: number keys 1–N pick the choice, top to bottom.
                        .numberKeyShortcut(i)
                    }
                } else {
                    TextField("Type the next step…", text: $typed, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .focused($fieldFocused)
                    Button("Reveal Answer") { answered = true; fieldFocused = false }
                        .buttonStyle(.borderedProminent).tint(.indigo)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.gray.opacity(0.12)))
    }

    // MARK: Previous steps (context)

    @ViewBuilder private var previousSteps: some View {
        let prev = Array(0..<stepIndex)
        let shown = showAllPrev ? prev : Array(prev.suffix(3))
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prev.count > 3 && !showAllPrev ? "PREVIOUS STEPS (LAST 3)" : "PREVIOUS STEPS")
                    .font(.caption2).fontWeight(.bold).foregroundStyle(.orange)
                Spacer()
                if prev.count > 3 {
                    Button(showAllPrev ? "Show less" : "Show all \(prev.count)") {
                        withAnimation { showAllPrev.toggle() }
                    }
                    .font(.caption2)
                }
            }
            ForEach(shown, id: \.self) { i in
                let step = steps[i]
                let sts = stepStructures[step.id] ?? []
                HStack(alignment: .top, spacing: 8) {
                    Text("\(i + 1).").font(.caption.monospacedDigit().weight(.bold)).foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.text).font(.caption).foregroundStyle(.secondary)
                        if !sts.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(sts.prefix(4)) { s in
                                    Button { fullscreenImage = s.images.first } label: {
                                        TracePracticeThumb(image: s.images.first, label: "", size: 34)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(.orange.opacity(0.06))
        .cornerRadius(10)
    }

    // MARK: Reveal (answer + big image)

    @ViewBuilder private func revealArea(_ step: TraceStep) -> some View {
        let structures = stepStructures[step.id] ?? []

        // Big image of the step's first structure; extra structures as small tappable thumbs.
        if let first = structures.first, let img = first.images.first {
            AnatomyImageView(image: img, title: first.name)
                .adaptiveImageHeight(phone: 300, padFraction: 0.5)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if structures.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(structures.dropFirst()) { s in
                            NavigationLink { StructureDetailView(structure: s) } label: {
                                TracePracticeThumb(image: s.images.first, label: s.name)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }

        // The answer text.
        Text(step.text)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)

        if style == .multipleChoice, let selected {
            Label(selected == step.text ? "Correct!" : "You chose: \(selected)",
                  systemImage: selected == step.text ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(selected == step.text ? .green : .red)
        }
        if style == .writeIn && !typed.trimmingCharacters(in: .whitespaces).isEmpty {
            Text("You wrote: \(typed)").font(.caption).foregroundStyle(.secondary)
        }

        // Advance controls.
        if style == .writeIn && !scored {
            HStack(spacing: 10) {
                Button { gotCount += 1; scored = true; advance() } label: {
                    Label("I got it right", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.green)
                Button { missedSteps.append(stepIndex); scored = true; advance() } label: {
                    Label("Missed it", systemImage: "xmark").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).tint(.red)
            }
        } else {
            Button(stepIndex + 1 < steps.count ? "Next Step →" : "See Results") { advance() }
                .buttonStyle(.borderedProminent).tint(.indigo)
                .frame(maxWidth: .infinity)
                // Hardware keyboard: Return advances to the next step / results.
                .keyboardShortcut(.return, modifiers: [])
        }
    }

    // MARK: Completion

    @ViewBuilder private var completionCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 56)).foregroundStyle(.green)
            Text("Trace Complete").font(.title2).fontWeight(.semibold)
            Text("\(gotCount) / \(steps.count) recalled").font(.title3).foregroundStyle(.secondary)

            if missedSteps.isEmpty {
                Label("Perfect — every step recalled!", systemImage: "star.fill")
                    .font(.subheadline).foregroundStyle(.green)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Review these steps", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline).foregroundStyle(.orange)
                    ForEach(missedSteps, id: \.self) { i in
                        let sts = stepStructures[steps[i].id] ?? []
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1).").font(.subheadline.weight(.bold)).foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(steps[i].text).font(.subheadline)
                                if !sts.isEmpty {
                                    HStack(spacing: 4) {
                                        ForEach(sts.prefix(4)) { s in
                                            Button { fullscreenImage = s.images.first } label: {
                                                TracePracticeThumb(image: s.images.first, label: "", size: 40)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.orange.opacity(0.08))
                .cornerRadius(12)
            }

            Button("Practice Again") { restart() }
                .buttonStyle(.borderedProminent).tint(.indigo)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    // MARK: Logic

    private func chooseMC(_ choice: String, correct: String) {
        guard !answered else { return }
        selected = choice
        if choice == correct { gotCount += 1 } else { missedSteps.append(stepIndex) }
        scored = true
        withAnimation(.easeInOut(duration: 0.2)) { answered = true }
    }

    private func advance() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            stepIndex += 1
        }
        resetStepInput()
        if !isComplete {
            buildOptions()
        } else {
            // Run finished — log it for trace mastery (feeds the overall mastery score).
            TraceProgressManager.shared.record(title: trace.title, correct: gotCount, total: steps.count)
        }
    }

    private func resetStepInput() {
        answered = false
        scored = false
        selected = nil
        typed = ""
        showAllPrev = false
    }

    private func restart() {
        withAnimation { stepIndex = 0 }
        gotCount = 0
        missedSteps = []
        resetStepInput()
        buildOptions()
    }

    /// MC distractors that keep you on your toes: mostly the NEXT 1–3 steps (are we there yet,
    /// or jumping ahead?) plus one much-later step. To top up, prefer OTHER steps of THIS trace —
    /// they're distinct stages of one pathway, so they can never be a synonym of the answer. Only a
    /// very short trace falls back to other traces, and then we drop anything that reads like the
    /// answer, so a differently-worded name for the SAME structure can't show up as a wrong option.
    private func buildOptions() {
        guard stepIndex < steps.count else { options = []; return }
        let correct = steps[stepIndex].text
        let nearPool = steps.indices
            .filter { $0 > stepIndex && $0 <= stepIndex + 3 }
            .map { steps[$0].text }.filter { $0 != correct }
        let farPool = steps.indices
            .filter { $0 > stepIndex + 3 }
            .map { steps[$0].text }.filter { $0 != correct }

        var picks: [String] = Array(Set(nearPool)).shuffled().prefix(2).map { $0 }
        if let far = Array(Set(farPool)).shuffled().first { picks.append(far) }

        // Top up from this trace's OTHER steps (including earlier ones) before ever borrowing.
        if picks.count < 3 {
            let sameTrace = steps.map(\.text).filter { $0 != correct && !picks.contains($0) }
            picks += Array(Set(sameTrace)).shuffled().prefix(3 - picks.count)
        }
        // Last resort (very short trace): borrow from other traces, excluding anything that
        // matches the answer even loosely — no cross-trace synonym can slip in as "wrong".
        if picks.count < 3 {
            let covered = Set(steps.map(\.text))
            let extra = otherTraceDistractors.filter {
                !covered.contains($0) && $0 != correct && !picks.contains($0)
                && !ExamItem.matchesLeniently($0.lowercased(), against: correct)
            }
            picks += Array(Set(extra)).shuffled().prefix(3 - picks.count)
        }
        options = (Array(picks.prefix(3)) + [correct]).shuffled()
    }

    /// Step texts from OTHER traces (same category preferred) — fallback MC distractors when a
    /// trace is too short or we're near the end.
    private var otherTraceDistractors: [String] {
        let all = AnatomyDataManager.shared.traces
        let sameCat = all.filter { $0.category == trace.category && $0.id != trace.id }
        let pool = sameCat.isEmpty ? all.filter { $0.id != trace.id } : sameCat
        return pool.flatMap { $0.steps.map(\.text) }
    }
}

/// Small tappable thumbnail used under a revealed trace step.
private struct TracePracticeThumb: View {
    let image: AnatomyImage?
    var label: String = ""
    var size: CGFloat = 54
    var body: some View {
        VStack(spacing: 3) {
            Group {
                if let img = image {
                    if img.isRemote {
                        AsyncImage(url: OfflineImageStore.shared.loadURL(for: img.source)) { phase in
                            if let i = phase.image { i.resizable().scaledToFill() }
                            else { Color.gray.opacity(0.12) }
                        }
                    } else if let ui = UIImage(named: img.source) {
                        Image(uiImage: ui).resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.12)
                    }
                } else {
                    Color.gray.opacity(0.12).overlay(Image(systemName: "photo").font(.caption2).foregroundStyle(.secondary))
                }
            }
            .frame(width: size, height: size)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            if !label.isEmpty {
                Text(label).font(.system(size: 9)).lineLimit(1).frame(width: size + 2)
            }
        }
    }
}
