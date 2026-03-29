import Foundation

/// Represents a named, toggleable log capture channel (OSLog subsystem, process stdout/stderr, etc.).
/// Displayed in the sidebar so users can enable or disable individual log sources.
struct LogStream: Identifiable {
    let id: UUID
    let name: String
    let source: LogSource
    var isActive: Bool
}
