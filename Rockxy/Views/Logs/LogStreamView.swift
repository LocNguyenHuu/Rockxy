import SwiftUI

/// Real-time log stream view displaying captured OSLog, stdout/stderr, and custom log entries.
/// Each row shows a color-coded severity badge, message text, and timestamp.
struct LogStreamView: View {
    // MARK: Internal

    let coordinator: MainContentCoordinator

    var body: some View {
        if coordinator.logEntries.isEmpty {
            ContentUnavailableView(
                "No Logs",
                systemImage: "doc.text",
                description: Text("Enable log capture to see application logs")
            )
        } else {
            List(coordinator.logEntries) { entry in
                HStack {
                    logLevelBadge(entry.level)
                    Text(entry.message)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                    Spacer()
                    Text(entry.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: Private

    private func logLevelBadge(_ level: LogLevel) -> some View {
        Text(level.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(levelColor(level).opacity(0.2))
            .foregroundStyle(levelColor(level))
            .cornerRadius(3)
    }

    private func levelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: .gray
        case .info: .blue
        case .notice: .cyan
        case .warning: .orange
        case .error: .red
        case .fault: .purple
        }
    }
}
