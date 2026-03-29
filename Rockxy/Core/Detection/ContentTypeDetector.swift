import Foundation

/// Extracts the `Content-Type` header from an HTTP message and maps it
/// to a `ContentType` enum value used throughout the app for selecting
/// the appropriate inspector plugin and body renderer.
enum ContentTypeDetector {
    static func detect(headers: [HTTPHeader], body: Data?) -> ContentType {
        let headerValue = headers.first { $0.name.lowercased() == "content-type" }?.value
        return ContentType.detect(from: headerValue)
    }
}
