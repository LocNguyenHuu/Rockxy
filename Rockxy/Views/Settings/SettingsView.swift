import SwiftUI

// Root settings window using macOS native tab-based layout.
// Each tab is a self-contained settings pane with its own `@AppStorage` bindings.

// MARK: - SettingsView

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label(String(localized: "General"), systemImage: "gear")
                }

            WorkspaceSettingsTab()
                .tabItem {
                    Label(String(localized: "Workspace"), systemImage: "person.2")
                }

            AppearanceSettingsTab()
                .tabItem {
                    Label(String(localized: "Appearance"), systemImage: "sparkles")
                }

            PrivacySettingsTab()
                .tabItem {
                    Label(String(localized: "Privacy"), systemImage: "person.badge.shield.checkmark")
                }

            ToolsSettingsTab()
                .tabItem {
                    Label(String(localized: "Tools"), systemImage: "wrench.and.screwdriver")
                }

            GitHubSettingsTab()
                .tabItem {
                    Label(String(localized: "GitHub"), systemImage: "chevron.left.forwardslash.chevron.right")
                }

            // PlatformSettingsTab hidden for Community edition
            // PlatformSettingsTab()
            //     .tabItem {
            //         Label(String(localized: "Platform"), systemImage: "display")
            //     }

            MCPSettingsTab()
                .tabItem {
                    Label(String(localized: "MCP"), systemImage: "server.rack")
                }

            PluginsSettingsTab()
                .tabItem {
                    Label(String(localized: "Plugins"), systemImage: "puzzlepiece.extension")
                }

            AdvancedSettingsTab()
                .tabItem {
                    Label(String(localized: "Advanced"), systemImage: "ellipsis.circle")
                }
        }
        .frame(width: 820, height: 600)
    }
}
