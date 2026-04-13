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

    private(set) static var shared = RulePolicyGate()

    let policy: any AppPolicy

    static func configure(policy: any AppPolicy) {
        guard !isConfigured else {
            return
        }
        isConfigured = true
        shared = RulePolicyGate(policy: policy)
    }

    /// Reset shared state for testing. Not for production use.
    static func resetForTesting(policy: any AppPolicy = DefaultAppPolicy()) {
        isConfigured = false
        configure(policy: policy)
    }

    static func capEnabledPerCategory(_ rules: [ProxyRule], limit: Int) -> [ProxyRule] {
        var counts: [String: Int] = [:]
        var result = rules
        for index in result.indices where result[index].isEnabled {
            let cat = result[index].action.toolCategory
            let count = counts[cat, default: 0]
            if count >= limit {
                result[index].isEnabled = false
            } else {
                counts[cat] = count + 1
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
        let capped = Self.capEnabledPerCategory(rules, limit: policy.maxActiveRulesPerTool)
        await RuleSyncService.replaceAllRules(capped)
    }

    func setBreakpointToolEnabled(_ enabled: Bool) async {
        await RuleSyncService.setBreakpointToolEnabled(enabled)
    }

    // MARK: Private

    private static var isConfigured = false

    private static let logger = Logger(
        subsystem: RockxyIdentity.current.logSubsystem,
        category: "RulePolicyGate"
    )

    private func canAddActiveRule(action: RuleAction) async -> Bool {
        let allRules = await RuleEngine.shared.allRules
        let category = action.toolCategory
        let activeCount = allRules.filter { $0.isEnabled && $0.action.toolCategory == category }.count
        return activeCount < policy.maxActiveRulesPerTool
    }
}
