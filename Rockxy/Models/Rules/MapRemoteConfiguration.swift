import Foundation

/// Structured destination configuration for Map Remote rules.
/// Each field is optional — nil means "keep the original request value."
struct MapRemoteConfiguration: Codable, Hashable {
    // MARK: Lifecycle

    init(
        scheme: String? = nil,
        host: String? = nil,
        port: Int? = nil,
        path: String? = nil,
        query: String? = nil,
        preserveHostHeader: Bool = false
    ) {
        self.scheme = scheme
        self.host = host
        self.port = port
        self.path = path
        self.query = query
        self.preserveHostHeader = preserveHostHeader
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        scheme = try container.decodeIfPresent(String.self, forKey: .scheme)
        host = try container.decodeIfPresent(String.self, forKey: .host)
        port = try container.decodeIfPresent(Int.self, forKey: .port)
        path = try container.decodeIfPresent(String.self, forKey: .path)
        query = try container.decodeIfPresent(String.self, forKey: .query)
        preserveHostHeader = try container.decodeIfPresent(Bool.self, forKey: .preserveHostHeader) ?? false
    }

    /// Parses a legacy URL string into structured components.
    init(fromLegacyURL urlString: String) {
        guard let components = URLComponents(string: urlString) else {
            self.init()
            return
        }
        self.init(
            scheme: components.scheme,
            host: components.host,
            port: components.port,
            path: components.path.isEmpty ? nil : components.path,
            query: components.query,
            preserveHostHeader: false
        )
    }

    // MARK: Internal

    var scheme: String?
    var host: String?
    var port: Int?
    var path: String?
    var query: String?
    var preserveHostHeader: Bool

    /// Whether any destination override is set.
    var hasOverride: Bool {
        scheme != nil || host != nil || port != nil || path != nil || query != nil
    }

    /// Returns a summary string for table display.
    var destinationSummary: String {
        if let host {
            if let port {
                return "\(host):\(port)"
            }
            return host
        }
        if let path {
            return path
        }
        if let scheme {
            return "\(scheme)://"
        }
        return "—"
    }
}
