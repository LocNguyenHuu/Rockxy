import Foundation
import os

// Extends `MainContentCoordinator` with bandwidth behavior for the main workspace.

// MARK: - MainContentCoordinator + Bandwidth

/// Coordinator extension for live bandwidth metering: tracks cumulative upload/download
/// byte totals and computes instantaneous throughput rates over a 1-second sliding window.
/// A repeating timer (250ms) decays stale samples so the footer speed indicators drop
/// to zero when traffic stops.
extension MainContentCoordinator {
    // MARK: - Batch Recording

    func recordTrafficMetrics(for batch: [HTTPTransaction], at now: Date = Date()) {
        guard !batch.isEmpty else {
            return
        }

        var batchUpload: Int64 = 0
        var batchDownload: Int64 = 0

        for tx in batch {
            let bytes = Self.extractBytes(from: tx)
            batchUpload += bytes.upload
            batchDownload += bytes.download
        }

        totalUploadBytes += batchUpload
        totalDownloadBytes += batchDownload
        totalDataSize = totalUploadBytes + totalDownloadBytes

        trafficSamples.append((timestamp: now, upload: batchUpload, download: batchDownload))
        recomputeInstantaneousSpeeds(now: now)
    }

    // MARK: - Instantaneous Speed

    func recomputeInstantaneousSpeeds(now: Date = Date()) {
        let windowStart = now.addingTimeInterval(-1.0)
        trafficSamples.removeAll { $0.timestamp < windowStart }

        guard !trafficSamples.isEmpty else {
            uploadSpeed = 0
            downloadSpeed = 0
            return
        }

        // Sum bytes in the 1-second window. Since the window is always 1s,
        // total bytes in window = bytes/second (no division needed).
        uploadSpeed = trafficSamples.reduce(Int64(0)) { $0 + $1.upload }
        downloadSpeed = trafficSamples.reduce(Int64(0)) { $0 + $1.download }
    }

    // MARK: - Reset

    func resetTrafficMetrics() {
        totalUploadBytes = 0
        totalDownloadBytes = 0
        totalDataSize = 0
        uploadSpeed = 0
        downloadSpeed = 0
        trafficSamples.removeAll()
    }

    func resetInstantaneousSpeeds() {
        uploadSpeed = 0
        downloadSpeed = 0
        trafficSamples.removeAll()
    }

    // MARK: - Timer

    func startBandwidthTimer() {
        bandwidthTimer?.invalidate()
        bandwidthTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recomputeInstantaneousSpeeds()
            }
        }
    }

    func stopBandwidthTimer() {
        bandwidthTimer?.invalidate()
        bandwidthTimer = nil
    }

    // MARK: - Byte Extraction

    static func extractBytes(from tx: HTTPTransaction) -> (upload: Int64, download: Int64) {
        var upload = Int64(tx.request.body?.count ?? 0)
        var download = Int64(tx.response?.body?.count ?? 0)

        if let ws = tx.webSocketConnection {
            for frame in ws.frames {
                let size = Int64(frame.payload.count)
                if frame.direction == .sent {
                    upload += size
                } else {
                    download += size
                }
            }
        }

        return (upload, download)
    }

    // MARK: - Rebuild from Existing Transactions

    func rebuildTrafficTotals(from transactions: [HTTPTransaction]) {
        var upload: Int64 = 0
        var download: Int64 = 0

        for tx in transactions {
            let bytes = Self.extractBytes(from: tx)
            upload += bytes.upload
            download += bytes.download
        }

        totalUploadBytes = upload
        totalDownloadBytes = download
        totalDataSize = upload + download
    }
}
