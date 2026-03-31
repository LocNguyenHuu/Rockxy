import Foundation

/// Thread-safe container for a WebSocket connection's upgrade request and captured frames.
/// Marked `@unchecked Sendable` because frame access is serialized through an `NSLock`.
final class WebSocketConnection: @unchecked Sendable {
    // MARK: Lifecycle

    init(upgradeRequest: HTTPRequestData, frames: [WebSocketFrameData] = []) {
        self.upgradeRequest = upgradeRequest
        self._frames = frames
        self.totalPayloadSize = frames.reduce(0) { $0 + $1.payload.count }
    }

    // MARK: Internal

    let upgradeRequest: HTTPRequestData

    private(set) var totalPayloadSize: Int = 0

    var frames: [WebSocketFrameData] {
        lock.withLock { _frames }
    }

    var frameCount: Int {
        lock.withLock { _frames.count }
    }

    var sentFrames: [WebSocketFrameData] {
        lock.withLock { _frames.filter { $0.direction == .sent } }
    }

    var receivedFrames: [WebSocketFrameData] {
        lock.withLock { _frames.filter { $0.direction == .received } }
    }

    func addFrame(_ frame: WebSocketFrameData) {
        lock.withLock {
            _frames.append(frame)
            totalPayloadSize += frame.payload.count
        }
    }

    // MARK: Private

    private let lock = NSLock()
    private var _frames: [WebSocketFrameData]
}
