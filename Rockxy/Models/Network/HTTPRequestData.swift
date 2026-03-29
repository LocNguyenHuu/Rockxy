import Foundation

// Defines `HTTPRequestData`, the model for http request data used by proxy, storage, and
// inspection flows.

// MARK: - HTTPRequestData

/// Captured HTTP request data including method, URL, headers, and optional body.
/// This is a value type snapshot — mutating headers or body creates a modified copy
/// used by the rule engine (breakpoint editing) and request replay.
struct HTTPRequestData {
    let method: String
    let url: URL
    let httpVersion: String
    var headers: [HTTPHeader]
    var body: Data?
    var contentType: ContentType?

    var host: String {
        url.host() ?? ""
    }

    var path: String {
        url.path()
    }

    var cookies: [HTTPCookie] {
        guard let headerValue = headers.first(where: { $0.name.lowercased() == "cookie" })?.value else {
            return []
        }
        return HTTPCookie.cookies(
            withResponseHeaderFields: ["Set-Cookie": headerValue],
            for: url
        )
    }
}

// MARK: - HTTPHeader

/// A single HTTP header name-value pair, used in both requests and responses.
struct HTTPHeader: Equatable {
    let name: String
    let value: String
}
