import Foundation

/// Lightweight draft for Network Conditions editor handoff.
struct NetworkConditionsDraft {
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
