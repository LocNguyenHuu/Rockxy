import Foundation

/// A single captured log message from any log source (OSLog, stdout, stderr, custom).
/// When the log engine can correlate a log entry with an HTTP transaction by timestamp
/// and process, `correlatedTransactionId` links the two for cross-referencing in the UI.
struct LogEntry: Identifiable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: LogSource
    let processName: String?
    let subsystem: String?
    let category: String?
    let metadata: [String: String]
    var correlatedTransactionId: UUID?
}
