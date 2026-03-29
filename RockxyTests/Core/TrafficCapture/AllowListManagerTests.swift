import Foundation
@testable import Rockxy
import Testing

/// AllowListManager tests validate the matching and filtering logic at the manager boundary.
/// The actual capture-level filtering in MainContentCoordinator.processBatch delegates to
/// AllowListManager.shared.isHostAllowed() — the same method tested here. Direct processBatch
/// testing requires instantiating the full @MainActor coordinator + proxy pipeline, which is
/// impractical for unit tests. The manager tests prove the filtering contract that processBatch
/// relies on: when isActive is true, only hosts matching enabled entries pass through.
struct AllowListManagerTests {
    // MARK: - Domain Matching

    @Test("Exact domain match")
    @MainActor
    func exactMatch() {
        let entry = AllowListEntry(domain: "httpbin.org")
        #expect(entry.matches("httpbin.org"))
        #expect(!entry.matches("api.httpbin.org"))
        #expect(!entry.matches("httpbin.org.evil.com"))
    }

    @Test("Wildcard domain match")
    @MainActor
    func wildcardMatch() {
        let entry = AllowListEntry(domain: "*.example.com")
        #expect(entry.matches("api.example.com"))
        #expect(entry.matches("sub.api.example.com"))
        #expect(!entry.matches("example.com"))
        #expect(!entry.matches("notexample.com"))
    }

    @Test("Case-insensitive matching")
    @MainActor
    func caseInsensitive() {
        let entry = AllowListEntry(domain: "API.Example.COM")
        #expect(entry.matches("api.example.com"))
        #expect(entry.matches("API.EXAMPLE.COM"))

        let wildcard = AllowListEntry(domain: "*.Example.COM")
        #expect(wildcard.matches("sub.example.com"))
        #expect(wildcard.matches("SUB.EXAMPLE.COM"))
    }

    // MARK: - isActive Toggle

    @Test("When inactive, isHostAllowed always returns true")
    @MainActor
    func inactiveAllowsAll() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)
        manager.isActive = false
        manager.addEntry("api.example.com")

        #expect(manager.isHostAllowed("api.example.com"))
        #expect(manager.isHostAllowed("totally.different.host"))
        #expect(manager.isHostAllowed("anything.goes"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("When active with matching host, returns true")
    @MainActor
    func activeMatchingHost() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)
        manager.addEntry("api.example.com")
        manager.addEntry("*.stripe.com")
        manager.isActive = true

        #expect(manager.isHostAllowed("api.example.com"))
        #expect(manager.isHostAllowed("checkout.stripe.com"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("When active with non-matching host, returns false")
    @MainActor
    func activeNonMatchingHost() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)
        manager.addEntry("api.example.com")
        manager.isActive = true

        #expect(!manager.isHostAllowed("cdn.other.com"))
        #expect(!manager.isHostAllowed("totally.different.host"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Add / Remove / Toggle

    @Test("Add and remove entries")
    @MainActor
    func addRemove() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)

        manager.addEntry("api.example.com")
        #expect(manager.entries.count == 1)

        manager.addEntry("*.stripe.com")
        #expect(manager.entries.count == 2)

        // Deduplicate
        manager.addEntry("api.example.com")
        #expect(manager.entries.count == 2)

        let firstID = manager.entries[0].id
        manager.removeEntry(id: firstID)
        #expect(manager.entries.count == 1)
        #expect(manager.entries[0].domain == "*.stripe.com")

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Toggle entry enabled state")
    @MainActor
    func toggleEntry() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)

        manager.addEntry("api.example.com")
        #expect(manager.entries[0].isEnabled)

        manager.toggleEntry(id: manager.entries[0].id)
        #expect(!manager.entries[0].isEnabled)

        // Disabled entry should not match when active
        manager.isActive = true
        #expect(!manager.isHostAllowed("api.example.com"))

        manager.toggleEntry(id: manager.entries[0].id)
        #expect(manager.isHostAllowed("api.example.com"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Persistence Round-Trip

    @Test("Persistence round-trip saves and restores state")
    @MainActor
    func persistenceRoundTrip() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")

        // Write
        let writer = AllowListManager(storageURL: tempURL)
        writer.addEntry("api.example.com")
        writer.addEntry("*.stripe.com")
        writer.isActive = true

        // Read
        let reader = AllowListManager(storageURL: tempURL)
        #expect(reader.isActive)
        #expect(reader.entries.count == 2)
        #expect(reader.entries[0].domain == "api.example.com")
        #expect(reader.entries[1].domain == "*.stripe.com")
        #expect(reader.isHostAllowed("api.example.com"))
        #expect(!reader.isHostAllowed("cdn.other.com"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Disabled entry is excluded from matching")
    @MainActor
    func disabledEntryExcluded() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)

        manager.addEntry("api.example.com")
        manager.addEntry("cdn.example.com")
        manager.isActive = true

        // Disable the second entry
        manager.toggleEntry(id: manager.entries[1].id)

        #expect(manager.isHostAllowed("api.example.com"))
        #expect(!manager.isHostAllowed("cdn.example.com"))

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Batch Filtering (Processing Path)

    @Test("Mixed batch filters correctly when active")
    @MainActor
    func mixedBatchFiltering() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)
        manager.addEntry("api.example.com")
        manager.isActive = true

        let allowed = TestFixtures.makeTransaction(url: "https://api.example.com/data")
        let blocked = TestFixtures.makeTransaction(url: "https://other.com/data")

        let batch = [allowed, blocked]
        let filtered = batch.filter { manager.isHostAllowed($0.request.host) }

        #expect(filtered.count == 1)
        #expect(filtered[0].request.host == "api.example.com")

        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Batch passes through when inactive")
    @MainActor
    func batchPassesThroughWhenInactive() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)
        manager.addEntry("api.example.com")
        manager.isActive = false

        let t1 = TestFixtures.makeTransaction(url: "https://api.example.com/data")
        let t2 = TestFixtures.makeTransaction(url: "https://other.com/data")

        let batch = [t1, t2]
        let filtered = batch.filter { manager.isHostAllowed($0.request.host) }

        #expect(filtered.count == 2)

        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - Bulk Operations

    @Test("Remove multiple entries by IDs")
    @MainActor
    func removeMultiple() {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        let manager = AllowListManager(storageURL: tempURL)

        manager.addEntry("a.com")
        manager.addEntry("b.com")
        manager.addEntry("c.com")
        #expect(manager.entries.count == 3)

        let idsToRemove: Set<UUID> = [manager.entries[0].id, manager.entries[2].id]
        manager.removeEntries(ids: idsToRemove)
        #expect(manager.entries.count == 1)
        #expect(manager.entries[0].domain == "b.com")

        try? FileManager.default.removeItem(at: tempURL)
    }
}
