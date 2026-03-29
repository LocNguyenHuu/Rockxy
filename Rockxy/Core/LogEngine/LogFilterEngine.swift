import Foundation

/// Stateless filter that narrows a collection of log entries by level, keyword, and source.
/// Used by the UI layer to apply user-selected filters without mutating the underlying buffer.
enum LogFilterEngine {
    static func filter(
        entries: [LogEntry],
        levels: Set<LogLevel>,
        keyword: String?,
        source: LogSource?
    )
        -> [LogEntry]
    {
        var result = entries
        if !levels.isEmpty {
            result = result.filter { levels.contains($0.level) }
        }
        if let keyword, !keyword.isEmpty {
            result = result.filter { $0.message.localizedCaseInsensitiveContains(keyword) }
        }
        // Source filtering could be added here
        return result
    }
}
