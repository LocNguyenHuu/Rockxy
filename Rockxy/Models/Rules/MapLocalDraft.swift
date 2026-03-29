import Foundation

/// Lightweight draft for Map Local editor handoff. Stores only what the editor needs,
/// NOT the full HTTPTransaction. Supports both transaction quick-create and domain quick-create.
struct MapLocalDraft {
    // MARK: Lifecycle

    init(
        origin: Origin,
        suggestedName: String,
        sourceURL: URL? = nil,
        sourceHost: String,
        sourcePath: String? = nil,
        sourceMethod: String? = nil,
        responseBody: Data? = nil,
        responseContentType: String? = nil,
        inferredExtension: String? = nil
    ) {
        self.origin = origin
        self.suggestedName = suggestedName
        self.sourceURL = sourceURL
        self.sourceHost = sourceHost
        self.sourcePath = sourcePath
        self.sourceMethod = sourceMethod
        self.responseBody = responseBody
        self.responseContentType = responseContentType
        self.inferredExtension = inferredExtension
    }

    // MARK: Internal

    enum Origin: Equatable {
        case selectedTransaction
        case domainQuickCreate
    }

    let origin: Origin
    let suggestedName: String
    let sourceURL: URL?
    let sourceHost: String
    let sourcePath: String?
    let sourceMethod: String?
    let responseBody: Data?
    let responseContentType: String?
    let inferredExtension: String?

    var hasResponseBody: Bool {
        guard let body = responseBody else {
            return false
        }
        return !body.isEmpty
    }
}
