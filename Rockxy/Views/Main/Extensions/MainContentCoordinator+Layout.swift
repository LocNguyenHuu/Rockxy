import Foundation

// Extends `MainContentCoordinator` with layout behavior for the main workspace.

// MARK: - MainContentCoordinator + Layout

/// Coordinator extension for inspector panel layout toggling (right, bottom, hidden).
extension MainContentCoordinator {
    // MARK: - Inspector Layout

    func toggleInspectorRight() {
        inspectorLayout = (inspectorLayout == .right) ? .hidden : .right
    }

    func toggleInspectorBottom() {
        inspectorLayout = (inspectorLayout == .bottom) ? .hidden : .bottom
    }
}
