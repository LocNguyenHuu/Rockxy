import SwiftUI

// Renders the proxy status indicator interface for toolbar controls and filtering.

// MARK: - ProxyStatusIndicator

/// Toolbar capsule showing the proxy server's running state with a colored dot indicator
/// and the listen address. Clicking opens a popover with connection details and an
/// "Advanced Settings..." button.
struct ProxyStatusIndicator: View {
    // MARK: Internal

    let displayState: ProxyDisplayState
    let listenAddress: String
    let port: Int
    let updateStatusSummary: AppUpdater.UpdateStatusSummary?

    @Binding var showPopover: Bool

    var body: some View {
        Button {
            showPopover.toggle()
        } label: {
            HStack(spacing: 7) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 9, height: 9)
                    .shadow(
                        color: statusShadowColor,
                        radius: 4,
                        x: 0,
                        y: 0
                    )

                Text(statusText)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let updateStatusSummary {
                    updateStatus(updateStatusSummary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.55)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(statusHelpText)
        .popover(isPresented: $showPopover) {
            ProxyStatusPopover(
                listenAddress: listenAddress,
                port: port,
                loopbackAddress: AppSettingsManager.shared.settings.loopbackAddress,
                showPopover: $showPopover
            )
        }
    }

    // MARK: Private

    private var statusColor: Color {
        switch displayState {
        case .starting:
            Color.accentColor
        case .running:
            Color(nsColor: .systemGreen)
        case .paused:
            Color(nsColor: .systemOrange)
        case .stopped:
            Color(nsColor: .tertiaryLabelColor)
        }
    }

    private var statusShadowColor: Color {
        switch displayState {
        case .running:
            Color(nsColor: .systemGreen).opacity(0.45)
        case .starting:
            Color.accentColor.opacity(0.35)
        default:
            Color.clear
        }
    }

    private var statusText: String {
        "Rockxy | \(listenAddress):\(port) | \(displayState.title)"
    }

    private var statusHelpText: String {
        if let updateStatusSummary {
            [
                statusText,
                updateStatusSummary.title,
                updateStatusSummary.versionLine,
                updateStatusSummary.countLine,
            ]
            .compactMap { $0 }
            .joined(separator: "\n")
        } else {
            statusText
        }
    }

    @ViewBuilder
    private func updateStatus(_ summary: AppUpdater.UpdateStatusSummary) -> some View {
        Text("|")
            .font(.caption)
            .foregroundStyle(Color(nsColor: .tertiaryLabelColor))

        ViewThatFits(in: .horizontal) {
            HStack(spacing: 5) {
                Label(summary.title, systemImage: "arrow.down.circle")
                    .labelStyle(.titleAndIcon)
                Text(summary.versionLine)
                if let countLine = summary.countLine {
                    Text(countLine)
                }
            }

            Label(summary.title, systemImage: "arrow.down.circle")
                .labelStyle(.titleAndIcon)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(Color.accentColor)
        .lineLimit(1)
    }
}
