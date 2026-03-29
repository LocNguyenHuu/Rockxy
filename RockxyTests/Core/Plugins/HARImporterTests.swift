import Foundation
@testable import Rockxy
import Testing

// Regression tests for `HARImporter` in the core plugins layer.

// MARK: - HARImporterTests

struct HARImporterTests {
    // MARK: Internal

    @Test("Imports valid HAR 1.2 JSON")
    func importValidHAR() throws {
        let data = TestFixtures.makeHARJSON(entryCount: 3)
        let transactions = try importer.importData(data)
        #expect(transactions.count == 3)
    }

    @Test("Parses request fields from HAR entry")
    func parsesRequestFields() throws {
        let data = TestFixtures.makeHARJSON(entryCount: 1)
        let transactions = try importer.importData(data)
        let request = transactions[0].request

        #expect(request.method == "GET")
        #expect(request.url.absoluteString == "https://api.example.com/items/0")
        #expect(request.httpVersion == "HTTP/1.1")
        #expect(request.headers.count == 2)
    }

    @Test("Parses response fields from HAR entry")
    func parsesResponseFields() throws {
        let data = TestFixtures.makeHARJSON(entryCount: 1)
        let transactions = try importer.importData(data)
        let response = transactions[0].response

        #expect(response?.statusCode == 200)
        #expect(response?.statusMessage == "OK")
        #expect(response?.headers.count == 1)
        #expect(response?.body != nil)
    }

    @Test("Converts timing ms to seconds")
    func convertsTimingUnits() throws {
        let data = TestFixtures.makeHARJSON(entryCount: 1, includeTimings: true)
        let transactions = try importer.importData(data)
        let timing = transactions[0].timingInfo

        #expect(timing?.dnsLookup == 0.01)
        #expect(timing?.tcpConnection == 0.02)
        #expect(timing?.tlsHandshake == 0.03)
        #expect(timing?.timeToFirstByte == 0.05)
        #expect(timing?.contentTransfer == 0.04)
    }

    @Test("Handles base64 response body")
    func handlesBase64Body() throws {
        let data = TestFixtures.makeHARJSON(entryCount: 1, includeBase64Body: true)
        let transactions = try importer.importData(data)
        let body = transactions[0].response?.body

        #expect(body != nil)
        let text = body.flatMap { String(data: $0, encoding: .utf8) }
        #expect(text == "Hello World")
    }

