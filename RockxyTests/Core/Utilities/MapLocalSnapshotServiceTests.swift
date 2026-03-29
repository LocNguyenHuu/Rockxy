import Foundation
@testable import Rockxy
import Testing

// Regression tests for `MapLocalSnapshotService` in the core utilities layer.

struct MapLocalSnapshotServiceTests {
    @Test("JSON response body saves as .json file")
    func jsonSnapshot() throws {
        let body = "{\"users\": []}".data(using: .utf8)!
        let result = MapLocalSnapshotService.saveSnapshot(
            responseBody: body,
            contentType: "application/json",
            requestURL: URL(string: "https://api.example.com/v2/users")
        )

        #expect(result != nil)
        #expect(try #require(result?.path.hasSuffix(".json")))
        #expect(result?.mimeType == "application/json")

        let savedData = try Data(contentsOf: URL(fileURLWithPath: #require(result?.path)))
        #expect(savedData == body)

        try? FileManager.default.removeItem(atPath: try #require(result?.path))
    }

    @Test("Binary response body saves with inferred extension")
    func binarySnapshot() throws {
        let body = Data([0x89, 0x50, 0x4E, 0x47])
        let result = MapLocalSnapshotService.saveSnapshot(
            responseBody: body,
            contentType: "image/png",
            requestURL: URL(string: "https://example.com/icon")
        )

        #expect(result != nil)
        #expect(try #require(result?.path.hasSuffix(".png")))
        #expect(result?.mimeType == "image/png")

        try? FileManager.default.removeItem(atPath: try #require(result?.path))
    }

    @Test("Nil body returns nil")
    func nilBody() {
        let result = MapLocalSnapshotService.saveSnapshot(
            responseBody: nil,
            contentType: "application/json",
            requestURL: URL(string: "https://example.com/data")
        )
        #expect(result == nil)
    }

    @Test("Empty body returns nil")
    func emptyBody() {
        let result = MapLocalSnapshotService.saveSnapshot(
            responseBody: Data(),
            contentType: "application/json",
            requestURL: URL(string: "https://example.com/data")
        )
        #expect(result == nil)
    }

    @Test("Extension inferred from URL when Content-Type is unknown")
    func extensionFromURL() throws {
        let body = "test".data(using: .utf8)!
        let result = MapLocalSnapshotService.saveSnapshot(
            responseBody: body,
            contentType: "application/x-custom",
            requestURL: URL(string: "https://example.com/data.csv")
        )

        #expect(result != nil)
        #expect(try #require(result?.path.hasSuffix(".csv")))

        try? FileManager.default.removeItem(atPath: try #require(result?.path))
    }

    @Test("Falls back to .bin when no extension can be inferred")
    func fallbackExtension() throws {
        let body = "test".data(using: .utf8)!
        let result = MapLocalSnapshotService.saveSnapshot(
            responseBody: body,
            contentType: nil,
            requestURL: URL(string: "https://example.com/data")
        )

        #expect(result != nil)
        #expect(try #require(result?.path.hasSuffix(".bin")))

        try? FileManager.default.removeItem(atPath: try #require(result?.path))
    }

    @Test("expectedSnapshotPath returns path without writing")
    func expectedPath() {
        let path = MapLocalSnapshotService.expectedSnapshotPath(
            contentType: "application/json",
            requestURL: URL(string: "https://api.example.com/users")
        )
        #expect(path.contains("snapshots"))
        #expect(path.contains(".json"))
        #expect(path.contains("users"))
    }
}
