import Foundation
@testable import Rockxy
import Testing

// Regression tests for `BypassProxyManager` in the core proxy engine layer.

// MARK: - BypassProxyManagerTests

/// Tests for BypassProxyManager using isolated instances with temp storage
/// to avoid shared state conflicts across parallel test runner processes.
@MainActor
struct BypassProxyManagerTests {
    // MARK: Internal

    // MARK: - State Management

    @Test("addDomain adds a new domain")
    func addDomain() {
        let manager = makeManager()
        manager.addDomain("localhost")
        #expect(manager.domains.count == 1)
        #expect(manager.domains.first?.domain == "localhost")
    }

    @Test("addDomain trims whitespace")
    func addDomainTrimsWhitespace() {
        let manager = makeManager()
        manager.addDomain("  localhost  ")
        #expect(manager.domains.first?.domain == "localhost")
    }

    @Test("addDomain lowercases input")
    func addDomainLowercases() {
        let manager = makeManager()
        manager.addDomain("LocalHost")
        #expect(manager.domains.first?.domain == "localhost")
    }

    @Test("addDomain rejects duplicates")
    func addDomainRejectsDuplicate() {
        let manager = makeManager()
        manager.addDomain("localhost")
        manager.addDomain("localhost")
        #expect(manager.domains.count == 1)
    }

    @Test("addDomain rejects empty string")
    func addDomainRejectsEmpty() {
        let manager = makeManager()
        manager.addDomain("")
        manager.addDomain("   ")
        #expect(manager.domains.isEmpty)
    }

    @Test("removeDomain removes by ID")
    func removeDomainByID() {
        let manager = makeManager()
        manager.addDomain("localhost")
        let id = manager.domains[0].id

        manager.removeDomain(id: id)
        #expect(manager.domains.isEmpty)
    }

    @Test("removeDomains batch removes by IDs")
    func batchRemove() {
        let manager = makeManager()
        manager.addDomain("a.local")
        manager.addDomain("b.local")
        manager.addDomain("c.local")

        let idsToRemove = Set(manager.domains.prefix(2).map(\.id))
        manager.removeDomains(ids: idsToRemove)
        #expect(manager.domains.count == 1)
        #expect(manager.domains[0].domain == "c.local")
    }

    @Test("toggleDomain toggles isEnabled")
    func toggleDomain() {
        let manager = makeManager()
        manager.addDomain("localhost")
        let id = manager.domains[0].id
        #expect(manager.domains[0].isEnabled == true)

        manager.toggleDomain(id: id)
        #expect(manager.domains[0].isEnabled == false)

        manager.toggleDomain(id: id)
        #expect(manager.domains[0].isEnabled == true)
    }

    // MARK: - isHostBypassed

    @Test("isHostBypassed returns true for exact match")
    func isHostBypassedExact() {
        let manager = makeManager()
        manager.addDomain("localhost")
        #expect(manager.isHostBypassed("localhost"))
    }

    @Test("isHostBypassed returns true for wildcard match")
    func isHostBypassedWildcard() {
        let manager = makeManager()
        manager.addDomain("*.local")
        #expect(manager.isHostBypassed("myhost.local"))
    }

    @Test("isHostBypassed returns false for disabled domain")
    func isHostBypassedDisabled() {
        let manager = makeManager()
        manager.addDomain("localhost")
        manager.toggleDomain(id: manager.domains[0].id)
        #expect(!manager.isHostBypassed("localhost"))
    }

    @Test("isHostBypassed returns false for non-matching host")
    func isHostBypassedNoMatch() {
        let manager = makeManager()
        manager.addDomain("localhost")
        #expect(!manager.isHostBypassed("example.com"))
    }

    // MARK: - enabledDomainStrings

    @Test("enabledDomainStrings returns only enabled domains")
    func enabledDomainStrings() {
        let manager = makeManager()
        manager.addDomain("enabled.local")
        manager.addDomain("disabled.local")
        manager.toggleDomain(id: manager.domains[1].id)

        let strings = manager.enabledDomainStrings()
        #expect(strings == ["enabled.local"])
    }

    // MARK: - Presets

    @Test("addPresets adds expected default domains")
    func addPresets() {
        let manager = makeManager()
        manager.addPresets()

        let expected = ["localhost", "*.local", "127.0.0.1", "::1", "169.254.*"]
        let domainStrings = manager.domains.map(\.domain)
        for preset in expected {
            #expect(domainStrings.contains(preset), "Missing preset: \(preset)")
        }
        #expect(manager.domains.count == expected.count)
    }

    @Test("addPresets does not create duplicates")
    func addPresetsDeduplicates() {
        let manager = makeManager()
        manager.addDomain("localhost")
        manager.addPresets()

        let localhostCount = manager.domains.filter { $0.domain == "localhost" }.count
        #expect(localhostCount == 1)
    }

    // MARK: - Export/Import

    @Test("Export and import roundtrip preserves domains")
    func exportImportRoundtrip() throws {
        let manager = makeManager()
        manager.addDomain("a.local")
        manager.addDomain("b.local")

        guard let data = manager.exportDomains() else {
            #expect(Bool(false), "Export returned nil")
            return
        }

        let manager2 = makeManager()
        try manager2.importDomains(from: data)
        #expect(manager2.domains.count == 2)
        #expect(manager2.domains.map(\.domain).contains("a.local"))
        #expect(manager2.domains.map(\.domain).contains("b.local"))
    }

    // MARK: - Persistence

    @Test("Save and load roundtrip preserves domains")
    func persistenceRoundtrip() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rockxy-persist-\(UUID().uuidString).json")

        let manager1 = BypassProxyManager(storageURL: url)
        manager1.addDomain("persisted.local")
        manager1.addDomain("*.test")

        let manager2 = BypassProxyManager(storageURL: url)
        #expect(manager2.domains.count == 2)
        #expect(manager2.domains.map(\.domain).contains("persisted.local"))
        #expect(manager2.domains.map(\.domain).contains("*.test"))

        // Cleanup
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: Private

    /// Creates an isolated manager instance with a unique temp storage file.
    private func makeManager() -> BypassProxyManager {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rockxy-test-\(UUID().uuidString).json")
        return BypassProxyManager(storageURL: url)
    }
}
