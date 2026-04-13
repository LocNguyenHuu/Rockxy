import Foundation
import os

/// App-layer quota gate for rule mutations. Wraps `RuleSyncService` with
/// per-category active rule limits. All rule-creating UI surfaces route
/// add, toggle, and enable calls through this gate.
///
/// Non-quota-affected operations (remove, update, disable) pass through
/// directly to `RuleSyncService`.
@MainActor
final class RulePolicyGate {
    // MARK: Lifecycle

    init(policy: any AppPolicy = DefaultAppPolicy()) {
        self.policy = policy
    }

    // MARK: Internal

    static var shared = RulePolicyGate()

    let policy: any AppPolicy

    /// Cap enabled rules only in categories that exceed the limit compared to the
    /// `baseline`. Categories unchanged or within quota are left untouched.
    static func capEnabledPerCategory(
        _ rules: [ProxyRule],
        limit: Int,
        baseline: [ProxyRule]
    )
        -> [ProxyRule]
    {
        let baselineCounts = enabledCounts(in: baseline)
        var newCounts = enabledCounts(in: rules)

        // Only enforce on categories that grew beyond the limit
        var categoriesToCap: Set<String> = []
        for (cat, count) in newCounts where count > limit {
            let prior = baselineCounts[cat, default: 0]
            if count > prior {
                categoriesToCap.insert(cat)
            }
        }

        guard !categoriesToCap.isEmpty else {
            return rules
        }

        var result = rules
        var running: [String: Int] = [:]
        for index in result.indices where result[index].isEnabled {
            let cat = result[index].action.toolCategory
            guard categoriesToCap.contains(cat) else {
                continue
            }
            let count = running[cat, default: 0]
            if count >= limit {
                result[index].isEnabled = false
                newCounts[cat] = (newCounts[cat] ?? 0) - 1
            } else {
                running[cat] = count + 1
            }
        }
        return result
    }

    // MARK: - Quota-Checked Operations

    @discardableResult
    func addRule(_ rule: ProxyRule) async -> Bool {
        if rule.isEnabled {
            guard await canAddActiveRule(action: rule.action) else {
                Self.logger.info("Rule quota reached for \(rule.action.toolCategory)")
                return false
            }
        }
        await RuleSyncService.addRule(rule)
        return true
    }

    @discardableResult
    func toggleRule(id: UUID) async -> Bool {
        let allRules = await RuleEngine.shared.allRules
        guard let rule = allRules.first(where: { $0.id == id }) else {
            return false
        }
        if !rule.isEnabled {
            guard await canAddActiveRule(action: rule.action) else {
                Self.logger.info("Cannot enable rule — quota reached for \(rule.action.toolCategory)")
                return false
            }
        }
        await RuleSyncService.toggleRule(id: id)
        return true
    }

    @discardableResult
    func setRuleEnabled(id: UUID, enabled: Bool) async -> Bool {
        if enabled {
            let allRules = await RuleEngine.shared.allRules
            guard let rule = allRules.first(where: { $0.id == id }) else {
                return false
            }
            guard await canAddActiveRule(action: rule.action) else {
                Self.logger.info("Cannot enable rule — quota reached for \(rule.action.toolCategory)")
                return false
            }
        }
        await RuleSyncService.setRuleEnabled(id: id, enabled: enabled)
        return true
    }

    func addNetworkConditionExclusive(_ rule: ProxyRule) async -> Bool {
        guard await canAddActiveRule(action: rule.action) else {
            Self.logger.info("Rule quota reached for networkCondition")
            return false
        }
        await RuleSyncService.addNetworkConditionExclusive(rule)
        return true
    }

    // MARK: - Pass-Through Operations (no quota impact)

    func removeRule(id: UUID) async {
        await RuleSyncService.removeRule(id: id)
    }

    func updateRule(_ rule: ProxyRule) async {
        await RuleSyncService.updateRule(rule)
    }

    func enableExclusiveNetworkCondition(id: UUID) async {
        await RuleSyncService.enableExclusiveNetworkCondition(id: id)
    }

    func disableAllNetworkConditions() async {
        await RuleSyncService.disableAllNetworkConditions()
    }

    func replaceAllRules(_ rules: [ProxyRule]) async {
        let baseline = await RuleEngine.shared.allRules
        let capped = Self.capEnabledPerCategory(rules, limit: policy.maxActiveRulesPerTool, baseline: baseline)
        await RuleSyncService.replaceAllRules(capped)
    }

    func setBreakpointToolEnabled(_ enabled: Bool) async {
        await RuleSyncService.setBreakpointToolEnabled(enabled)
    }

    // MARK: Private

    private static let logger = Logger(
        subsystem: RockxyIdentity.current.logSubsystem,
        category: "RulePolicyGate"
    )

    private static func enabledCounts(in rules: [ProxyRule]) -> [String: Int] {
        var counts: [String: Int] = [:]
        for rule in rules where rule.isEnabled {
            counts[rule.action.toolCategory, default: 0] += 1
        }
        return counts
    }

    private func canAddActiveRule(action: RuleAction) async -> Bool {
        let allRules = await RuleEngine.shared.allRules
        let category = action.toolCategory
        let activeCount = allRules.filter { $0.isEnabled && $0.action.toolCategory == category }.count
        return activeCount < policy.maxActiveRulesPerTool
    }
}
