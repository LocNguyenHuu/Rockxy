import Foundation

// Renders the diff interface for the diff workflow.

// MARK: - CompareTarget

enum CompareTarget: String, CaseIterable {
    case request = "Request"
    case response = "Response"
    case timing = "Timing"
}

// MARK: - PresentationMode

enum PresentationMode: String, CaseIterable {
    case sideBySide = "Side by Side"
    case unified = "Unified"
}

// MARK: - DiffFormatter

/// Formats HTTPTransaction data into structured sections for diffing.
/// Produces named section pairs that DiffEngine can compare.
enum DiffFormatter {
    // MARK: Internal

    /// Formats a transaction into named sections based on the compare target.
    static func format(
        transaction: HTTPTransaction,
        target: CompareTarget
    )
        -> [(title: String, content: String)]
    {
        switch target {
        case .request:
            formatRequest(transaction)
        case .response:
            formatResponse(transaction)
        case .timing:
            formatTiming(transaction)
        }
    }

    /// Computes a structured diff between two transactions for the given compare target.
    static func diff(
        left: HTTPTransaction,
        right: HTTPTransaction,
        target: CompareTarget
    )
        -> DiffResult
    {
        let leftSections = format(transaction: left, target: target)
        let rightSections = format(transaction: right, target: target)
        return DiffEngine.diffSections(leftSections: leftSections, rightSections: rightSections)
    }

    // MARK: Private

    // MARK: - Request Formatting

    private static func formatRequest(_ transaction: HTTPTransaction) -> [(String, String)] {
        var sections: [(String, String)] = []

        // Request line
        sections.append((
            "Request Line",
            "\(transaction.request.method) \(transaction.request.url.path) \(normalizeHTTPVersion(transaction.request.httpVersion))"
        ))

        // Host
        sections.append((
            "Host",
            transaction.request.url.host ?? "—"
        ))

        // Query
        let queryItems = URLComponents(url: transaction.request.url, resolvingAgainstBaseURL: false)?
            .queryItems ?? []
        if !queryItems.isEmpty {
            let queryText = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "\n")
            sections.append(("Query", queryText))
        } else {
            sections.append(("Query", "(no query parameters)"))
        }

        // Request headers
        let headersText = transaction.request.headers
            .map { "\($0.name): \($0.value)" }
            .joined(separator: "\n")
        sections.append(("Headers", headersText.isEmpty ? "(no headers)" : headersText))

        // Request body
        if let body = transaction.request.body {
            sections.append(("Body", formatBody(body, contentType: transaction.request.contentType?.rawValue)))
        } else {
            sections.append(("Body", "No request body"))
        }

        return sections
    }

    // MARK: - Response Formatting

    private static func formatResponse(_ transaction: HTTPTransaction) -> [(String, String)] {
        var sections: [(String, String)] = []

        guard let response = transaction.response else {
            return [
                ("Status Line", "No response"),
                ("Headers", "(no headers)"),
                ("Body", "No response body"),
            ]
        }

        // Status line
        sections.append((
            "Status Line",
            "HTTP/1.1 \(response.statusCode) \(response.statusMessage)"
        ))

        // Response headers
        let headersText = response.headers
            .map { "\($0.name): \($0.value)" }
            .joined(separator: "\n")
        sections.append(("Headers", headersText.isEmpty ? "(no headers)" : headersText))

        // Response body
        if let body = response.body {
            let contentType = response.headers.first { $0.name.lowercased() == "content-type" }?.value
            sections.append(("Body", formatBody(body, contentType: contentType)))
        } else {
            sections.append(("Body", "No response body"))
        }

        return sections
    }

    // MARK: - Timing Formatting

    private static func formatTiming(_ transaction: HTTPTransaction) -> [(String, String)] {
        guard let timing = transaction.timingInfo else {
            return [("Timing", "No timing data")]
        }

        let content = """
        DNS Lookup:       \(formatMs(timing.dnsLookup))
        TCP Connection:   \(formatMs(timing.tcpConnection))
        TLS Handshake:    \(formatMs(timing.tlsHandshake))
        Time to First Byte: \(formatMs(timing.timeToFirstByte))
        Content Transfer:  \(formatMs(timing.contentTransfer))
        Total:            \(formatMs(timing.totalDuration))
        """

        return [("Timing", content)]
    }

    // MARK: - Body Formatting

    private static func formatBody(_ data: Data, contentType: String?) -> String {
        // Check if binary
        guard let text = String(data: data, encoding: .utf8) else {
            let ct = contentType ?? "unknown"
            return "Binary body (\(data.count) bytes, \(ct))"
        }

        // Try JSON pretty-print
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(
               withJSONObject: jsonObject,
               options: [.prettyPrinted, .sortedKeys]
           ),
           let prettyText = String(data: prettyData, encoding: .utf8)
        {
            return prettyText
        }

        return text
    }

    private static func normalizeHTTPVersion(_ version: String) -> String {
        version.hasPrefix("HTTP/") ? version : "HTTP/\(version)"
    }

    private static func formatMs(_ seconds: TimeInterval) -> String {
        String(format: "%.1fms", seconds * 1000)
    }
}
