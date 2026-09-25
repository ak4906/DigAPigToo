//
//  CategoryPicker.swift
//  DigAPigToo
//
//  Shared category-selection UI used by BOTH the Quiz and Flashcards setup screens, so
//  the two pages look identical instead of hand-matched. Also a shared "start" button
//  label so those match too.
//

import SwiftUI

/// A preset-macro row (All / Gross / Histology) plus the categories grouped
/// (Terminology / Gross Anatomy / Histology / Other). Each row is a left selection
/// circle + name + trailing count. Drop directly inside a Form or List.
struct CategoryPickerSections: View {
    @ObservedObject private var dataManager = AnatomyDataManager.shared
    @Binding var selected: Set<UUID>
    /// Trailing count per category (structures for Quiz, image-backed cards for Flashcards).
    let count: (AnatomyCategory) -> Int
    /// Whether a category can be selected (Flashcards disables 0-card categories).
    var isEnabled: (AnatomyCategory) -> Bool = { _ in true }

    // Ordered groups, mirroring the IDs page.
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

    private var allSet: Set<UUID> {
        Set(dataManager.categories.filter { isEnabled($0) }.map { $0.id })
    }
    private var grossSet: Set<UUID> {
        Set(dataManager.categories.filter { c in
            isEnabled(c)
                && !c.name.contains("Histology")
                && c.name != "Microscope"
                && c.name != "Epithelial Types"
                && c.name != "Anatomical Planes"
                && c.name != "Directional Terminology"
        }.map { $0.id })
    }
    private var histoSet: Set<UUID> {
        Set(dataManager.categories.filter { c in
            isEnabled(c) && (c.name.contains("Histology") || c.name == "Microscope")
        }.map { $0.id })
    }

    var body: some View {
        // Preset macros. Each REPLACES the selection; pressing again clears it.
        Section {
            HStack(spacing: 8) {
                QuizPresetButton("All") { selected = (selected == allSet) ? [] : allSet }
                QuizPresetButton("Gross") { selected = (selected == grossSet) ? [] : grossSet }
                QuizPresetButton("Histology") { selected = (selected == histoSet) ? [] : histoSet }
            }
            .buttonStyle(.borderless)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: { Text("Categories") }

        ForEach(groups, id: \.title) { group in
            Section(group.title) {
                ForEach(group.categories) { cat in
                    let enabled = isEnabled(cat)
                    Button {
                        guard enabled else { return }
                        if selected.contains(cat.id) { selected.remove(cat.id) }
                        else { selected.insert(cat.id) }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: selected.contains(cat.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected.contains(cat.id) ? .blue : .secondary)
                            Text(cat.name).foregroundStyle(enabled ? .primary : .secondary)
                            Spacer()
                            Text("\(count(cat))").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                }
            }
        }
    }
}

/// Shared label for the "start" row on both setup screens (icon + bold title + subtitle
/// + chevron), so Start Quiz / Start Exam / Start Studying all look the same.
struct StartRowLabel: View {
    let title: String
    let subtitle: String
    var systemImage: String = "play.fill"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).font(.title3).foregroundStyle(.blue).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
        }
    }
}
