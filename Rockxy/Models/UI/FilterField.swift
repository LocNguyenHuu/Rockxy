import Foundation

/// The request property that a search filter targets in the traffic list toolbar.
enum FilterField: String, CaseIterable {
    case url
    case contains
    case host
    case path
    case method
    case statusCode
    case requestHeader
    case responseHeader
    case queryString
    case comment
    case color

    // MARK: Internal

    var displayName: String {
        switch self {
        case .url: "URL"
        case .contains: "Contains"
        case .host: "Host"
        case .path: "Path"
        case .method: "Method"
        case .statusCode: "Status Code"
        case .requestHeader: "Request Header"
        case .responseHeader: "Response Header"
        case .queryString: "Query String"
        case .comment: "Comment"
        case .color: "Color"
        }
    }
}
