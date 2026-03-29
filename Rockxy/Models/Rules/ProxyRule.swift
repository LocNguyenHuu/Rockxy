import Foundation

/// A user-defined rule evaluated by the `RuleEngine` against each proxied request.
/// Rules are persisted as JSON and evaluated in priority order. Each rule pairs
/// a `RuleMatchCondition` (URL pattern, method, header) with a `RuleAction`
/// (block, map local/remote, breakpoint, throttle, modify header).
struct ProxyRule: Identifiable, Codable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        matchCondition: RuleMatchCondition,
        action: RuleAction,
        priority: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.matchCondition = matchCondition
        self.action = action
        self.priority = priority
    }

    // MARK: Internal

    let id: UUID
    var name: String
    var isEnabled: Bool
    var matchCondition: RuleMatchCondition
    var action: RuleAction
    var priority: Int
}
