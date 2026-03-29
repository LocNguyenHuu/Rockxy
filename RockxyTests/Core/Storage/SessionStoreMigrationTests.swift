import Foundation
@testable import Rockxy
import Testing

// Regression tests for `SessionStoreMigration` in the core storage layer.

struct SessionStoreMigrationTests {
    // MARK: Internal

    @Test("Fresh database migrates to latest schema version")
    func freshDatabaseMigratesToLatest() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try SessionStore(directory: dir)
        let version = try await store.schemaVersion()

        #expect(version >= 1)
    }

    @Test("Second initialization skips migration")
    func secondInitSkipsMigration() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store1 = try SessionStore(directory: dir)
        let v1 = try await store1.schemaVersion()

        let store2 = try SessionStore(directory: dir)
        let v2 = try await store2.schemaVersion()

        #expect(v1 == v2)
    }

    @Test("Schema version persists across instances")
    func schemaVersionPersists() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        _ = try SessionStore(directory: dir)
        let store = try SessionStore(directory: dir)
        let version = try await store.schemaVersion()

        #expect(version >= 1)
    }

    @Test("Save and load transaction after migration")
    func saveLoadAfterMigration() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try SessionStore(directory: dir)
        let transaction = TestFixtures.makeTransaction()
        transaction.isPinned = true
        transaction.comment = "test comment"

        try await store.saveTransaction(transaction)
        let loaded = try await store.loadTransactions(limit: 10)

        #expect(loaded.count == 1)
        #expect(loaded[0].isPinned == true)
        #expect(loaded[0].comment == "test comment")
    }

    @Test("Migrated columns have correct defaults")
    func migratedColumnDefaults() async throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = try SessionStore(directory: dir)
        let transaction = TestFixtures.makeTransaction()

        try await store.saveTransaction(transaction)
        let loaded = try await store.loadTransactions(limit: 1)

        #expect(loaded.count == 1)
        #expect(loaded[0].isPinned == false)
        #expect(loaded[0].isSaved == false)
        #expect(loaded[0].comment == nil)
        #expect(loaded[0].highlightColor == nil)
        #expect(loaded[0].clientApp == nil)
    }

    // MARK: Private

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RockxyTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
