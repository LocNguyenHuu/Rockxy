import Foundation

/// Tabs for the request half of the split inspector panel.
enum RequestInspectorTab: String, CaseIterable {
    case headers
    case query
    case body
    case cookies
    case raw
    case synopsis
    case comments

    // MARK: Internal

    var displayName: String {
        switch self {
        case .headers: "Headers"
        case .query: "Query"
        case .body: "Body"
        case .cookies: "Cookies"
        case .raw: "Raw"
        case .synopsis: "Synopsis"
        case .comments: "Comments"
        }
    }
}
