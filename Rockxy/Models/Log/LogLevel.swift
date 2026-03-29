import Foundation

/// Severity levels for captured log entries, mirroring Apple's OSLog levels.
/// Raw values are ordered by severity to support `Comparable` filtering (e.g. "warning and above").
enum LogLevel: Int, Comparable, CaseIterable {
    case debug = 0
    case info = 1
    case notice = 2
    case warning = 3
    case error = 4
    case fault = 5

    // MARK: Internal

    var displayName: String {
        switch self {
        case .debug: "Debug"
        case .info: "Info"
        case .notice: "Notice"
        case .warning: "Warning"
        case .error: "Error"
        case .fault: "Fault"
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
