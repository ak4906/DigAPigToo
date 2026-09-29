//
//  CloudSync.swift
//  DigAPigToo
//
//  Serverless cross-device sync of small learning-progress blobs via iCloud's
//  key-value store (NSUbiquitousKeyValueStore). Apple hosts the per-user store,
//  so there is NO backend and no CloudKit schema — this simply mirrors the same
//  Codable→JSON blobs the managers already keep in UserDefaults.
//
//  Degrades gracefully: if the iCloud "Key-value storage" capability is absent,
//  or the user isn't signed into iCloud, reads return nil / 0 and writes are
//  no-ops, so every manager keeps working from its local UserDefaults copy.
//
//  REQUIRES (one-time, in Xcode): target → Signing & Capabilities → + Capability
//  → iCloud → check "Key-value storage". No CloudKit container is needed for KVS.
//

import Foundation

enum CloudSync {
    /// Computed (not a stored global) so there is no shared non-Sendable state to
    /// trip strict-concurrency checking; `.default` is always the same singleton.
    static var store: NSUbiquitousKeyValueStore { .default }

    // MARK: - Typed accessors
    static func data(forKey key: String) -> Data? { store.data(forKey: key) }

    static func set(_ data: Data?, forKey key: String) {
        if let data { store.set(data, forKey: key) } else { store.removeObject(forKey: key) }
    }

    static func double(forKey key: String) -> Double { store.double(forKey: key) }
    static func set(_ value: Double, forKey key: String) { store.set(value, forKey: key) }

    static func integer(forKey key: String) -> Int { Int(store.longLong(forKey: key)) }
    static func set(_ value: Int, forKey key: String) { store.set(Int64(value), forKey: key) }

    static func remove(forKey key: String) { store.removeObject(forKey: key) }

    /// Best-effort push of pending local writes toward iCloud. Returns false when
    /// the store is unavailable (e.g. capability off / not signed in).
    @discardableResult
    static func flush() -> Bool { store.synchronize() }

    /// Pull the latest values now, and call `onChange` on the main queue whenever
    /// ANOTHER device updates the store. Call once per manager from its init.
    static func observe(_ onChange: @escaping @Sendable () -> Void) {
        // Singletons live for the app's lifetime, so the observer is never removed.
        _ = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store,
            queue: .main
        ) { _ in onChange() }
        _ = store.synchronize()
    }
}
