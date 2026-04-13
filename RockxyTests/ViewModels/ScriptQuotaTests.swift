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

    @Test("enablePluginIfAllowed is atomic — rejects when at limit")
    func enableIfAllowedAtLimit() async {
        let manager = ScriptPluginManager()
        // No plugins loaded → enabledCount is 0, maxEnabled 0 → should reject
        let accepted = try? await manager.enablePluginIfAllowed(id: "nonexistent", maxEnabled: 0)
        #expect(accepted == false)
    }

    @Test("ScriptPolicyGate.configure only applies first call")
    @MainActor
    func gateConfigureOnce() {
        ScriptPolicyGate.resetForTesting(policy: TinyScriptPolicy())
        #expect(ScriptPolicyGate.shared.policy.maxEnabledScripts == 2)

        // Second configure should be ignored
        ScriptPolicyGate.configure(policy: DefaultAppPolicy())
        #expect(ScriptPolicyGate.shared.policy.maxEnabledScripts == 2)

        // Cleanup
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
