import Foundation

/// Thread-safe container for a WebSocket connection's upgrade request and captured frames.
/// Marked `@unchecked Sendable` because frame access is serialized through an `NSLock`.
final class WebSocketConnection: @unchecked Sendable {
    // MARK: Lifecycle

    init(upgradeRequest: HTTPRequestData, frames: [WebSocketFrameData] = []) {
        self.upgradeRequest = upgradeRequest
        self._frames = frames
    }

    // MARK: Internal

    let upgradeRequest: HTTPRequestData

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
        lock.withLock { _frames.append(frame) }
    }

    // MARK: Private

    private let lock = NSLock()
    private var _frames: [WebSocketFrameData]
}
