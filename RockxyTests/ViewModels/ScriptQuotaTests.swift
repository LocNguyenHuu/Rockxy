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
}

// MARK: - TinyScriptPolicy

private struct TinyScriptPolicy: AppPolicy {
    let maxWorkspaceTabs = 8
    let maxDomainFavorites = 5
    let maxActiveRulesPerTool = 10
    let maxEnabledScripts = 2
    let maxLiveHistoryEntries = 1_000
}
