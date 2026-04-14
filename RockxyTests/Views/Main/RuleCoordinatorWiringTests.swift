import Foundation
@testable import Rockxy
import Testing

// MARK: - RuleCoordinatorWiringTests

@Suite(.serialized)
@MainActor
struct RuleCoordinatorWiringTests {
    @Test("addRule success fires notification and sets no toast")
    func addRuleSuccess() async {
        await RuleTestLock.shared.acquire()
        let savedGate = RulePolicyGate.shared
        let engineSnapshot = await RuleEngine.shared.allRules
        RulePolicyGate.shared = RulePolicyGate(policy: LargePolicy())
        await RuleEngine.shared.replaceAll([])

        let coordinator = MainContentCoordinator()
        let rule = TestFixtures.makeRule(name: "WiringAdd", action: .block(statusCode: 403))
        coordinator.addRule(rule)

        for _ in 0 ..< 500 {
            let rules = await RuleEngine.shared.allRules
            if rules.contains(where: { $0.id == rule.id }) {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(coordinator.activeToast == nil)
        let engineRules = await RuleEngine.shared.allRules
        #expect(engineRules.contains { $0.id == rule.id })

        RulePolicyGate.shared = savedGate
        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }

    @Test("addRule at quota sets error toast")
    func addRuleAtQuota() async {
        await RuleTestLock.shared.acquire()
        let savedGate = RulePolicyGate.shared
        let engineSnapshot = await RuleEngine.shared.allRules
        await RuleEngine.shared.replaceAll([])
        await RuleEngine.shared.addRule(
            TestFixtures.makeRule(name: "Existing", action: .block(statusCode: 403))
        )
        RulePolicyGate.shared = RulePolicyGate(policy: TinyRulePolicy())

        let coordinator = MainContentCoordinator()
        let overflow = TestFixtures.makeRule(name: "Overflow", action: .block(statusCode: 403))
        coordinator.addRule(overflow)

        for _ in 0 ..< 500 {
            if coordinator.activeToast != nil {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(coordinator.activeToast != nil)
        #expect(coordinator.activeToast?.style == .error)
        let engineRules = await RuleEngine.shared.allRules
        #expect(!engineRules.contains { $0.id == overflow.id })

        RulePolicyGate.shared = savedGate
        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }

    @Test("toggleRule disable fires notification and sets no toast")
    func toggleRuleDisable() async {
        await RuleTestLock.shared.acquire()
        let savedGate = RulePolicyGate.shared
        let engineSnapshot = await RuleEngine.shared.allRules
        RulePolicyGate.shared = RulePolicyGate(policy: LargePolicy())
        await RuleEngine.shared.replaceAll([])
        let rule = TestFixtures.makeRule(name: "Toggle", action: .throttle(delayMs: 100))
        await RuleEngine.shared.addRule(rule)

        let coordinator = MainContentCoordinator()
        coordinator.toggleRule(id: rule.id)

        for _ in 0 ..< 500 {
            let rules = await RuleEngine.shared.allRules
            if rules.first(where: { $0.id == rule.id })?.isEnabled == false {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(coordinator.activeToast == nil)
        let engineRules = await RuleEngine.shared.allRules
        #expect(engineRules.first { $0.id == rule.id }?.isEnabled == false)

        RulePolicyGate.shared = savedGate
        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }

    @Test("toggleRule enable at quota sets error toast")
    func toggleRuleEnableAtQuota() async {
        await RuleTestLock.shared.acquire()
        let savedGate = RulePolicyGate.shared
        let engineSnapshot = await RuleEngine.shared.allRules
        await RuleEngine.shared.replaceAll([])
        let active = TestFixtures.makeRule(name: "Active", action: .throttle(delayMs: 100))
        await RuleEngine.shared.addRule(active)
        var disabled = TestFixtures.makeRule(name: "Disabled", action: .throttle(delayMs: 200))
        disabled.isEnabled = false
        await RuleEngine.shared.addRule(disabled)
        RulePolicyGate.shared = RulePolicyGate(policy: TinyRulePolicy())

        let coordinator = MainContentCoordinator()
        coordinator.toggleRule(id: disabled.id)

        for _ in 0 ..< 500 {
            if coordinator.activeToast != nil {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(coordinator.activeToast != nil)
        #expect(coordinator.activeToast?.style == .error)
        let engineRules = await RuleEngine.shared.allRules
        #expect(engineRules.first { $0.id == disabled.id }?.isEnabled == false)

        RulePolicyGate.shared = savedGate
        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }
}

// MARK: - TinyRulePolicy

private struct TinyRulePolicy: AppPolicy {
    let maxWorkspaceTabs = 8
    let maxDomainFavorites = 5
    let maxActiveRulesPerTool = 1
    let maxEnabledScripts = 10
    let maxLiveHistoryEntries = 1_000
}

// MARK: - LargePolicy

private struct LargePolicy: AppPolicy {
    let maxWorkspaceTabs = 8
    let maxDomainFavorites = 5
    let maxActiveRulesPerTool = 100
    let maxEnabledScripts = 10
    let maxLiveHistoryEntries = 1_000
}
