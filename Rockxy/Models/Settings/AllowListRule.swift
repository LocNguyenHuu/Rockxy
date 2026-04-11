import Foundation

// MARK: - AllowListRule

/// A capture-level allow rule. When the Allow List is active, only traffic matching
/// an enabled rule is recorded in the session. Non-matching traffic is still proxied
/// (forwarded) but not displayed or stored.
///
/// The model holds only source-of-truth user-facing fields. Regex compilation for
/// runtime matching happens exclusively in `AllowListManager.rebuildCache()` and
/// is never persisted.
struct AllowListRule: Identifiable, Codable, Hashable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        rawPattern: String,
        method: String? = nil,
        matchType: RuleMatchType = .wildcard,
        includeSubpaths: Bool = true
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.rawPattern = rawPattern
        self.method = Self.normalizeMethod(method)
        self.matchType = matchType
        self.includeSubpaths = includeSubpaths
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        rawPattern = try container.decode(String.self, forKey: .rawPattern)
        let decodedMethod = try container.decodeIfPresent(String.self, forKey: .method)
        method = Self.normalizeMethod(decodedMethod)
        matchType = try container.decode(RuleMatchType.self, forKey: .matchType)
        includeSubpaths = try container.decode(Bool.self, forKey: .includeSubpaths)
    }

    // MARK: Internal

    let id: UUID
    var name: String
    var isEnabled: Bool
    /// User-facing pattern. For `.wildcard` rules this is e.g. `*example.com/v1/*`.
    /// For `.regex` rules this is the raw regex source.
    var rawPattern: String
    /// HTTP method filter. `nil` matches any method. Stored uppercased and
    /// whitespace-trimmed; empty strings and any form of "ANY" map to `nil`.
    var method: String?
    var matchType: RuleMatchType
    /// Display flag for wildcard rules. Ignored at runtime for `.regex` rules.
    var includeSubpaths: Bool

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case isEnabled
        case rawPattern
        case method
        case matchType
        case includeSubpaths
    }

    /// Normalizes an HTTP method string for storage:
    /// - trims whitespace
    /// - uppercases non-empty values
    /// - maps `nil`, empty, or any form of `"ANY"` to `nil`
    private static func normalizeMethod(_ raw: String?) -> String? {
        guard let raw else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        let upper = trimmed.uppercased()
        return upper == "ANY" ? nil : upper
    }
}
