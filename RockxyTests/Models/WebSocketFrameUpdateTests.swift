import Foundation
@testable import Rockxy
import Testing

/// Tests for the observable bridge between WebSocketConnection frame mutations
/// and HTTPTransaction's @Observable frame version counter.
/// These test the model-level update mechanism, NOT the NIO handler pipeline.
struct WebSocketFrameUpdateTests {
    @Test("addFrame increments connection frame count")
    func addFrameIncrementsCount() throws {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        #expect(connection.frameCount == 0)

        try connection.addFrame(WebSocketFrameData(
            direction: .sent, opcode: .text, payload: #require("hello".data(using: .utf8))
        ))
        #expect(connection.frameCount == 1)

        try connection.addFrame(WebSocketFrameData(
            direction: .received, opcode: .text, payload: #require("world".data(using: .utf8))
        ))
        #expect(connection.frameCount == 2)
    }

    @Test("webSocketFrameVersion is independently writable on HTTPTransaction")
    func versionIndependentlyWritable() {
        let transaction = TestFixtures.makeWebSocketTransaction()
        #expect(transaction.webSocketFrameVersion == 0)

        transaction.webSocketFrameVersion += 1
        #expect(transaction.webSocketFrameVersion == 1)

        transaction.webSocketFrameVersion += 1
        #expect(transaction.webSocketFrameVersion == 2)
    }

    @Test("Frame version bump simulates MainActor dispatch from handler")
    func versionBumpSimulatesDispatch() throws {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        let transaction = HTTPTransaction(
            request: request, state: .active, webSocketConnection: connection
        )

        #expect(transaction.webSocketFrameVersion == 0)
        #expect(connection.frameCount == 0)

        // Simulate what WebSocketFrameHandler.captureFrame does:
        // 1. Add frame to connection (on NIO thread)
        try connection.addFrame(WebSocketFrameData(
            direction: .received, opcode: .text, payload: #require("msg1".data(using: .utf8))
        ))
        // 2. Bump version (on MainActor, simulated here)
        transaction.webSocketFrameVersion += 1

        #expect(connection.frameCount == 1)
        #expect(transaction.webSocketFrameVersion == 1)

        // Second frame
        try connection.addFrame(WebSocketFrameData(
            direction: .sent, opcode: .text, payload: #require("msg2".data(using: .utf8))
        ))
        transaction.webSocketFrameVersion += 1

        #expect(connection.frameCount == 2)
        #expect(transaction.webSocketFrameVersion == 2)
    }

    @Test("Frame data accessible through transaction after version bump")
    func frameDataAccessibleAfterBump() throws {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        let transaction = HTTPTransaction(
            request: request, state: .active, webSocketConnection: connection
        )

        connection.addFrame(WebSocketFrameData(
            direction: .received, opcode: .binary, payload: Data([0xFF, 0x00, 0xAB])
        ))
        transaction.webSocketFrameVersion += 1

        let frames = try #require(transaction.webSocketConnection?.frames)
        #expect(frames.count == 1)
        #expect(frames[0].direction == .received)
        #expect(frames[0].opcode == .binary)
        #expect(frames[0].payload == Data([0xFF, 0x00, 0xAB]))
    }

    @Test("Sent and received counts update correctly through bridge")
    func sentReceivedCountsUpdateThroughBridge() throws {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        let transaction = HTTPTransaction(
            request: request, state: .active, webSocketConnection: connection
        )

        for i in 0 ..< 10 {
            try connection.addFrame(WebSocketFrameData(
                direction: i % 3 == 0 ? .sent : .received,
                opcode: .text,
                payload: #require("frame\(i)".data(using: .utf8))
            ))
            transaction.webSocketFrameVersion += 1
        }

        #expect(transaction.webSocketFrameVersion == 10)
        #expect(connection.frameCount == 10)
        #expect(connection.sentFrames.count == 4) // i=0,3,6,9
        #expect(connection.receivedFrames.count == 6)
    }
}
