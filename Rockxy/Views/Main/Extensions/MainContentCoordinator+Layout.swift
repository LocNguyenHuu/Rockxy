import SwiftUI

// Extends `MainContentCoordinator` with layout behavior for the main workspace.

// MARK: - MainContentCoordinator + Layout

/// Coordinator extension for inspector panel layout toggling (right, bottom, hidden).
extension MainContentCoordinator {
    // MARK: - Inspector Layout

    func toggleInspectorRight() {
        withAnimation(.smooth(duration: 0.18)) {
            inspectorLayout = (inspectorLayout == .right) ? .hidden : .right
        }
    }

    func toggleInspectorBottom() {
        withAnimation(.smooth(duration: 0.18)) {
            inspectorLayout = (inspectorLayout == .bottom) ? .hidden : .bottom
        }
    }
}
