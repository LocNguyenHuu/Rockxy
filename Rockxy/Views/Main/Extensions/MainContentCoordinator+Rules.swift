import Foundation

// Extends `MainContentCoordinator` with rules behavior for the main workspace.

// MARK: - MainContentCoordinator + Rules

/// Coordinator extension for proxy rule management (block, map, breakpoint, throttle).
/// Delegates to `RuleSyncService` which coordinates between the shared `RuleEngine` actor,
/// disk persistence via `RuleStore`, and UI notification via `NotificationCenter`.
extension MainContentCoordinator {
    // MARK: - Rule Management

    func addRule(_ rule: ProxyRule) {
        Task { await RuleSyncService.addRule(rule) }
    }

    func removeRule(id: UUID) {
        Task { await RuleSyncService.removeRule(id: id) }
    }

    func toggleRule(id: UUID) {
        Task { await RuleSyncService.toggleRule(id: id) }
    }

    func createBreakpointRule(for transaction: HTTPTransaction) {
        let host = transaction.request.host
        let path = transaction.request.path.isEmpty ? "/" : transaction.request.path
        let escapedHost = NSRegularExpression.escapedPattern(for: host)
        let escapedPath = NSRegularExpression.escapedPattern(for: path)
        let pattern = ".*\(escapedHost)\(escapedPath).*"

        let rule = ProxyRule(
            name: "Breakpoint: \(host)\(path)",
            matchCondition: RuleMatchCondition(urlPattern: pattern),
            action: .breakpoint(phase: .both)
        )
        Task {
            await RuleSyncService.addRule(rule)
            BreakpointWindowModel.shared.selectRule(rule.id)
            NotificationCenter.default.post(name: .breakpointRuleCreated, object: nil)
        }
    }
}
