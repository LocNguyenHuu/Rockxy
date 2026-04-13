import Foundation
@testable import Rockxy
import Testing

// MARK: - ScriptQuotaTests

struct ScriptQuotaTests {
    @Test("ScriptPolicyGate reads limit from AppPolicy")
    @MainActor
    func gateLimitFromPolicy() {
        let gate = ScriptPolicyGate(policy: TinyScriptPolicy())
        #expect(gate.policy.maxEnabledScripts == 2)
    }

    @Test("Default gate uses DefaultAppPolicy limit of 10")
    @MainActor
    func defaultGateLimit() {
        let gate = ScriptPolicyGate()
        #expect(gate.policy.maxEnabledScripts == 10)
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

    @Test("enablePlugin throws for missing plugin ID")
    func enablePluginMissingThrows() async {
        let manager = ScriptPluginManager()
        do {
            try await manager.enablePlugin(id: "nonexistent")
            Issue.record("Expected ScriptPluginError.pluginNotFound")
        } catch is ScriptPluginError {
            // Expected
        } catch {
            Issue.record("Expected ScriptPluginError, got \(error)")
        }
    }

    @Test("enablePluginIfAllowed throws for missing plugin even at zero limit")
    func enableIfAllowedMissingAtZeroLimit() async {
        let manager = ScriptPluginManager()
        // Plugin not found is checked before quota — throws, does not return false
        do {
            _ = try await manager.enablePluginIfAllowed(id: "nonexistent", maxEnabled: 0)
            Issue.record("Expected ScriptPluginError.pluginNotFound")
        } catch is ScriptPluginError {
            // Expected — plugin not found checked first
        } catch {
            Issue.record("Expected ScriptPluginError, got \(error)")
        }
    }

    @Test("Concurrent enables against shared manager are serialized by actor")
    func concurrentEnablesAreSerialized() async {
        let manager = ScriptPluginManager()
        // With no plugins loaded, all enables will throw pluginNotFound.
        // The key test here is that the actor serializes calls correctly
        // without crashing or data corruption.
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
            // All should return false (either quota or plugin-not-found)
            #expect(results.allSatisfy { !$0 })
        }
    }

    @Test("ScriptPolicyGate.configure only applies first call")
    @MainActor
    func gateConfigureOnce() {
        ScriptPolicyGate.resetForTesting(policy: TinyScriptPolicy())
        #expect(ScriptPolicyGate.shared.policy.maxEnabledScripts == 2)

        ScriptPolicyGate.configure(policy: DefaultAppPolicy())
        #expect(ScriptPolicyGate.shared.policy.maxEnabledScripts == 2)

        ScriptPolicyGate.resetForTesting()
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
