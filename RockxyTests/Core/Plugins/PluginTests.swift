import Foundation
@testable import Rockxy
import Testing

// Tests for the plugin system: `HARExporter` (HAR 1.2 JSON structure, entry counts,
// timing unit conversion, missing response handling) and `PluginManager` (built-in
// plugin registration, inspector/exporter lookup).

// MARK: - PluginTests

struct PluginTests {
    // MARK: - HARExporter Tests

    @Test("HARExporter produces valid HAR 1.2 JSON structure")
    func harExporterStructure() throws {
        let exporter = HARExporter()
        let transaction = TestFixtures.makeTransactionWithTiming()
        let data = try exporter.export(transactions: [transaction])

        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let log = try #require(json["log"] as? [String: Any])

        #expect(log["version"] as? String == "1.2")

        let creator = try #require(log["creator"] as? [String: Any])
        #expect(creator["name"] as? String == "Rockxy")

        let entries = try #require(log["entries"] as? [[String: Any]])
        #expect(!entries.isEmpty)
    }

    @Test("HARExporter entry count matches transaction count")
    func harExporterEntryCount() throws {
        let exporter = HARExporter()
        let transactions = [
            TestFixtures.makeTransaction(),
            TestFixtures.makeTransaction(),
            TestFixtures.makeTransaction()
        ]

        let data = try exporter.export(transactions: transactions)
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let log = try #require(json["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])

        #expect(entries.count == 3)
    }

    @Test("HARExporter timing values are in milliseconds")
    func harExporterTimingsInMilliseconds() throws {
        let exporter = HARExporter()
        let transaction = TestFixtures.makeTransactionWithTiming(
            dns: 0.01, tcp: 0.02, tls: 0.03, ttfb: 0.1, transfer: 0.05
        )

        let data = try exporter.export(transactions: [transaction])
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let log = try #require(json["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])
        let entry = try #require(entries.first)
        let timings = try #require(entry["timings"] as? [String: Any])

        let dns = try #require(timings["dns"] as? Double)
        let connect = try #require(timings["connect"] as? Double)
        let ssl = try #require(timings["ssl"] as? Double)

        #expect(abs(dns - 10.0) < 0.01)
        #expect(abs(connect - 20.0) < 0.01)
        #expect(abs(ssl - 30.0) < 0.01)
    }

    @Test("HARExporter handles missing response without crashing")
    func harExporterMissingResponse() throws {
        let exporter = HARExporter()
        let request = TestFixtures.makeRequest()
        let transaction = HTTPTransaction(request: request, state: .pending)

        let data = try exporter.export(transactions: [transaction])
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let log = try #require(json["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])

        #expect(entries.count == 1)

        let entry = entries[0]
        let response = try #require(entry["response"] as? [String: Any])
        #expect(response["status"] as? Int == 0)
    }

    // MARK: - PluginManager Tests

    @Test("PluginManager loadPlugins registers built-in plugins")
    func loadPluginsRegistersBuiltIns() {
        let manager = PluginManager()
        manager.loadPlugins()

        let exporters = manager.allExporters()
        #expect(!exporters.isEmpty)
    }

    @Test("PluginManager inspectorPlugin for .json returns JSONInspector")
    func inspectorPluginForJSON() {
        let manager = PluginManager()
        manager.loadPlugins()

        let plugin = manager.inspectorPlugin(for: .json)

        #expect(plugin != nil)
        #expect(plugin?.name == "JSON Inspector")
    }

    @Test("PluginManager inspectorPlugin for .image returns nil")
    func inspectorPluginForImageReturnsNil() {
        let manager = PluginManager()
        manager.loadPlugins()

        let plugin = manager.inspectorPlugin(for: .image)

        #expect(plugin == nil)
    }

    @Test("PluginManager allExporters returns HARExporter after loadPlugins")
    func allExportersIncludesHAR() {
        let manager = PluginManager()
        manager.loadPlugins()

        let exporters = manager.allExporters()
        let harExporter = exporters.first { $0.name == "HAR Exporter" }

        #expect(harExporter != nil)
        #expect(harExporter?.fileExtension == "har")
    }

    // MARK: - HARExporter Body Encoding Tests

