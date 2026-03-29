import Foundation

/// A domain entry in the Allow List for capture-level filtering.
/// When the allow list is active, only traffic matching these entries is captured.
/// Supports exact matches and wildcard prefixes (e.g., `*.example.com`).
struct AllowListEntry: Identifiable, Codable, Hashable {
    // MARK: Lifecycle

    init(id: UUID = UUID(), domain: String, isEnabled: Bool = true) {
        self.id = id
        self.domain = domain
        self.isEnabled = isEnabled
    }

    // MARK: Internal

    let id: UUID
    var domain: String
    var isEnabled: Bool

    /// Checks whether the given host matches this allow list pattern.
    ///
    /// - Wildcard: `*.example.com` matches `api.example.com`, `sub.api.example.com`
    /// - Exact: `httpbin.org` matches only `httpbin.org`
    func matches(_ host: String) -> Bool {
        let lowerDomain = domain.lowercased()
        let lowerHost = host.lowercased()

        if lowerDomain.hasPrefix("*.") {
            let suffix = String(lowerDomain.dropFirst(1))
            return lowerHost.hasSuffix(suffix) && lowerHost.count > suffix.count
        }

        return lowerHost == lowerDomain
    }
}
