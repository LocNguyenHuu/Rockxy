import Foundation

/// Tabs available in the combined request/response inspector panel.
/// Protocol-specific tabs (WebSocket, GraphQL, Certificates) are shown conditionally
/// based on the selected transaction's type.
enum InspectorTab: String, CaseIterable {
    case headers
    case body
    case cookies
    case timing
    case raw
    case certificates
    case websocket
    case graphql

    // MARK: Internal

    var displayName: String {
        switch self {
        case .headers: "Headers"
        case .body: "Body"
        case .cookies: "Cookies"
        case .timing: "Timing"
        case .raw: "Raw"
        case .certificates: "Certs"
        case .websocket: "WebSocket"
        case .graphql: "GraphQL"
        }
    }
}
