import Foundation
@testable import Rockxy
import Testing

// MARK: - RuleQuotaTests

/// Tests ``RulePolicyGate`` per-category active rule limits.
///
/// Counts pre-existing rules in the shared ``RuleEngine`` before seeding,
/// so tests are immune to cross-suite singleton pollution from parallel
/// test processes.
@Suite(.serialized)
@MainActor
struct RuleQuotaTests {
    // MARK: Internal

    @Test("Adding rule at quota is rejected")
    func addAtQuotaRejected() async {
        let baseline = await activeCount(for: "throttle")
        let gate = RulePolicyGate(policy: PolicyWithLimit(baseline + 2))

        let ids = await seedThrottleRules(count: 2)

        let rejected = await gate.addRule(makeThrottle())
        #expect(!rejected)

        await removeRules(ids)
    }

    @Test("Toggle-enable at quota is rejected")
    func toggleEnableAtQuota() async {
        let baseline = await activeCount(for: "throttle")
        let gate = RulePolicyGate(policy: PolicyWithLimit(baseline + 2))

        let ids = await seedThrottleRules(count: 2)

        var disabled = makeThrottle()
        disabled.isEnabled = false
        await RuleEngine.shared.addRule(disabled)

        let toggled = await gate.toggleRule(id: disabled.id)
        #expect(!toggled)

        await RuleEngine.shared.removeRule(id: disabled.id)
        await removeRules(ids)
    }

    @Test("Disabled rules do not count toward quota")
    func disabledRulesExcluded() async {
        let baseline = await activeCount(for: "throttle")
        let ids = await seedThrottleRules(count: 2)

        var disabled = makeThrottle()
        disabled.isEnabled = false
        await RuleEngine.shared.addRule(disabled)

        let allRules = await RuleEngine.shared.allRules
        let activeThrottle = allRules.filter { $0.isEnabled && $0.action.toolCategory == "throttle" }.count
        #expect(activeThrottle == baseline + 2)

        await RuleEngine.shared.removeRule(id: disabled.id)
        await removeRules(ids)
    }

    @Test("Cross-category independence")
    func crossCategory() async {
        let ids = await seedThrottleRules(count: 2)

        let allRules = await RuleEngine.shared.allRules
        let throttleCount = allRules.filter { $0.isEnabled && $0.action.toolCategory == "throttle" }.count
        #expect(throttleCount >= 2)

        await removeRules(ids)
    }

    @Test("toolCategory mapping")
    func toolCategoryMapping() {
        #expect(RuleAction.block(statusCode: 403).toolCategory == "block")
        #expect(RuleAction.breakpoint().toolCategory == "breakpoint")
        #expect(RuleAction.mapLocal(filePath: "").toolCategory == "mapLocal")
        #expect(RuleAction.mapRemote(configuration: .init()).toolCategory == "mapRemote")
        #expect(RuleAction.modifyHeader(operations: []).toolCategory == "modifyHeader")
        #expect(RuleAction.throttle(delayMs: 100).toolCategory == "throttle")
        #expect(RuleAction.networkCondition(preset: .custom, delayMs: 0).toolCategory == "networkCondition")
    }

    // MARK: - Bulk Replace Quota

    @Test("capEnabledPerCategory disables excess rules per category")
    func bulkReplaceCapsExcess() {
        let rules: [ProxyRule] = (0 ..< 5).map { _ in
            ProxyRule(
                name: "Block",
                matchCondition: RuleMatchCondition(urlPattern: ".*"),
                action: .block(statusCode: 403)
            )
        }
        let capped = RulePolicyGate.capEnabledPerCategory(rules, limit: 3)
        let enabledCount = capped.filter(\.isEnabled).count
        #expect(enabledCount == 3)
        let disabledCount = capped.filter { !$0.isEnabled }.count
        #expect(disabledCount == 2)
    }

    @Test("capEnabledPerCategory respects cross-category limits independently")
    func bulkReplaceCrossCategoryIndependence() {
        var rules: [ProxyRule] = (0 ..< 3).map { _ in
            ProxyRule(
                name: "Block",
                matchCondition: RuleMatchCondition(urlPattern: ".*"),
                action: .block(statusCode: 403)
            )
        }
        rules += (0 ..< 3).map { _ in
            ProxyRule(
                name: "Throttle",
                matchCondition: RuleMatchCondition(urlPattern: ".*"),
                action: .throttle(delayMs: 100)
            )
        }
        let capped = RulePolicyGate.capEnabledPerCategory(rules, limit: 2)
        let enabledBlocks = capped.filter { $0.isEnabled && $0.action.toolCategory == "block" }.count
        let enabledThrottles = capped.filter { $0.isEnabled && $0.action.toolCategory == "throttle" }.count
        #expect(enabledBlocks == 2)
        #expect(enabledThrottles == 2)
    }

    // MARK: - Gate Configure-Once

    @Test("RulePolicyGate.configure only applies first call")
    func gateConfigureOnce() {
        RulePolicyGate.resetForTesting(policy: PolicyWithLimit(5))
        #expect(RulePolicyGate.shared.policy.maxActiveRulesPerTool == 5)

        // Second configure should be ignored
        RulePolicyGate.configure(policy: PolicyWithLimit(99))
        #expect(RulePolicyGate.shared.policy.maxActiveRulesPerTool == 5)

        // Cleanup
        RulePolicyGate.resetForTesting()
    }

    // MARK: Private

    // MARK: - Helpers

    private func activeCount(for category: String) async -> Int {
        let allRules = await RuleEngine.shared.allRules
        return allRules.filter { $0.isEnabled && $0.action.toolCategory == category }.count
    }

    private func makeThrottle() -> ProxyRule {
        ProxyRule(
            name: "QuotaTest",
            matchCondition: RuleMatchCondition(urlPattern: ".*quota-test-throttle.*"),
            action: .throttle(delayMs: 999)
        )
    }

    private func seedThrottleRules(count: Int) async -> [UUID] {
        var ids: [UUID] = []
        for _ in 0 ..< count {
            let rule = makeThrottle()
            await RuleEngine.shared.addRule(rule)
            ids.append(rule.id)
        }
        return ids
    }

    private func removeRules(_ ids: [UUID]) async {
        for id in ids {
            await RuleEngine.shared.removeRule(id: id)
        }
    }
}

// MARK: - PolicyWithLimit

/// Policy that sets the per-tool limit to a specific value (baseline + headroom).
private struct PolicyWithLimit: AppPolicy {
    // MARK: Lifecycle

    init(_ maxRules: Int) {
        maxActiveRulesPerTool = maxRules
    }

    // MARK: Internal

    let maxWorkspaceTabs = 8
    let maxDomainFavorites = 5
    let maxActiveRulesPerTool: Int
    let maxEnabledScripts = 10
    let maxLiveHistoryEntries = 1_000
}
