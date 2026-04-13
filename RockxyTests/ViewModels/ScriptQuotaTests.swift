import Foundation
@testable import Rockxy
import Testing

// MARK: - ScriptQuotaTests

struct ScriptQuotaTests {
    // MARK: Internal

    @Test("ScriptPolicyGate reads limit from AppPolicy")
    @MainActor
    func gateLimitFromPolicy() {
        let gate = ScriptPolicyGate(policy: TinyScriptPolicy())
        #expect(gate.policy.maxEnabledScripts == 2)
    }

    @Test("ScriptQuotaError provides description")
    func quotaErrorDescription() {
        let error = ScriptQuotaError.limitReached(max: 5)
        #expect(error.localizedDescription.contains("5"))
    }

    @Test("ScriptPluginError.pluginNotFound provides description")
    func pluginNotFoundDescription() {
        let error = ScriptPluginError.pluginNotFound("test-id")
        #expect(error.localizedDescription.contains("test-id"))
    }

    // MARK: - Missing Plugin Errors

    @Test("enablePluginIfAllowed throws for missing plugin ID")
    func enableMissingPluginThrows() async {
        let manager = ScriptPluginManager()
        do {
            _ = try await manager.enablePluginIfAllowed(id: "nonexistent", maxEnabled: 10)
            Issue.record("Expected ScriptPluginError.pluginNotFound")
        } catch is ScriptPluginError {
            // Expected
        } catch {
            Issue.record("Expected ScriptPluginError, got \(error)")
        }
    }

