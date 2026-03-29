import Foundation

// Defines the breakpoint request, response, and decision types shared across breakpoint
// workflows.

// MARK: - BreakpointPhase

/// Whether the breakpoint fires on the outgoing request or the incoming response.
enum BreakpointPhase {
    case request
    case response
}

// MARK: - BreakpointDecision

/// The user's chosen action when a breakpoint-paused request is presented.
enum BreakpointDecision {
    /// Forward the (potentially modified) request to the upstream server.
    case execute
    /// Drop the request and return a 503 Service Unavailable response.
    case abort
    /// Drop the request silently with no response.
    case cancel
}

// MARK: - BreakpointRequestData

/// Editable snapshot of an intercepted HTTP request/response shown in the breakpoint sheet.
struct BreakpointRequestData {
    var method: String
    var url: String
    var headers: [EditableHeader]
    var body: String
    var statusCode: Int
    var phase: BreakpointPhase = .request

    /// Whether the original request uses HTTPS. Used by the breakpoint sheet to constrain
    /// the URL editor so the user can only modify path and query — the host is fixed by the
    /// TLS tunnel and cannot be changed mid-connection.
    var isHTTPS: Bool {
        url.lowercased().hasPrefix("https://")
    }
}

// MARK: - EditableHeader

/// A mutable header name-value pair for the breakpoint editor table.
struct EditableHeader: Identifiable {
    let id = UUID()
    var name: String
    var value: String
}
