import AppKit

// Resolves the app icon used in alerts and other AppKit surfaces.

// MARK: - AppIconProvider

enum AppIconProvider {
    static var appIcon: NSImage {
        let icon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        icon.isTemplate = false
        return icon
    }
}
