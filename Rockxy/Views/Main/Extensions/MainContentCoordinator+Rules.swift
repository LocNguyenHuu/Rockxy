import Foundation
import os

// Extends `MainContentCoordinator` with rules behavior for the main workspace.

// MARK: - MainContentCoordinator + Rules

/// Coordinator extension for proxy rule management (block, map, breakpoint, throttle).
/// Delegates to `RulePolicyGate` which enforces per-category quotas before
/// forwarding to `RuleSyncService`.
extension MainContentCoordinator {
    // MARK: - Rule Management

    func addRule(_ rule: ProxyRule) {
        Task {
            let accepted = await RulePolicyGate.shared.addRule(rule)
            if !accepted {
                Self.logger.info("Rule add rejected — quota reached for \(rule.action.toolCategory)")
                activeToast = ToastMessage(
                    style: .error,
                    text: String(localized: "Rule limit reached for this category")
                )
            }
        }
    }

    func removeRule(id: UUID) {
        Task { await RulePolicyGate.shared.removeRule(id: id) }
    }

    func toggleRule(id: UUID) {
        Task {
            let accepted = await RulePolicyGate.shared.toggleRule(id: id)
            if !accepted {
                Self.logger.info("Rule toggle rejected — quota reached")
                activeToast = ToastMessage(
                    style: .error,
                    text: String(localized: "Rule limit reached for this category")
                )
            }
        }
    }

    func createBreakpointRule(for transaction: HTTPTransaction) {
        let context = BreakpointEditorContextBuilder.fromTransaction(transaction)
        BreakpointEditorContextStore.shared.setPending(context)
        NotificationCenter.default.post(name: .openBreakpointRulesWindow, object: nil)
    }
}
