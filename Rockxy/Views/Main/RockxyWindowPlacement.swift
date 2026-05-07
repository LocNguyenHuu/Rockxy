import AppKit
import SwiftUI

// MARK: - Rockxy Window Placement

extension View {
    func centerOverRockxyMainWindowOnAppear() -> some View {
        background {
            RockxyAuxiliaryWindowCenteringAccessor()
                .frame(width: 0, height: 0)
        }
    }
}

private struct RockxyAuxiliaryWindowCenteringAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> RockxyAuxiliaryWindowCenteringView {
        RockxyAuxiliaryWindowCenteringView()
    }

    func updateNSView(_ nsView: RockxyAuxiliaryWindowCenteringView, context: Context) {
        nsView.centerIfReady()
    }
}

@MainActor
private final class RockxyAuxiliaryWindowCenteringView: NSView {
    private var didCenter = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        centerIfReady()
    }

    func centerIfReady() {
        guard !didCenter,
              let window else {
            return
        }
        didCenter = true
        DispatchQueue.main.async {
            RockxyWorkspaceWindowManager.shared.centerAuxiliaryWindowOverPrimary(window)
        }
    }
}
