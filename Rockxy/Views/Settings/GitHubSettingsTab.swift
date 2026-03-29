import SwiftUI

/// GitHub integration settings — not yet implemented.
struct GitHubSettingsTab: View {
    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "GitHub Integration"), systemImage: "arrow.triangle.branch")
        } description: {
            Text(
                String(
                    localized:
                    "Share captured sessions, export reports, and sync rules with GitHub repositories."
                )
            )
        } actions: {
            Text(String(localized: "Planned for Future Release"))
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}
