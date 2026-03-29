import Foundation

// Defines the UI model for transient in-app notifications.

// MARK: - ToastStyle

/// Visual style for transient toast notifications.
enum ToastStyle {
    case success
    case error
}

// MARK: - ToastMessage

/// Transient notification displayed as a bottom overlay, auto-dismissed after a few seconds.
struct ToastMessage: Identifiable {
    let id = UUID()
    let style: ToastStyle
    let text: String
}
