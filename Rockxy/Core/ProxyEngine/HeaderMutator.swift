import NIOHTTP1

/// Shared header mutation logic used by HTTPProxyHandler, HTTPSProxyRelayHandler,
/// and UpstreamResponseHandler. Preserves existing header order except where
/// remove/replace intentionally changes it.
enum HeaderMutator {
    /// Apply a list of header operations to Rockxy's `[HTTPHeader]` model (request-side).
    /// Operations are applied in order — later operations can overwrite earlier ones.
    static func apply(_ operations: [HeaderOperation], to headers: inout [HTTPHeader]) {
        for op in operations {
            switch op.type {
            case .add:
                if let value = op.headerValue {
                    headers.append(HTTPHeader(name: op.headerName, value: value))
                }
            case .remove:
                headers.removeAll { $0.name.lowercased() == op.headerName.lowercased() }
            case .replace:
                headers.removeAll { $0.name.lowercased() == op.headerName.lowercased() }
                if let value = op.headerValue {
                    headers.append(HTTPHeader(name: op.headerName, value: value))
                }
            }
        }
    }

    /// Apply a list of header operations to NIO `HTTPHeaders` (response-side).
    /// Operations are applied in order — later operations can overwrite earlier ones.
    static func apply(_ operations: [HeaderOperation], to headers: inout HTTPHeaders) {
        for op in operations {
            switch op.type {
            case .add:
                if let value = op.headerValue {
                    headers.add(name: op.headerName, value: value)
                }
            case .remove:
                headers.remove(name: op.headerName)
            case .replace:
                headers.remove(name: op.headerName)
                if let value = op.headerValue {
                    headers.add(name: op.headerName, value: value)
                }
            }
        }
    }
}
