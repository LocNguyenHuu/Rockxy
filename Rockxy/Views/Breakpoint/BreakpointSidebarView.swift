import SwiftUI

// Renders the breakpoint sidebar interface for breakpoint review and editing.

// MARK: - BreakpointSidebarView

/// Left panel of the Breakpoints window showing breakpoint rules and paused items.
/// Two sections: Rules (breakpoint-type rules) and Paused (items awaiting user decision).
struct BreakpointSidebarView: View {
    // MARK: Internal

    let windowModel: BreakpointWindowModel
    let manager: BreakpointManager

    var body: some View {
        VStack(spacing: 0) {
            if manager.pausedItems.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "pause.circle")
                        .font(.title2).foregroundStyle(.secondary)
                    Text(String(localized: "No paused items."))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(String(localized: "Manage breakpoint rules from Tools → Breakpoint Rules."))
                        .font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section(header: pausedSectionHeader) {
                        ForEach(manager.pausedItems) { item in
                            BreakpointQueueRow(item: item)
                                .contentShape(Rectangle())
                                .onTapGesture { windowModel.selectPausedItem(item.id) }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Private

    /// Returns a SwiftUI `Text` header for the paused items section.
    /// The string is an inline inflect-able localized literal using the
    /// `^[…](inflect: true)` markdown form, so the noun phrase `paused item`
    /// automatically resolves to the correct singular/plural form at runtime
    /// based on `count`. The integer count is a first-class argument that
    /// localizers can reorder per locale.
    private var pausedSectionHeader: Text {
        let count = manager.pausedItems.count
        return Text(
            "^[\(count) paused item](inflect: true)",
            comment: "Section header showing how many paused items are in the breakpoint queue"
        )
    }
}
