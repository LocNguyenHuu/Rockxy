import SwiftUI

// Renders the proxy status indicator interface for toolbar controls and filtering.

// MARK: - ProxyStatusIndicator

/// Toolbar capsule showing the proxy server's running state with a colored dot indicator
/// and the listen address. Clicking opens a popover with connection details and an
/// "Advanced Settings..." button.
struct ProxyStatusIndicator: View {
    // MARK: Internal

    let isRunning: Bool
    let listenAddress: String
    let port: Int

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
                        color: isRunning ? Color.green.opacity(0.5) : Color.clear,
                        radius: 4,
                        x: 0,
                        y: 0
                    )

                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
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
        isRunning ? .green : .gray
    }

    private var statusText: String {
        if isRunning {
            "Rockxy | Listening on \(listenAddress):\(port)"
        } else {
            String(localized: "Rockxy | Not Running")
        }
    }
}
