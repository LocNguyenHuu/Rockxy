import Foundation

// Defines the UI model for configurable request and response table columns.

// MARK: - HeaderColumnSource

enum HeaderColumnSource: String, Codable {
    case request
    case response
}

// MARK: - HeaderColumn

struct HeaderColumn: Identifiable, Codable, Hashable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        headerName: String,
        source: HeaderColumnSource,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.headerName = headerName
        self.source = source
        self.isEnabled = isEnabled
    }

    // MARK: Internal

    let id: UUID
    var headerName: String
    var source: HeaderColumnSource
    var isEnabled: Bool

    var columnIdentifier: String {
        switch source {
        case .request: "reqHeader.\(headerName)"
        case .response: "resHeader.\(headerName)"
        }
    }
}
