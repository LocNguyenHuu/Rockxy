import Foundation

// Defines `PluginInfo`, the model for plugin used by plugin discovery and settings.

// MARK: - PluginInfo

/// UI-facing model combining a plugin's manifest with its runtime state.
/// Used by the Settings UI to display plugin details and enable/disable toggles.
struct PluginInfo: Identifiable {
    let id: String
    let manifest: PluginManifest
    let bundlePath: URL
    var isEnabled: Bool
    var status: PluginStatus
    var lastError: String?

    /// Whether this is a built-in plugin shipped with Rockxy (not user-installed).
    var isBuiltIn: Bool {
        manifest.author.name == "Rockxy"
    }

    /// Display-friendly status text for the plugin list subtitle.
    var statusText: String {
        switch status {
        case .active:
            "Active"
        case .disabled:
            "Disabled"
        case .error:
            "Error"
        case .loading:
            "Loading…"
        }
    }
}

// MARK: - PluginStatus

enum PluginStatus: Equatable {
    case active
    case disabled
    case error(String)
    case loading
}
