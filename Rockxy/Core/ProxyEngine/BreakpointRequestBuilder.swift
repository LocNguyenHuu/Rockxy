import Foundation
import NIOHTTP1

// Defines `BreakpointRequestBuilder`, which builds breakpoint request values for the proxy
// engine.

// MARK: - BreakpointRequestBuilder

/// Centralises the logic for rebuilding an HTTP request from user-edited breakpoint data.
/// Extracted from `HTTPProxyHandler` and `HTTPSProxyRelayHandler` so the URL-reconstruction
/// and host-pinning behaviour can be unit-tested without a live NIO pipeline.
enum BreakpointRequestBuilder {
    struct Result {
        let head: HTTPRequestHead
        let requestData: HTTPRequestData
    }

    /// Builds a NIO request head and `HTTPRequestData` from the user-modified breakpoint
    /// snapshot, falling back to the original request's authority when the edited URL is
    /// origin-form (path-only) or when the HTTPS tunnel requires a fixed host.
    ///
    /// - Parameters:
    ///   - modifiedData: The snapshot edited by the user in the breakpoint sheet.
    ///   - originalHead: The original NIO request head captured before the breakpoint.
    ///   - originalRequestData: The original `HTTPRequestData` with a fully-qualified URL.
    ///   - isHTTPS: Whether the request is on an HTTPS tunnel (forces original host).
    ///   - originalHost: The CONNECT-tunnel host for HTTPS; ignored for plain HTTP.
    static func build(
        from modifiedData: BreakpointRequestData,
        originalHead: HTTPRequestHead,
        originalRequestData: HTTPRequestData,
        isHTTPS: Bool = false,
        originalHost: String? = nil
    )
        -> Result
    {
        // 1. Resolve URL — preserve original authority for origin-form edits
        var editedURL: URL
        if let parsed = URL(string: modifiedData.url), parsed.host != nil {
            if isHTTPS, let host = originalHost {
                // Force the tunnel host even if the user typed a different absolute URL
                var components = URLComponents(url: parsed, resolvingAgainstBaseURL: false) ?? URLComponents()
                components.scheme = "https"
                components.host = host
                editedURL = components.url ?? originalRequestData.url
            } else {
                editedURL = parsed
            }
        } else {
            // Path-only (origin-form) — rebuild against original host
            var components = URLComponents(
                url: originalRequestData.url,
                resolvingAgainstBaseURL: false
            ) ?? URLComponents()
            let pathQuery = modifiedData.url
            let parts = pathQuery.split(separator: "?", maxSplits: 1)
            components.path = parts.first.map { String($0) } ?? "/"
            if !components.path.hasPrefix("/") {
                components.path = "/" + components.path
            }
            components.query = parts.count > 1 ? String(parts[1]) : nil
            editedURL = components.url ?? originalRequestData.url
        }

        // 1b. Force original scheme for non-HTTPS — the user can type "https://" but the
        // transport is cleartext, so the scheme must match the actual connection.
        if !isHTTPS, let originalScheme = originalRequestData.url.scheme {
            var components = URLComponents(url: editedURL, resolvingAgainstBaseURL: false)
                ?? URLComponents()
            if components.scheme != originalScheme {
                components.scheme = originalScheme
                editedURL = components.url ?? editedURL
            }
        }

        // 2. Build headers from the edited list
        var resolvedHeaders = modifiedData.headers.map {
            HTTPHeader(name: $0.name, value: $0.value)
        }

        // 3. For HTTPS, pin the Host header to the tunnel authority
        if isHTTPS, let host = originalHost {
            if let idx = resolvedHeaders.firstIndex(where: {
                $0.name.caseInsensitiveCompare("Host") == .orderedSame
            }) {
                resolvedHeaders[idx] = HTTPHeader(name: "Host", value: host)
            } else {
                resolvedHeaders.append(HTTPHeader(name: "Host", value: host))
            }
        }

        // 4. Build body
        let body: Data? = modifiedData.body.isEmpty
            ? nil
            : modifiedData.body.data(using: .utf8)

        // 5. Reconcile Content-Length and Transfer-Encoding with the actual body
        if let body, !body.isEmpty {
            resolvedHeaders.removeAll {
                $0.name.caseInsensitiveCompare("Transfer-Encoding") == .orderedSame
            }
            if let idx = resolvedHeaders.firstIndex(where: {
                $0.name.caseInsensitiveCompare("Content-Length") == .orderedSame
            }) {
                resolvedHeaders[idx] = HTTPHeader(name: "Content-Length", value: "\(body.count)")
            } else {
                resolvedHeaders.append(HTTPHeader(name: "Content-Length", value: "\(body.count)"))
            }
        } else {
            resolvedHeaders.removeAll {
                $0.name.caseInsensitiveCompare("Content-Length") == .orderedSame
                    || $0.name.caseInsensitiveCompare("Transfer-Encoding") == .orderedSame
            }
        }

        // 6. Build NIO head
        var head = originalHead
        head.method = HTTPMethod(rawValue: modifiedData.method)
        let pathComponent = editedURL.path.isEmpty ? "/" : editedURL.path
        let queryComponent = editedURL.query.map { "?\($0)" } ?? ""
        head.uri = pathComponent + queryComponent
        head.headers = HTTPHeaders(resolvedHeaders.map { ($0.name, $0.value) })
        if isHTTPS, let host = originalHost {
            head.headers.replaceOrAdd(name: "Host", value: host)
        }

        // 7. Build request data
        let requestData = HTTPRequestData(
            method: modifiedData.method,
            url: editedURL,
            httpVersion: originalRequestData.httpVersion,
            headers: resolvedHeaders,
            body: body,
            contentType: originalRequestData.contentType
        )

        return Result(head: head, requestData: requestData)
    }
}
