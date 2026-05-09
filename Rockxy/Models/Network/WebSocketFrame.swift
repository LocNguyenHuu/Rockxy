import Foundation

// Defines `WebSocketFrame`, the model for web socket frame used by proxy, storage, and
// inspection flows.

// MARK: - WebSocketFrameData

/// A single captured WebSocket frame with direction, opcode, and raw payload.
/// Displayed in the WebSocket inspector tab as a chronological message log.
struct WebSocketFrameData: Identifiable, Sendable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        direction: FrameDirection,
        opcode: FrameOpcode,
        payload: Data,
        isFinal: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.direction = direction
        self.opcode = opcode
        self.payload = payload
        self.isFinal = isFinal
    }

    // MARK: Internal

    let id: UUID
    let timestamp: Date
    let direction: FrameDirection
    let opcode: FrameOpcode
    let payload: Data
    let isFinal: Bool
}

// MARK: - FrameDirection

/// Whether a WebSocket frame was sent by the client or received from the server.
enum FrameDirection: String, Sendable {
    case sent
    case received
}

// MARK: - FrameOpcode

/// WebSocket frame opcodes as defined in RFC 6455 Section 5.2.
enum FrameOpcode: UInt8, Sendable {
    case continuation = 0
    case text = 1
    case binary = 2
    case connectionClose = 8
    case ping = 9
    case pong = 10
}
