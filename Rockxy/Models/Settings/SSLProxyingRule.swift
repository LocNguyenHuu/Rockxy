import Foundation

/// A domain rule controlling whether Rockxy intercepts HTTPS traffic for that host.
/// Supports exact matches and wildcard prefixes (e.g., `*.example.com`).
struct SSLProxyingRule: Codable, Identifiable, Hashable {
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

    /// Checks whether the given host matches this rule's domain pattern.
    ///
    /// - Wildcard: `*.example.com` matches `foo.example.com`, `bar.baz.example.com`
    /// - Exact: `example.com` matches only `example.com`
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
