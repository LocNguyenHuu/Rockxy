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

    @Test("capEnabledPerCategory caps excess in changed category only")
    func bulkReplaceCapsChangedCategoryOnly() {
        // Baseline: 2 blocks enabled, 1 throttle enabled
        let baseline: [ProxyRule] = [
            makeNamedRule(name: "B1", action: .block(statusCode: 403), enabled: true),
            makeNamedRule(name: "B2", action: .block(statusCode: 403), enabled: true),
            makeNamedRule(name: "T1", action: .throttle(delayMs: 100), enabled: true),
        ]
        // Replacement: enable ALL 4 blocks, keep 1 throttle
        var replacement = baseline
        replacement.append(makeNamedRule(name: "B3", action: .block(statusCode: 403), enabled: true))
        replacement.append(makeNamedRule(name: "B4", action: .block(statusCode: 403), enabled: true))

        let capped = RulePolicyGate.capEnabledPerCategory(replacement, limit: 3, baseline: baseline)
        let enabledBlocks = capped.filter { $0.isEnabled && $0.action.toolCategory == "block" }.count
        let enabledThrottles = capped.filter { $0.isEnabled && $0.action.toolCategory == "throttle" }.count
        // Blocks capped at 3 (grew from 2 → 4, exceeds limit 3)
        #expect(enabledBlocks == 3)
        // Throttle untouched (was 1, still 1 — no growth beyond limit)
        #expect(enabledThrottles == 1)
    }

    @Test("capEnabledPerCategory does not touch categories within quota")
    func bulkReplacePreservesWithinQuota() {
        let baseline: [ProxyRule] = [
            makeNamedRule(name: "B1", action: .block(statusCode: 403), enabled: true),
            makeNamedRule(name: "B2", action: .block(statusCode: 403), enabled: true),
        ]
        // No change — same rules
        let capped = RulePolicyGate.capEnabledPerCategory(baseline, limit: 3, baseline: baseline)
        let enabledBlocks = capped.filter { $0.isEnabled && $0.action.toolCategory == "block" }.count
        #expect(enabledBlocks == 2)
    }

    // MARK: - Policy Injection

    @Test("Custom policy takes effect through .shared assignment")
    func customPolicyInjectable() {
        let saved = RulePolicyGate.shared
        defer { RulePolicyGate.shared = saved }

        RulePolicyGate.shared = RulePolicyGate(policy: PolicyWithLimit(5))
        #expect(RulePolicyGate.shared.policy.maxActiveRulesPerTool == 5)

        RulePolicyGate.shared = RulePolicyGate(policy: PolicyWithLimit(99))
        #expect(RulePolicyGate.shared.policy.maxActiveRulesPerTool == 99)
    }

    @Test("Multiple coordinators can each set different policy")
    func multipleCoordinatorPolicies() {
        let saved = RulePolicyGate.shared
        defer { RulePolicyGate.shared = saved }

        _ = MainContentCoordinator(policy: PolicyWithLimit(3))
        #expect(RulePolicyGate.shared.policy.maxActiveRulesPerTool == 3)

        _ = MainContentCoordinator(policy: PolicyWithLimit(7))
        #expect(RulePolicyGate.shared.policy.maxActiveRulesPerTool == 7)
    }

    // MARK: Private

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

    private func makeNamedRule(name: String, action: RuleAction, enabled: Bool) -> ProxyRule {
        var rule = ProxyRule(
            name: name,
            matchCondition: RuleMatchCondition(urlPattern: ".*"),
            action: action
        )
        rule.isEnabled = enabled
        return rule
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

/// Policy that sets the per-tool limit to a specific value.
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
