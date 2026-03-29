import SwiftUI

// Renders the breakpoint rule row used by breakpoint review and editing.

// MARK: - BreakpointRuleRow

/// A single row in the breakpoint rules section of the sidebar.
/// Displays the phase badge, rule name, URL pattern, and enabled/disabled indicator.
struct BreakpointRuleRow: View {
    // MARK: Internal

    let rule: ProxyRule
    let isSelected: Bool
    var onToggle: ((UUID) -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            phaseBadge
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.caption)
                    .lineLimit(1)
                Text(rule.matchCondition.urlPattern ?? "")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                onToggle?(rule.id)
            } label: {
                Circle()
                    .fill(rule.isEnabled ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .listRowBackground(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
    }

    // MARK: Private

    private var phaseBadge: some View {
        let label: String = {
            if case let .breakpoint(phase) = rule.action {
                switch phase {
                case .request: return "REQ"
                case .response: return "RES"
                case .both: return "ALL"
                }
            }
            return "?"
        }()
        return Text(label)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Color.purple, in: Capsule())
    }
}
