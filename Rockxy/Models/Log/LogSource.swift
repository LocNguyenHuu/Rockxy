import Foundation

/// Identifies where a log entry originated. Used to filter and group log entries
/// by capture method in the log viewer.
enum LogSource: Hashable {
    case oslog(subsystem: String)
    case processStdout(pid: Int32)
    case processStderr(pid: Int32)
    case custom(name: String)

    // MARK: Internal

    var displayName: String {
        switch self {
        case let .oslog(subsystem): "OSLog: \(subsystem)"
        case let .processStdout(pid): "stdout (PID \(pid))"
        case let .processStderr(pid): "stderr (PID \(pid))"
        case let .custom(name): name
        }
    }
}
