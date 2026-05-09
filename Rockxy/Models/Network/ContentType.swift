import Foundation

/// Normalized content type categories derived from the `Content-Type` header.
/// Used to select the appropriate body renderer (JSON tree, image preview, hex dump, etc.)
/// and to power content-type-based protocol filters.
enum ContentType: String, Sendable {
    case json
    case xml
    case html
    case image
    case form
    case multipartForm
    case protobuf
    case binary
    case text
    case unknown

    // MARK: Internal

    static func detect(from header: String?) -> ContentType {
        guard let header = header?.lowercased() else {
            return .unknown
        }
        if header.contains("application/json") {
            return .json
        }
        if header.contains("text/xml") || header.contains("application/xml") {
            return .xml
        }
        if header.contains("text/html") {
            return .html
        }
        if header.hasPrefix("image/") {
            return .image
        }
        if header.contains("application/x-www-form-urlencoded") {
            return .form
        }
        if header.contains("multipart/form-data") {
            return .multipartForm
        }
        if header.contains("application/grpc") || header.contains("application/protobuf") {
            return .protobuf
        }
        if header.hasPrefix("text/") {
            return .text
        }
        return .unknown
    }
}
