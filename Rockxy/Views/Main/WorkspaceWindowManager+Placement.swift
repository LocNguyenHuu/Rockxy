@preconcurrency import AppKit

// MARK: - RockxyWorkspaceWindowManager Placement

extension RockxyWorkspaceWindowManager {
    func centerAuxiliaryWindowOverPrimary(_ window: NSWindow) {
        guard let primaryWindow, primaryWindow.isVisible else {
            window.center()
            return
        }

        let visibleFrame = primaryWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        let centeredFrame = Self.centeredFrame(
            windowFrame: window.frame,
            parentFrame: primaryWindow.frame,
            visibleFrame: visibleFrame
        )
        window.setFrame(centeredFrame, display: true)
    }

    static func centeredFrame(windowFrame: NSRect, parentFrame: NSRect, visibleFrame: NSRect?) -> NSRect {
        var frame = windowFrame
        frame.origin.x = parentFrame.midX - frame.width / 2
        frame.origin.y = parentFrame.midY - frame.height / 2

        guard let visibleFrame else {
            return frame
        }

        frame.origin.x = min(max(frame.minX, visibleFrame.minX), visibleFrame.maxX - frame.width)
        frame.origin.y = min(max(frame.minY, visibleFrame.minY), visibleFrame.maxY - frame.height)
        return frame
    }
}
