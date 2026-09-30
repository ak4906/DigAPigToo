//
//  LeaderboardView.swift
//  DigAPigToo
//
//  The in-app leaderboard, powered invisibly by Game Center (rendered in the app's own UI, no
//  Game Center overlay). Two forms:
//   • LeaderboardContent — the full view (your mastery score + breakdown, then the class ranking);
//     hosted inside the "Stats & Ranking" tab.
//   • MiniLeaderboardView — a compact, horizontally-scrolling strip (your score + top-3 medals)
//     pinned atop the IDs page for a motivating glance on launch.
//

import SwiftUI

// MARK: - Full leaderboard (hosted in Stats & Ranking)

struct LeaderboardContent: View {
    @StateObject private var gc = GameCenterManager.shared
    // Observe the progress managers so the score breakdown refreshes as the user studies.
    @StateObject private var fills = FillBlankProgressManager.shared
    @StateObject private var traces = TraceProgressManager.shared
    @StateObject private var cards = FlashcardManager.shared
    @StateObject private var quiz = StatsManager.shared

    var body: some View {
        let m = MasteryScore.current()
        List {
            scoreSection(m)
            leaderboardSection
        }
        .onAppear {
            gc.authenticate()
            Task { await gc.refresh() }
        }
    }

    @ViewBuilder
    private func scoreSection(_ m: MasteryScore) -> some View {
        Section("Your Score") {
            VStack(spacing: 4) {
                Text("\(m.score)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.indigo)
                Text("mastery \(m.masteryPoints)/1000  ·  practice \(m.performancePoints)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            scoreRow("Physical IDs", m.idMastered, m.idTotal, m.idPoints, .blue)
            scoreRow("Traces", m.traceMastered, m.traceTotal, m.tracePoints, .teal)
            scoreRow("Fill-ins", m.fillMastered, m.fillTotal, m.fillPoints, .purple)

            // Practice / performance — the tie-breaker among people who've mastered everything.
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Practice (quizzes & exams)").font(.subheadline)
                    Spacer()
                    Text("\(m.questionsAnswered) answered · \(Int(m.answerAccuracy * 100))% · \(m.performancePoints) pts")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                Text("Reps + accuracy add up to \(Int(MasteryScore.practiceVolumeCap + MasteryScore.accuracyCap)) bonus points.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
    }

    private func scoreRow(_ title: String, _ mastered: Int, _ total: Int, _ points: Int, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Text("\(mastered)/\(total) mastered · \(points) pts")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                let frac = total > 0 ? Double(mastered) / Double(total) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(.gray.opacity(0.15)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(color).frame(width: geo.size.width * frac, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var leaderboardSection: some View {
        Section("Class Leaderboard") {
            if !gc.isAuthenticated {
                Button {
                    gc.authenticate()
                } label: {
                    Label("Sign in to Game Center to compete", systemImage: "person.2.fill")
                        .foregroundStyle(.indigo)
                }
                Text("Optional and friendly. Your Game Center nickname and mastery score are shared so classmates can see who's studying hard — and who to ask for help. Nothing else is shared.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Button {
                    Task { await gc.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(gc.isLoading)

                if gc.isLoading && gc.entries.isEmpty {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
                // Pin the local player's rank if they're outside the visible top list.
                if let me = gc.localEntry, !gc.entries.contains(where: { $0.isLocalPlayer }) {
                    entryRow(me)
                    if !gc.entries.isEmpty { Divider() }
                }
                ForEach(gc.entries) { entryRow($0) }
                if gc.totalPlayers > 0 {
                    Text("\(gc.totalPlayers) player\(gc.totalPlayers == 1 ? "" : "s") competing")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            if let msg = gc.statusMessage {
                Text(msg).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func entryRow(_ e: GameCenterManager.Entry) -> some View {
        HStack(spacing: 12) {
            Text(medal(e.rank))
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .frame(minWidth: 30, alignment: .trailing)
            Text(e.displayName)
                .font(.subheadline.weight(e.isLocalPlayer ? .bold : .regular))
                .lineLimit(1)
            if e.isLocalPlayer {
                Text("You").font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(.indigo.opacity(0.15)).foregroundStyle(.indigo).clipShape(Capsule())
            }
            Spacer()
            Text("\(e.score)").font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .listRowBackground(e.isLocalPlayer ? Color.indigo.opacity(0.08) : nil)
    }

    private func medal(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}

// MARK: - Mini strip (atop the IDs page)

struct MiniLeaderboardView: View {
    @StateObject private var gc = GameCenterManager.shared
    @StateObject private var fills = FillBlankProgressManager.shared
    @StateObject private var traces = TraceProgressManager.shared
    @StateObject private var cards = FlashcardManager.shared
    @StateObject private var quiz = StatsManager.shared

    var body: some View {
        let m = MasteryScore.current()
        let top3 = Array(gc.entries.prefix(3))
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Your own score.
                HStack(spacing: 5) {
                    Image(systemName: "trophy.fill").font(.caption2).foregroundStyle(.indigo)
                    Text("You: \(m.score)").font(.caption.bold()).monospacedDigit()
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(.indigo.opacity(0.12)).clipShape(Capsule())

                if !gc.isAuthenticated {
                    Button { gc.authenticate() } label: {
                        Text("Sign in to compete →").font(.caption)
                    }
                    .buttonStyle(.plain).foregroundStyle(.indigo)
                } else if top3.isEmpty {
                    Text("No rankings yet").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(top3) { e in
                        HStack(spacing: 4) {
                            Text(medal(e.rank))
                            Text(e.displayName).font(.caption).lineLimit(1)
                            Text("\(e.score)").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground)).clipShape(Capsule())
                    }
                }
                if gc.totalPlayers > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill").font(.caption2)
                        Text("\(gc.totalPlayers) competing").font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground)).clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .onAppear {
            gc.authenticate()
            Task { await gc.refresh() }
        }
    }

    private func medal(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)."
        }
    }
}
