import SwiftUI

/// Convenience extension for conditionally applying a keyboard shortcut.
/// Used when a shortcut binding may be nil (e.g., platform-specific shortcuts).
extension View {
    @ViewBuilder
    func optionalKeyboardShortcut(_ shortcut: KeyboardShortcut?) -> some View {
        if let shortcut {
            self.keyboardShortcut(shortcut)
        } else {
            self
        }
    }
}
