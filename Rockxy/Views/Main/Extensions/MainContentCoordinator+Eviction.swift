import Foundation
import os

// Extends `MainContentCoordinator` with eviction behavior for the main workspace.

// MARK: - MainContentCoordinator + Eviction

extension MainContentCoordinator {
    func evictOldestTransactions(count: Int) {
        guard count > 0, !transactions.isEmpty else {
            return
        }
        let removeCount = min(count, transactions.count)
        let removedIDs = Set(transactions.prefix(removeCount).map(\.id))

        transactions.removeFirst(removeCount)
        rebuildObservedDomainsByApp()
        evictFromAllWorkspaces(removedIDs: removedIDs)

        Self.logger.info("Evicted \(removeCount) oldest transactions (remaining: \(self.transactions.count))")
    }

    func rebuildSidebarIndexes() {
        rebuildSidebarIndexes(for: activeWorkspace)
    }
}
