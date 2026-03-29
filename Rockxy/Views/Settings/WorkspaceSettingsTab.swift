import SwiftUI

/// Placeholder for future workspace/team collaboration settings.
struct WorkspaceSettingsTab: View {
    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "Workspace"), systemImage: "square.grid.2x2")
        } description: {
            Text(
                String(
                    localized:
                    "Team workspace settings for shared session stores, multi-user rules, and workspace profiles."
                )
            )
        } actions: {
            Text(String(localized: "Planned for Future Release"))
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}
