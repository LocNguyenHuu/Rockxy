import Foundation

/// Lightweight draft for Map Remote editor handoff.
struct MapRemoteDraft {
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
}
