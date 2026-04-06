import Combine
import SwiftUI

// Renders the status bar interface for traffic list presentation.

// MARK: - FooterButton

/// Styled button used in the status bar footer, with an active/inactive visual state.
private struct FooterButton: View {
    let title: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .white : Color(nsColor: .secondaryLabelColor))
                .padding(.horizontal, 11)
                .padding(.vertical, 3)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isActive
                                ? AnyShapeStyle(Color.accentColor)
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(nsColor: .controlBackgroundColor),
                                            Color(nsColor: .controlColor),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    isActive
                                        ? Color.accentColor
                                        : Color(nsColor: .separatorColor),
                                    lineWidth: 0.5
                                )
                        }
                        .shadow(color: .black.opacity(0.06), radius: 0.5, y: 0.5)
                }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StatusBarView

/// Bottom status bar showing request counts, bandwidth stats (upload/download speed),
/// and quick-action buttons for clearing, toggling filters, and auto-select mode.
struct StatusBarView: View {
    // MARK: Internal

    let totalCount: Int
    let selectedCount: Int
    var isProxyRunning: Bool = false
    var proxyPort: Int = 9_090
    var totalDataSize: Int64 = 0
    var uploadSpeed: Int64 = 0
    var downloadSpeed: Int64 = 0
    var isProxyOverridden: Bool = false
    var isAllowListActive: Bool = false
    var isNoCachingActive: Bool = false
    var isAutoSelectEnabled: Bool = true
    var isFilterBarVisible: Bool = false
    var activeFilterCount: Int = 0
    var errorCount: Int = 0
    var proxyStartedAt: Date?
    var selectedRequestInfo: String?
    var sessionProvenance: SessionProvenance?

    var onClear: () -> Void = {}
    var onFilter: () -> Void = {}
    var onAutoSelect: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            leftButtons
            Spacer()
            centerStatus
            Spacer()
            rightStats
        }
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: Private

    private var statusText: String {
        if totalCount == 0 {
            return String(localized: "No requests")
        }
        if selectedCount > 0 {
            return String(localized: "\(selectedCount)/\(totalCount) rows selected")
        }
        return String(localized: "\(totalCount) requests")
    }

    private var formattedDataSize: String {
        ByteCountFormatter.string(fromByteCount: totalDataSize, countStyle: .file)
    }

    private var leftButtons: some View {
        HStack(spacing: 6) {
            FooterButton(
                title: String(localized: "Clear"),
                action: onClear
            )
            FooterButton(
                title: activeFilterCount > 0
                    ? String(localized: "Filters (\(activeFilterCount))")
                    : String(localized: "Filter"),
                isActive: isFilterBarVisible || activeFilterCount > 0,
                action: onFilter
            )
            FooterButton(
                title: String(localized: "Auto Select"),
                isActive: isAutoSelectEnabled,
                action: onAutoSelect
            )
        }
    }

    private var centerStatus: some View {
        Group {
            if let provenance = sessionProvenance {
                Text(provenance.displayText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
            } else {
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: .secondaryLabelColor))
            }
        }
    }

    private var rightStats: some View {
        HStack(spacing: 8) {
            if let selectedRequestInfo {
                Text(selectedRequestInfo)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(nsColor: .secondaryLabelColor))
                    .lineLimit(1)

                Divider()
                    .frame(height: 12)
            }

            if errorCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9))
                    Text(String(localized: "\(errorCount) errors"))
                        .font(.system(size: 11))
                }
                .foregroundStyle(Color(nsColor: .systemRed))
            }

            if let proxyStartedAt {
                SessionDurationView(startedAt: proxyStartedAt)
            }

            Text("\(formattedDataSize) total")
                .font(.system(size: 11))
                .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                .help("Total captured payload bytes")

            Text("↑ \(formattedSpeed(uploadSpeed))")
                .font(.system(size: 11))
                .foregroundStyle(Color(nsColor: .systemGreen))
                .help("Captured upload throughput")

            Text("↓ \(formattedSpeed(downloadSpeed))")
                .font(.system(size: 11))
                .foregroundStyle(Color.accentColor)
                .help("Captured download throughput")

            if isAllowListActive {
                Text(String(localized: "Allow List"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
            }

            if isNoCachingActive {
                Text(String(localized: "No Cache"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 4))
            }

            if isProxyOverridden {
                Text(String(localized: "Proxy Overridden"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private func formattedSpeed(_ bytesPerSecond: Int64) -> String {
        if bytesPerSecond < 1_024 {
            return "\(bytesPerSecond) B/s"
        } else if bytesPerSecond < 1_048_576 {
            return "\(bytesPerSecond / 1_024) KB/s"
        } else {
            let mb = Double(bytesPerSecond) / 1_048_576
            return String(format: "%.1f MB/s", mb)
        }
    }
}

// MARK: - SessionDurationView

/// Displays elapsed time since the proxy session started, updating every second.
private struct SessionDurationView: View {
    // MARK: Internal

    let startedAt: Date

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock")
                .font(.system(size: 9))
            Text(formattedDuration)
                .font(.system(size: 11).monospacedDigit())
        }
        .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
        .onReceive(timer) { tick in
            now = tick
        }
    }

    // MARK: Private

    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var formattedDuration: String {
        let interval = Int(now.timeIntervalSince(startedAt))
        let hours = interval / 3_600
        let minutes = (interval % 3_600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
