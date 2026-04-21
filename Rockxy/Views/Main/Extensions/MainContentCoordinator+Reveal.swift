import AppKit
import Foundation

// MARK: - MainContentCoordinator + Reveal

extension MainContentCoordinator {
    func revealTransaction(id: UUID) {
        guard let transaction = transaction(for: id) else {
            return
        }

        let window = NSApp.mainWindow
            ?? NSApp.keyWindow
            ?? NSApp.windows.first(where: { $0.canBecomeKey && $0.isVisible })
            ?? NSApp.windows.first(where: { $0.canBecomeKey })

        NSApp.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
        }

        filterCriteria = .empty
        sidebarSelection = nil
        activeMainTab = .traffic
        recomputeFilteredTransactions()
        selectTransaction(transaction)
    }
}
