import Foundation

/// Tabs for the response half of the split inspector panel.
enum ResponseInspectorTab: String, CaseIterable {
    case headers
    case body
    case setCookie
    case auth
    case timeline

    // MARK: Internal

    var displayName: String {
        switch self {
        case .headers: "Headers"
        case .body: "Body"
        case .setCookie: "Set-Cookie"
        case .auth: "Auth"
        case .timeline: "Timeline"
        }
    }
}