    @Test("ScriptPolicyGate.enablePlugin propagates pluginNotFound")
    @MainActor
    func gatePropagatesPluginNotFound() async {
        let manager = ScriptPluginManager()
        let gate = ScriptPolicyGate(policy: DefaultAppPolicy())
        do {
            try await gate.enablePlugin(id: "ghost", using: manager)
            Issue.record("Expected error")
        } catch is ScriptPluginError {
            // Expected
        } catch is ScriptQuotaError {
            Issue.record("Should have thrown ScriptPluginError, not quota error")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Concurrent Enables

    @Test("Concurrent enables against shared manager are serialized by actor")
    func concurrentEnablesAreSerialized() async {
        let manager = ScriptPluginManager()
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    do {
                        return try await manager.enablePluginIfAllowed(id: "test", maxEnabled: 2)
                    } catch {
                        return false
                    }
                }
            }
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            #expect(results.allSatisfy { !$0 })
        }
    }

    // MARK: - Real Plugin Enable/Disable Path

    @Test("Enable and disable through shared manager round-trips correctly")
    func enableDisableRoundTrip() async throws {
        let id = "roundtrip-test-\(UUID().uuidString.prefix(8))"
        let pluginDir = try Self.createTempPlugin(id: id, enabled: false)
        defer { Self.cleanupPlugin(id: id, bundlePath: pluginDir) }

        let manager = ScriptPluginManager()
        await manager.loadAllPlugins()
        let initial = await manager.plugins
        #expect(initial.contains { $0.id == id })
        #expect(initial.first { $0.id == id }?.isEnabled == false)

        // Enable through the quota-checked path
        let accepted = try await manager.enablePluginIfAllowed(id: id, maxEnabled: 10)
        #expect(accepted)
        let afterEnable = await manager.plugins
        #expect(afterEnable.first { $0.id == id }?.isEnabled == true)

        // Disable
        await manager.disablePlugin(id: id)
        let afterDisable = await manager.plugins
        #expect(afterDisable.first { $0.id == id }?.isEnabled == false)
    }

    @Test("Both ViewModels observe shared manager enable/disable")
    @MainActor
    func sharedManagerObservation() async throws {
        let id = "shared-obs-\(UUID().uuidString.prefix(8))"
        let pluginDir = try Self.createTempPlugin(id: id, enabled: false)
        defer { Self.cleanupPlugin(id: id, bundlePath: pluginDir) }

        let manager = ScriptPluginManager()
        let settings = PluginSettingsViewModel(pluginManager: manager)
        let scripting = ScriptingViewModel(pluginManager: manager)

        await settings.loadPlugins()
        scripting.plugins = await manager.plugins

        #expect(settings.plugins.contains { $0.id == id })
        #expect(scripting.plugins.contains { $0.id == id })

        // Enable through gate
        let gate = ScriptPolicyGate(policy: DefaultAppPolicy())
        try await gate.enablePlugin(id: id, using: manager)

        // Both VMs refresh from the same manager and see the change
        settings.plugins = await manager.plugins
        scripting.plugins = await manager.plugins
        #expect(settings.plugins.first { $0.id == id }?.isEnabled == true)
        #expect(scripting.plugins.first { $0.id == id }?.isEnabled == true)
    }

    // MARK: - Stale Cross-Window Re-Enable

    @Test("Re-enabling an already-enabled plugin is a no-op success")
    func reEnableIsNoOp() async throws {
        let id = "reenable-\(UUID().uuidString.prefix(8))"
        let pluginDir = try Self.createTempPlugin(id: id, enabled: false)
        defer { Self.cleanupPlugin(id: id, bundlePath: pluginDir) }

        let manager = ScriptPluginManager()
        await manager.loadAllPlugins()

        // First window enables the plugin
        let first = try await manager.enablePluginIfAllowed(id: id, maxEnabled: 1)
        #expect(first)
        let afterFirst = await manager.plugins
        #expect(afterFirst.first { $0.id == id }?.isEnabled == true)
        #expect(afterFirst.first { $0.id == id }?.status == .active)

        // Second window has stale local state and issues enable again.
        // This must succeed as a no-op — no runtime reload, no quota rejection.
        let second = try await manager.enablePluginIfAllowed(id: id, maxEnabled: 1)
        #expect(second)

        // State remains stable
        let afterSecond = await manager.plugins
        #expect(afterSecond.first { $0.id == id }?.isEnabled == true)
        #expect(afterSecond.first { $0.id == id }?.status == .active)
    }

    // MARK: - Policy Injection

    @Test("Custom policy takes effect through .shared assignment")
    @MainActor
    func customPolicyInjectable() {
        let saved = ScriptPolicyGate.shared
        defer { ScriptPolicyGate.shared = saved }

        ScriptPolicyGate.shared = ScriptPolicyGate(policy: TinyScriptPolicy())
        #expect(ScriptPolicyGate.shared.policy.maxEnabledScripts == 2)

        ScriptPolicyGate.shared = ScriptPolicyGate(policy: DefaultAppPolicy())
        #expect(ScriptPolicyGate.shared.policy.maxEnabledScripts == 10)
    }

    @Test("Coordinator construction does not pollute shared script gate")
    @MainActor
    func coordinatorDoesNotPolluteScriptGate() {
        let saved = ScriptPolicyGate.shared
        defer { ScriptPolicyGate.shared = saved }

        ScriptPolicyGate.shared = ScriptPolicyGate(policy: TinyScriptPolicy())
        _ = MainContentCoordinator(policy: DefaultAppPolicy())
        #expect(ScriptPolicyGate.shared.policy.maxEnabledScripts == 2)
    }

    // MARK: Private

    // MARK: - Helpers

    /// Creates a minimal valid plugin on disk in the app's plugin directory.
    /// Returns the plugin bundle path. Caller is responsible for cleanup.
    private static func createTempPlugin(id: String, enabled: Bool) throws -> URL {
        let pluginsDir = RockxyIdentity.current.appSupportPath("Plugins")
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        let bundlePath = pluginsDir.appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: bundlePath, withIntermediateDirectories: true)

        let manifest = """
        {
            "id": "\(id)",
            "name": "Test Plugin \(id)",
            "version": "1.0.0",
            "author": { "name": "Test" },
            "description": "Test plugin",
            "types": ["script"],
            "entryPoints": { "script": "index.js" },
            "capabilities": []
        }
        """
        try manifest.write(to: bundlePath.appendingPathComponent("plugin.json"), atomically: true, encoding: .utf8)

        let script = "module.exports = {};"
        try script.write(to: bundlePath.appendingPathComponent("index.js"), atomically: true, encoding: .utf8)

        if enabled {
            UserDefaults.standard.set(true, forKey: RockxyIdentity.current.pluginEnabledKey(pluginID: id))
        } else {
            UserDefaults.standard.removeObject(forKey: RockxyIdentity.current.pluginEnabledKey(pluginID: id))
        }

        return bundlePath
    }

    private static func cleanupPlugin(id: String, bundlePath: URL) {
        try? FileManager.default.removeItem(at: bundlePath)
        UserDefaults.standard.removeObject(forKey: RockxyIdentity.current.pluginEnabledKey(pluginID: id))
    }
}

// MARK: - TinyScriptPolicy

private struct TinyScriptPolicy: AppPolicy {
    let maxWorkspaceTabs = 8
    let maxDomainFavorites = 5
    let maxActiveRulesPerTool = 10
    let maxEnabledScripts = 2
    let maxLiveHistoryEntries = 1_000
}
