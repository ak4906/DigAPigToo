//
//  DeckManager.swift
//  DigAPigToo
//
//  User-created custom flashcard decks. A deck is just a named list of structure
//  names; studying a deck reuses the same FlashcardManager SRS engine as category
//  study — a deck only changes WHICH cards are chosen, not how they're scheduled.
//  Keyed by structure name (stable, consistent with FlashcardManager/StatsManager).
//
//  PERSISTENCE: local (UserDefaults + Codable), isolated behind save()/load() so it
//  can move to SwiftData+CloudKit later alongside the flashcard schedules.
//

import Foundation
import Combine

@MainActor
class DeckManager: ObservableObject {
    static let shared = DeckManager()

    struct Deck: Identifiable, Codable, Hashable {
        var id: UUID = UUID()
        var name: String
        var structureNames: [String] = []
        var createdAt: Date = Date()

        var cardCount: Int { structureNames.count }
    }

    @Published private(set) var decks: [Deck] = []

    private let udKey = "DigAPigToo_CustomDecks_v1"
    private let udModKey = "DigAPigToo_CustomDecks_modifiedAt"
    private init() {
        load()
        mergeFromCloud()
        CloudSync.observe { [weak self] in
            Task { @MainActor in self?.mergeFromCloud() }
        }
    }

    // MARK: - Deck CRUD

    @discardableResult
    func createDeck(name: String) -> Deck {
        let deck = Deck(name: trimmedUniqueName(name))
        decks.append(deck)
        save()
        return deck
    }

    func renameDeck(_ id: UUID, to newName: String) {
        guard let idx = decks.firstIndex(where: { $0.id == id }) else { return }
        decks[idx].name = trimmedUniqueName(newName, excluding: id)
        save()
    }

    func deleteDeck(_ id: UUID) {
        decks.removeAll { $0.id == id }
        save()
    }

    func deck(_ id: UUID) -> Deck? { decks.first { $0.id == id } }

    // MARK: - Membership

    func contains(_ structureName: String, in deckID: UUID) -> Bool {
        deck(deckID)?.structureNames.contains(structureName) ?? false
    }

    /// Decks this structure currently belongs to.
    func decks(containing structureName: String) -> [Deck] {
        decks.filter { $0.structureNames.contains(structureName) }
    }

    func add(_ structureName: String, to deckID: UUID) {
        guard let idx = decks.firstIndex(where: { $0.id == deckID }) else { return }
        guard !decks[idx].structureNames.contains(structureName) else { return }
        decks[idx].structureNames.append(structureName)
        save()
    }

    func remove(_ structureName: String, from deckID: UUID) {
        guard let idx = decks.firstIndex(where: { $0.id == deckID }) else { return }
        decks[idx].structureNames.removeAll { $0 == structureName }
        save()
    }

    /// Toggle a structure's membership in a deck; returns the new membership state.
    @discardableResult
    func toggle(_ structureName: String, in deckID: UUID) -> Bool {
        if contains(structureName, in: deckID) {
            remove(structureName, from: deckID)
            return false
        } else {
            add(structureName, to: deckID)
            return true
        }
    }

    /// Add several structures at once (e.g. a whole category into a deck).
    func add(_ structureNames: [String], to deckID: UUID) {
        guard let idx = decks.firstIndex(where: { $0.id == deckID }) else { return }
        for name in structureNames where !decks[idx].structureNames.contains(name) {
            decks[idx].structureNames.append(name)
        }
        save()
    }

    // MARK: - Helpers

    /// Ensures a non-empty, unique deck name (appends a number on collision).
    private func trimmedUniqueName(_ raw: String, excluding: UUID? = nil) -> String {
        var base = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if base.isEmpty { base = "New Deck" }
        let existing = Set(decks.filter { $0.id != excluding }.map { $0.name.lowercased() })
        guard existing.contains(base.lowercased()) else { return base }
        var n = 2
        while existing.contains("\(base) \(n)".lowercased()) { n += 1 }
        return "\(base) \(n)"
    }

    // MARK: - Persistence (local UserDefaults + iCloud key-value mirror)

    private func save() {
        guard let data = try? JSONEncoder().encode(decks) else { return }
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(data, forKey: udKey)
        UserDefaults.standard.set(now, forKey: udModKey)
        CloudSync.set(data, forKey: udKey)
        CloudSync.set(now, forKey: udModKey)
        CloudSync.flush()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([Deck].self, from: data) else { return }
        decks = decoded
    }

    /// Adopt the iCloud copy when it is newer than ours. Decks use WHOLE-blob
    /// last-writer-wins (by modified timestamp) rather than a per-item union so
    /// that deck DELETIONS propagate instead of being resurrected. Adopts the
    /// cloud timestamp locally (no re-push) so both devices converge.
    private func mergeFromCloud() {
        let cloudMod = CloudSync.double(forKey: udModKey)
        guard cloudMod > 0,
              let data = CloudSync.data(forKey: udKey),
              let cloudDecks = try? JSONDecoder().decode([Deck].self, from: data) else { return }
        let localMod = UserDefaults.standard.double(forKey: udModKey)
        // First time this device joins the cloud (localMod == 0) while it already has
        // local decks: UNION by id so neither device's pre-existing decks are lost.
        // save() pushes the union up and stamps localMod, so the other device adopts it.
        if localMod == 0 && !decks.isEmpty {
            let localIds = Set(decks.map { $0.id })
            decks.append(contentsOf: cloudDecks.filter { !localIds.contains($0.id) })
            save()
            return
        }
        // Steady state: whole-blob last-writer-wins, so edits AND deletions propagate.
        guard cloudMod > localMod else { return }
        decks = cloudDecks
        UserDefaults.standard.set(data, forKey: udKey)
        UserDefaults.standard.set(cloudMod, forKey: udModKey)
    }
}
