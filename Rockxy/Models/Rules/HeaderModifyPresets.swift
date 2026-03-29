import Foundation

/// Shared preset definitions for Modify Header rules.
/// Used by both RuleListView (Presets menu) and ModifyHeaderWindowView (bottom bar Presets menu).
enum HeaderModifyPresets {
    static func corsHeaders() -> ProxyRule {
        ProxyRule(
            name: "Add CORS Headers",
            matchCondition: RuleMatchCondition(urlPattern: ".*"),
            action: .modifyHeader(operations: [HeaderOperation(
                type: .add,
                headerName: "Access-Control-Allow-Origin",
                headerValue: "*",
                phase: .response
            )])
        )
    }

    static func removeAuthorization() -> ProxyRule {
        ProxyRule(
            name: "Remove Authorization",
            matchCondition: RuleMatchCondition(urlPattern: ".*"),
            action: .modifyHeader(operations: [HeaderOperation(
                type: .remove,
                headerName: "Authorization",
                headerValue: nil,
                phase: .request
            )])
        )
    }

    static func stripServerHeader() -> ProxyRule {
        ProxyRule(
            name: "Strip Server Header",
            matchCondition: RuleMatchCondition(urlPattern: ".*"),
            action: .modifyHeader(operations: [HeaderOperation(
                type: .remove,
                headerName: "Server",
                headerValue: nil,
                phase: .response
            )])
        )
    }
}