    @Test("Rejects invalid JSON")
    func rejectsInvalidJSON() throws {
        let badData = "not json".data(using: .utf8)!
        #expect(throws: HARImportError.self) {
            try importer.importData(badData)
        }
    }

    @Test("Rejects missing log key")
    func rejectsMissingLog() throws {
        let noLog: [String: Any] = ["something": "else"]
        let data = try JSONSerialization.data(withJSONObject: noLog)
        #expect(throws: HARImportError.self) {
            try importer.importData(data)
        }
    }

    @Test("Handles entry with no response")
    func handlesNoResponse() throws {
        let harJSON: [String: Any] = [
            "log": [
                "version": "1.2",
                "creator": ["name": "test", "version": "1.0"],
                "entries": [
                    [
                        "startedDateTime": "2025-01-15T10:00:00.000Z",
                        "time": 0,
                        "request": [
                            "method": "GET",
                            "url": "https://example.com/timeout",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "queryString": [] as [[String: Any]],
                            "headersSize": 0,
                            "bodySize": 0
                        ] as [String: Any],
                        "response": [
                            "status": 0,
                            "statusText": "",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "content": ["size": 0, "mimeType": ""] as [String: Any],
                            "redirectURL": "",
                            "headersSize": -1,
                            "bodySize": -1
                        ] as [String: Any],
                        "cache": [String: Any](),
                        "timings": [
                            "dns": -1, "connect": -1, "ssl": -1,
                            "send": 0, "wait": 0, "receive": 0
                        ] as [String: Any]
                    ] as [String: Any]
                ]
            ] as [String: Any]
        ]
        let data = try JSONSerialization.data(withJSONObject: harJSON)
        let transactions = try importer.importData(data)

        #expect(transactions.count == 1)
        #expect(transactions[0].response == nil)
    }

    @Test("All imported transactions are .completed")
    func allTransactionsCompleted() throws {
        let data = TestFixtures.makeHARJSON(entryCount: 5)
        let transactions = try importer.importData(data)

        for transaction in transactions {
            #expect(transaction.state == .completed)
        }
    }

    // MARK: - Request Body Import

    @Test("Imports request postData into request body")
    func importsRequestPostData() throws {
        let data = TestFixtures.makeHARJSONWithPostData(
            body: "{\"username\":\"test\"}", mimeType: "application/json"
        )
        let transactions = try importer.importData(data)
        let request = transactions[0].request

        #expect(request.body != nil)
        let bodyString = request.body.flatMap { String(data: $0, encoding: .utf8) }
        #expect(bodyString == "{\"username\":\"test\"}")
    }

    // MARK: - Validation

    @Test("Rejects unsupported HAR version")
    func rejectsUnsupportedHARVersion() throws {
        let harJSON: [String: Any] = [
            "log": [
                "version": "2.0",
                "creator": ["name": "test", "version": "1.0"],
                "entries": [] as [[String: Any]]
            ] as [String: Any]
        ]
        let data = try JSONSerialization.data(withJSONObject: harJSON)

        #expect(throws: HARImportError.self) {
            try importer.importData(data)
        }
    }

    @Test("Clamps negative timings to zero")
    func clampsNegativeTimingsToZero() throws {
        let harJSON: [String: Any] = [
            "log": [
                "version": "1.2",
                "creator": ["name": "test", "version": "1.0"],
                "entries": [
                    [
                        "startedDateTime": "2025-01-15T10:00:00.000Z",
                        "time": 100.0,
                        "request": [
                            "method": "GET",
                            "url": "https://example.com/api",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "queryString": [] as [[String: Any]],
                            "headersSize": 0,
                            "bodySize": 0
                        ] as [String: Any],
                        "response": [
                            "status": 200,
                            "statusText": "OK",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "content": ["size": 0, "mimeType": ""] as [String: Any],
                            "redirectURL": "",
                            "headersSize": 0,
                            "bodySize": 0
                        ] as [String: Any],
                        "cache": [String: Any](),
                        "timings": [
                            "dns": -1.0,
                            "connect": -1.0,
                            "ssl": -1.0,
                            "send": 0.0,
                            "wait": 50.0,
                            "receive": 40.0
                        ] as [String: Any]
                    ] as [String: Any]
                ]
            ] as [String: Any]
        ]
        let data = try JSONSerialization.data(withJSONObject: harJSON)
        let transactions = try importer.importData(data)
        let timing = try #require(transactions[0].timingInfo)

        #expect(timing.dnsLookup == 0.0)
        #expect(timing.tcpConnection == 0.0)
        #expect(timing.tlsHandshake == 0.0)
    }

    @Test("Rejects entry missing request method")
    func rejectsMissingRequestMethod() throws {
        let harJSON: [String: Any] = [
            "log": [
                "version": "1.2",
                "creator": ["name": "test", "version": "1.0"],
                "entries": [
                    [
                        "startedDateTime": "2025-01-15T10:00:00.000Z",
                        "time": 0,
                        "request": [
                            "url": "https://example.com/api",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "queryString": [] as [[String: Any]],
                            "headersSize": 0,
                            "bodySize": 0
                        ] as [String: Any],
                        "response": [
                            "status": 200, "statusText": "OK",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "content": ["size": 0, "mimeType": ""] as [String: Any],
                            "redirectURL": "", "headersSize": 0, "bodySize": 0
                        ] as [String: Any],
                        "cache": [String: Any]()
                    ] as [String: Any]
                ]
            ] as [String: Any]
        ]
        let data = try JSONSerialization.data(withJSONObject: harJSON)

        #expect(throws: HARImportError.self) {
            try importer.importData(data)
        }
    }

    @Test("Rejects entry missing request URL")
    func rejectsMissingRequestURL() throws {
        let harJSON: [String: Any] = [
            "log": [
                "version": "1.2",
                "creator": ["name": "test", "version": "1.0"],
                "entries": [
                    [
                        "startedDateTime": "2025-01-15T10:00:00.000Z",
                        "time": 0,
                        "request": [
                            "method": "GET",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "queryString": [] as [[String: Any]],
                            "headersSize": 0,
                            "bodySize": 0
                        ] as [String: Any],
                        "response": [
                            "status": 200, "statusText": "OK",
                            "httpVersion": "HTTP/1.1",
                            "headers": [] as [[String: Any]],
                            "cookies": [] as [[String: Any]],
                            "content": ["size": 0, "mimeType": ""] as [String: Any],
                            "redirectURL": "", "headersSize": 0, "bodySize": 0
                        ] as [String: Any],
                        "cache": [String: Any]()
                    ] as [String: Any]
                ]
            ] as [String: Any]
        ]
        let data = try JSONSerialization.data(withJSONObject: harJSON)

        #expect(throws: HARImportError.self) {
            try importer.importData(data)
        }
    }

    @Test("Handles entry with no timings key")
    func handlesEntryWithNoTimings() throws {
        let data = TestFixtures.makeHARJSON(entryCount: 1, includeTimings: false)
        let transactions = try importer.importData(data)

        #expect(transactions[0].timingInfo == nil)
    }

    // MARK: - HAR Round-Trip (Export then Import)

    @Test("HAR round-trip preserves core fields")
    func harRoundTripPreservesCoreFields() throws {
        let bodyData = "{\"user\":\"alice\"}".data(using: .utf8)
        let request = try HTTPRequestData(
            method: "POST",
            url: #require(URL(string: "https://api.example.com/users")),
            httpVersion: "HTTP/1.1",
            headers: [
                HTTPHeader(name: "Content-Type", value: "application/json"),
                HTTPHeader(name: "Authorization", value: "Bearer tok123")
            ],
            body: bodyData,
            contentType: .json
        )
        let transaction = HTTPTransaction(request: request, state: .completed)
        transaction.response = HTTPResponseData(
            statusCode: 201,
            statusMessage: "Created",
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: "{\"id\":1}".data(using: .utf8),
            contentType: .json
        )

        let exporter = HARExporter()
        let harData = try exporter.export(transactions: [transaction])
        let imported = try importer.importData(harData)

        #expect(imported.count == 1)
        let restored = imported[0]
        #expect(restored.request.method == "POST")
        #expect(restored.request.url.absoluteString == "https://api.example.com/users")
        #expect(restored.request.headers.count == 2)
        #expect(restored.response?.statusCode == 201)
        #expect(restored.response?.statusMessage == "Created")

        let restoredBody = restored.request.body.flatMap { String(data: $0, encoding: .utf8) }
        #expect(restoredBody == "{\"user\":\"alice\"}")

        let respBody = restored.response?.body.flatMap { String(data: $0, encoding: .utf8) }
        #expect(respBody == "{\"id\":1}")
    }

    @Test("HAR round-trip drops non-HAR fields")
    func harRoundTripDropsNonHARFields() throws {
        let transaction = TestFixtures.makeGraphQLTransaction()
        transaction.comment = "Debug note"
        transaction.highlightColor = .green
        transaction.isPinned = true

        let exporter = HARExporter()
        let harData = try exporter.export(transactions: [transaction])
        let imported = try importer.importData(harData)

        let restored = imported[0]
        #expect(restored.graphQLInfo == nil)
        #expect(restored.comment == nil)
        #expect(restored.highlightColor == nil)
        #expect(restored.isPinned == false)
    }

    @Test("HAR round-trip preserves timings within tolerance")
    func harRoundTripPreservesTimings() throws {
        let transaction = TestFixtures.makeTransactionWithTiming(
            dns: 0.015, tcp: 0.025, tls: 0.035, ttfb: 0.120, transfer: 0.060
        )

        let exporter = HARExporter()
        let harData = try exporter.export(transactions: [transaction])
        let imported = try importer.importData(harData)

        let timing = try #require(imported[0].timingInfo)
        #expect(abs(timing.dnsLookup - 0.015) < 0.001)
        #expect(abs(timing.tcpConnection - 0.025) < 0.001)
        #expect(abs(timing.tlsHandshake - 0.035) < 0.001)
        #expect(abs(timing.timeToFirstByte - 0.120) < 0.001)
        #expect(abs(timing.contentTransfer - 0.060) < 0.001)
    }

    // MARK: Private

    private let importer = HARImporter()
}
