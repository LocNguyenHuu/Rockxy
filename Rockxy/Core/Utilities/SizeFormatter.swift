import Foundation

/// Formats byte counts into human-readable strings (e.g. "1.2 MB") using binary (1024-based) units.
enum SizeFormatter {
    static func format(bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
