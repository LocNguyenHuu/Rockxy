import Foundation
@testable import Rockxy
import Testing

// Regression tests for `WebSocketConnection` in the models layer.

struct WebSocketConnectionTests {
    @Test("addFrame appends to frames array")
    func addFrame() throws {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        #expect(connection.frameCount == 0)

        let frame = try WebSocketFrameData(
            direction: .sent,
            opcode: .text,
            payload: #require("hello".data(using: .utf8))
        )
        connection.addFrame(frame)

        #expect(connection.frameCount == 1)
        #expect(connection.frames[0].direction == .sent)
        #expect(connection.frames[0].payload == "hello".data(using: .utf8)!)
    }

    @Test("sentFrames filters to sent direction only")
    func sentFrames() {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        connection.addFrame(WebSocketFrameData(direction: .sent, opcode: .text, payload: Data()))
        connection.addFrame(WebSocketFrameData(direction: .received, opcode: .text, payload: Data()))
        connection.addFrame(WebSocketFrameData(direction: .sent, opcode: .text, payload: Data()))

        #expect(connection.sentFrames.count == 2)
        #expect(connection.receivedFrames.count == 1)
    }

    @Test("receivedFrames filters to received direction only")
    func receivedFrames() {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        connection.addFrame(WebSocketFrameData(direction: .received, opcode: .binary, payload: Data([0x01, 0x02])))
        connection.addFrame(WebSocketFrameData(direction: .received, opcode: .text, payload: Data()))
        connection.addFrame(WebSocketFrameData(direction: .sent, opcode: .ping, payload: Data()))

        #expect(connection.receivedFrames.count == 2)
        #expect(connection.sentFrames.count == 1)
    }

    @Test("frameCount matches total frames added")
    func frameCount() throws {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        for i in 0 ..< 10 {
            try connection.addFrame(WebSocketFrameData(
                direction: i % 2 == 0 ? .sent : .received,
                opcode: .text,
                payload: #require("msg\(i)".data(using: .utf8))
            ))
        }
        #expect(connection.frameCount == 10)
        #expect(connection.sentFrames.count == 5)
        #expect(connection.receivedFrames.count == 5)
    }

    @Test("concurrent addFrame calls preserve all frames")
    func threadSafety() async {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)

        await withTaskGroup(of: Void.self) { group in
            for i in 0 ..< 100 {
                group.addTask {
                    let frame = WebSocketFrameData(
                        direction: i % 2 == 0 ? .sent : .received,
                        opcode: .text,
                        payload: "frame\(i)".data(using: .utf8)!
                    )
                    connection.addFrame(frame)
                }
            }
        }

        #expect(connection.frameCount == 100)
    }

    @Test("empty connection has zero frames and counts")
    func emptyConnection() {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        #expect(connection.frames.isEmpty)
        #expect(connection.frameCount == 0)
        #expect(connection.sentFrames.isEmpty)
        #expect(connection.receivedFrames.isEmpty)
    }

    @Test("upgradeRequest preserved correctly")
    func upgradeRequestPreserved() {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws/v2")
        let connection = WebSocketConnection(upgradeRequest: request)
        #expect(connection.upgradeRequest.url.absoluteString == "wss://example.com/ws/v2")
    }

    @Test("binary frame payloads preserved exactly")
    func binaryPayloadPreserved() {
        let request = TestFixtures.makeRequest(url: "wss://example.com/ws")
        let connection = WebSocketConnection(upgradeRequest: request)
        let binaryData = Data([0x00, 0xFF, 0x89, 0x50, 0x4E, 0x47])
        connection.addFrame(WebSocketFrameData(
            direction: .received, opcode: .binary, payload: binaryData
        ))
        #expect(connection.frames[0].payload == binaryData)
        #expect(connection.frames[0].opcode == .binary)
    }
}
