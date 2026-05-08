import SwiftUI

// Renders the proxy status indicator interface for toolbar controls and filtering.

// MARK: - ProxyStatusIndicator

/// Toolbar capsule showing the proxy server's running state with a colored dot indicator
/// and the listen address. Clicking opens a popover with connection details and an
/// "Advanced Settings..." button.
struct ProxyStatusIndicator: View {
    // MARK: Internal

    @Environment(\.colorScheme) private var colorScheme

    let displayState: ProxyDisplayState
    let listenAddress: String
    let port: Int
    let updateStatusSummary: AppUpdater.UpdateStatusSummary?
    let openUpdates: () -> Void

    @Binding var showPopover: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button {
                showPopover.toggle()
            } label: {
                HStack(spacing: 7) {
                    statusDot

                    Text(statusText)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if updateStatusSummary != nil {
                        Text("|")
                            .font(.caption)
                            .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, updateStatusSummary == nil ? 12 : 7)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(statusHelpText)

            if let updateStatusSummary {
                updateStatus(updateStatusSummary)
                    .padding(.trailing, 12)
                    .padding(.vertical, 6)
            }
        }
        .background(
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.55)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 9, height: 9)
            .shadow(
                color: statusShadowColor,
                radius: 4,
                x: 0,
                y: 0
            )
    }

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
        Button(action: openUpdates) {
            ViewThatFits(in: .horizontal) {
                updateBadge(summary.badgeTitle)
                updateBadge(String(localized: "Update"))
            }
        }
        .buttonStyle(.plain)
        .help([
            summary.title,
            summary.versionLine,
            summary.countLine,
        ]
        .compactMap { $0 }
        .joined(separator: "\n"))
    }

    private func updateBadge(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(updateBadgeBackground)
            )
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), lineWidth: 1)
            )
    }

    private var updateBadgeBackground: Color {
        Color(nsColor: .systemGray).opacity(colorScheme == .dark ? 0.62 : 0.82)
    }
}
