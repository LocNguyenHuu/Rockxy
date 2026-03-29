import Foundation
import os

// Extends `MainContentCoordinator` with logs behavior for the main workspace.

// MARK: - MainContentCoordinator + Logs

/// Coordinator extension for OSLog and process log capture lifecycle. Incoming log entries
/// are correlated with network transactions by timestamp and process, then appended to the
/// in-memory buffer with overflow eviction based on `maxLogBufferSize`.
extension MainContentCoordinator {
    // MARK: - Log Capture Lifecycle

    func startLogCapture() {
        Self.logger.info("Starting log capture")
        Task {
            await logEngine.setOnLogEntry { [weak self] entry in
                guard let self else {
                    return
                }
                Task { @MainActor in
                    self.addLogEntry(entry)
                }
            }

            await logEngine.startCapture()
            Self.logger.info("Log capture started")
        }
    }

    func stopLogCapture() {
        Task {
            await logEngine.stopCapture()
            Self.logger.info("Log capture stopped")
        }
    }

    // MARK: - Log Entry Processing

    func addLogEntry(_ entry: LogEntry) {
        guard isRecording else {
            return
        }

        var mutableEntry = entry
        let settings = AppSettingsStorage.load()

        if let correlatedId = LogCorrelator.correlate(
            logEntry: entry,
            with: transactions
        ) {
            mutableEntry.correlatedTransactionId = correlatedId
        }

        logEntries.append(mutableEntry)

        if logEntries.count > settings.maxLogBufferSize {
            let excess = logEntries.count - settings.maxLogBufferSize
            logEntries.removeFirst(excess)
            Self.logger.debug("Evicted \(excess) oldest log entries")
        }
    }
}
