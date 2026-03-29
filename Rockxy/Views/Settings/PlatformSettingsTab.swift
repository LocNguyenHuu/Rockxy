import SwiftUI

/// Platform availability settings — not yet implemented.
struct PlatformSettingsTab: View {
    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "Platform & Device"), systemImage: "desktopcomputer")
        } description: {
            Text(
                String(
                    localized:
                    "Configure iOS Simulator, Android emulator, and remote device traffic capture settings."
                )
            )
        } actions: {
            Text(String(localized: "Planned for Future Release"))
                .font(.caption)
                .foregroundStyle(.orange)
        }
    }
}
