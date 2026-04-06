import Foundation

/// Formats time durations into the most readable unit: microseconds, milliseconds, seconds, or minutes.
enum DurationFormatter {
    static func format(seconds: TimeInterval) -> String {
        if seconds < 0.001 {
            return String(format: "%.0f µs", seconds * 1_000_000)
        } else if seconds < 1 {
            return String(format: "%.0f ms", seconds * 1_000)
        } else if seconds < 60 {
            return String(format: "%.2f s", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = seconds.truncatingRemainder(dividingBy: 60)
            return String(format: "%dm %.0fs", minutes, remainingSeconds)
        }
    }
}
