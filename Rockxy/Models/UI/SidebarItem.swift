import Foundation

// Defines the UI model for sidebar navigation targets.

// MARK: - SidebarItem

/// Represents a selectable row in the sidebar source list.
/// Covers domain groupings, app sources, saved filters, rules, persisted sessions,
/// log streams, and analytics sections.
enum SidebarItem: Hashable, Codable {
    case domainNode(domain: String)
    case domainPath(domain: String, pathPrefix: String)
    case app(name: String, bundleId: String?)
    case filter(name: String)
    case ruleGroup
    case savedSession(id: UUID, name: String)
    case logStream(id: UUID)
    case pinnedTransaction(id: UUID)
    case savedTransaction(id: UUID)
    case allApps
    case allDomains
    case allPinned
    case allSaved
}
