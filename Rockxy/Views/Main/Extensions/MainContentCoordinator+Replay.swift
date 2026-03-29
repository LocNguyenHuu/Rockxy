import Foundation
import os

// Extends `MainContentCoordinator` with replay behavior for the main workspace.

// MARK: - MainContentCoordinator + Replay

/// Coordinator extension for replaying captured HTTP requests against the original server.
extension MainContentCoordinator {
    // MARK: - Request Replay

    func replaySelectedRequest() {
        guard let transaction = selectedTransaction else {
            return
        }
        Task {
            do {
                let response = try await RequestReplay.replay(transaction.request)
                Self.logger.info("Replay completed: \(response.statusCode)")
            } catch {
                Self.logger.error("Replay failed: \(error.localizedDescription)")
            }
        }
    }

    func editAndReplaySelectedRequest() {
        guard let transaction = selectedTransaction else {
            return
        }
        editAndReplayTransaction(transaction)
    }
}
