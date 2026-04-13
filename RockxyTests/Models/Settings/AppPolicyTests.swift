@testable import Rockxy
import Testing

// MARK: - AppPolicyTests

struct AppPolicyTests {
    @Test("DefaultAppPolicy has expected baseline values")
    func defaultValues() {
        let policy = DefaultAppPolicy()
        #expect(policy.maxWorkspaceTabs == 8)
        #expect(policy.maxDomainFavorites == 5)
        #expect(policy.maxActiveRulesPerTool == 10)
        #expect(policy.maxEnabledScripts == 10)
        #expect(policy.maxLiveHistoryEntries == 1_000)
    }

    @Test("MainContentCoordinator uses DefaultAppPolicy by default")
    @MainActor
    func coordinatorDefaultPolicy() {
        let coordinator = MainContentCoordinator()
        #expect(coordinator.policy.maxWorkspaceTabs == 8)
        #expect(coordinator.policy.maxDomainFavorites == 5)
    }

    @Test("MainContentCoordinator accepts custom policy")
    @MainActor
    func coordinatorCustomPolicy() {
        let custom = TestPolicy(maxWorkspaceTabs: 3, maxDomainFavorites: 2)
        let coordinator = MainContentCoordinator(policy: custom)
        #expect(coordinator.policy.maxWorkspaceTabs == 3)
        #expect(coordinator.policy.maxDomainFavorites == 2)
    }
}

// MARK: - TestPolicy

private struct TestPolicy: AppPolicy {
    var maxWorkspaceTabs = 8
    var maxDomainFavorites = 5
    var maxActiveRulesPerTool = 10
    var maxEnabledScripts = 10
    var maxLiveHistoryEntries = 1_000
}