    @Test("HARExporter binary response body uses base64 encoding")
    func harExporterBinaryBodyUsesBase64() throws {
        let exporter = HARExporter()
        let pngHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        let transaction = TestFixtures.makeTransaction()
        transaction.response = TestFixtures.makeResponse(
            statusCode: 200,
            headers: [HTTPHeader(name: "Content-Type", value: "image/png")],
            body: pngHeader
        )
        transaction.response?.contentType = .image

        let data = try exporter.export(transactions: [transaction])
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let log = try #require(json["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])
        let entry = try #require(entries.first)
        let response = try #require(entry["response"] as? [String: Any])
        let content = try #require(response["content"] as? [String: Any])

        #expect(content["encoding"] as? String == "base64")
        #expect(content["text"] as? String == pngHeader.base64EncodedString())
    }

    @Test("HARExporter text response body omits encoding field")
    func harExporterTextBodyOmitsEncoding() throws {
        let exporter = HARExporter()
        let jsonBody = "{\"status\":\"ok\"}".data(using: .utf8)!
        let transaction = TestFixtures.makeTransaction()
        transaction.response = TestFixtures.makeResponse(
            statusCode: 200,
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: jsonBody
        )
        transaction.response?.contentType = .json

        let data = try exporter.export(transactions: [transaction])
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let log = try #require(json["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])
        let entry = try #require(entries.first)
        let response = try #require(entry["response"] as? [String: Any])
        let content = try #require(response["content"] as? [String: Any])

        #expect(content["encoding"] == nil)
        #expect(content["text"] as? String == "{\"status\":\"ok\"}")
    }

    @Test("HARExporter includes postData for POST request with body")
    func harExporterIncludesPostData() throws {
        let exporter = HARExporter()
        let bodyData = "{\"name\":\"test\"}".data(using: .utf8)!
        let request = try HTTPRequestData(
            method: "POST",
            url: #require(URL(string: "https://api.example.com/create")),
            httpVersion: "HTTP/1.1",
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: bodyData,
            contentType: .json
        )
        let transaction = HTTPTransaction(request: request, state: .completed)
        transaction.response = TestFixtures.makeResponse(statusCode: 201)

        let data = try exporter.export(transactions: [transaction])
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let log = try #require(json["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])
        let entry = try #require(entries.first)
        let requestDict = try #require(entry["request"] as? [String: Any])
        let postData = try #require(requestDict["postData"] as? [String: Any])

        #expect(postData["text"] as? String == "{\"name\":\"test\"}")
        #expect(postData["mimeType"] as? String == "json")
    }

    @Test("HARExporter single transaction produces valid HAR structure")
    func harExporterSingleTransactionValidHAR() throws {
        let exporter = HARExporter()
        let transaction = TestFixtures.makeTransactionWithTiming(
            method: "GET",
            url: "https://api.example.com/health",
            statusCode: 200
        )

        let data = try exporter.export(transactions: [transaction])
        let json = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        let log = try #require(json["log"] as? [String: Any])
        #expect(log["version"] as? String == "1.2")

        let creator = try #require(log["creator"] as? [String: Any])
        #expect(creator["name"] as? String == "Rockxy")
        #expect(creator["version"] as? String != nil)

        let entries = try #require(log["entries"] as? [[String: Any]])
        #expect(entries.count == 1)

        let entry = entries[0]
        #expect(entry["startedDateTime"] as? String != nil)
        #expect(entry["time"] as? Double != nil)

        let request = try #require(entry["request"] as? [String: Any])
        #expect(request["method"] as? String == "GET")
        #expect(request["url"] as? String == "https://api.example.com/health")
        #expect(request["httpVersion"] as? String != nil)
        #expect(request["headers"] as? [[String: Any]] != nil)
        #expect(request["cookies"] as? [[String: Any]] != nil)

        let response = try #require(entry["response"] as? [String: Any])
        #expect(response["status"] as? Int == 200)
        #expect(response["statusText"] as? String == "OK")
        #expect(response["headers"] as? [[String: Any]] != nil)

        let timings = try #require(entry["timings"] as? [String: Any])
        #expect(timings["dns"] as? Double != nil)
        #expect(timings["connect"] as? Double != nil)
        #expect(timings["ssl"] as? Double != nil)
        #expect(timings["send"] as? Double != nil)
        #expect(timings["wait"] as? Double != nil)
        #expect(timings["receive"] as? Double != nil)

        #expect(entry["cache"] as? [String: Any] != nil)
    }
}
