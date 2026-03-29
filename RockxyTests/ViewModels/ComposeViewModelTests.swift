import Foundation
@testable import Rockxy
import Testing

// Regression tests for `ComposeViewModel` in the view models layer.

// MARK: - MockComposeExecutor

/// Mock executor for deterministic testing of ComposeViewModel.
struct MockComposeExecutor: ComposeRequestExecutor {
    let handler: @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await handler(request)
    }
}

// MARK: - ComposeViewModelTests

@MainActor
struct ComposeViewModelTests {
    // MARK: Internal

    // MARK: - Prefill

    @Test("Prefill correctly maps transaction fields")
    func prefillMapsFields() {
        let transaction = TestFixtures.makeTransaction(
            method: "POST",
            url: "https://api.example.com/users?page=2&sort=name"
        )
        transaction.request.headers = [
            HTTPHeader(name: "Content-Type", value: "application/json"),
            HTTPHeader(name: "Authorization", value: "Bearer token123"),
        ]
        transaction.request.body = Data("{\"name\":\"test\"}".utf8)

        let vm = ComposeViewModel()
        vm.prefill(from: transaction)

        #expect(vm.method == "POST")
        #expect(vm.url == "https://api.example.com/users?page=2&sort=name")
        #expect(vm.headers.count == 2)
        #expect(vm.headers[0].name == "Content-Type")
        #expect(vm.headers[0].value == "application/json")
        #expect(vm.headers[1].name == "Authorization")
        #expect(vm.body == "{\"name\":\"test\"}")
        #expect(vm.queryItems.count == 2)
        #expect(vm.queryItems[0].name == "page")
        #expect(vm.queryItems[0].value == "2")
        #expect(vm.queryItems[1].name == "sort")
        #expect(vm.queryItems[1].value == "name")
    }

    @Test("Prefill resets response state to empty")
    func prefillResetsResponse() async throws {
        let response = try makeResponse()
        let executor = MockComposeExecutor { _ in
            (Data("ok".utf8), response)
        }
        let vm = ComposeViewModel(executor: executor)
        vm.url = "https://example.com"
        await vm.send()

        if case .success = vm.responseState {} else {
            Issue.record("Expected success state after send")
        }

        let transaction = TestFixtures.makeTransaction()
        vm.prefill(from: transaction)

        if case .empty = vm.responseState {} else {
            Issue.record("Expected empty state after prefill")
        }
    }

    // MARK: - Send Success

    @Test("Send success updates response state")
    func sendSuccess() async throws {
        let jsonBody = Data("{\"id\":1}".utf8)
        let response = try makeResponse(
            url: "https://api.example.com/test",
            headerFields: ["Content-Type": "application/json"]
        )
        let executor = MockComposeExecutor { _ in
            (jsonBody, response)
        }

        let vm = ComposeViewModel(executor: executor)
        vm.url = "https://api.example.com/test"
        vm.method = "GET"

        await vm.send()

        if case let .success(result) = vm.responseState {
            #expect(result.statusCode == 200)
            #expect(result.bodyData == jsonBody)
            #expect(result.bodyText == "{\"id\":1}")
        } else {
            Issue.record("Expected success state")
        }
    }

    // MARK: - Send Failure

    @Test("Send failure updates error state")
    func sendFailure() async {
        let executor = MockComposeExecutor { _ in
            throw URLError(.notConnectedToInternet)
        }

        let vm = ComposeViewModel(executor: executor)
        vm.url = "https://api.example.com/test"

        await vm.send()

        if case let .error(message) = vm.responseState {
            #expect(!message.isEmpty)
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("Send with invalid URL shows error state")
    func sendInvalidURL() async {
        let vm = ComposeViewModel()
        vm.url = ""

        await vm.send()

        if case .error = vm.responseState {} else {
            Issue.record("Expected error state for empty URL")
        }
    }

    // MARK: - Latest-Run-Wins

    @Test("Latest run wins when two sends overlap")
    func latestRunWins() async throws {
        let firstContinuation: AsyncStream<Void>.Continuation
        let firstStream: AsyncStream<Void>
        (firstStream, firstContinuation) = AsyncStream<Void>.makeStream()

        let callCount = ManagedAtomic(0)
        let firstResponse = try makeResponse(statusCode: 200)
        let secondResponse = try makeResponse(statusCode: 201)

        let executor = MockComposeExecutor { _ in
            let count = callCount.increment()

            if count == 1 {
                for await _ in firstStream {
                    break
                }
                return (Data("first".utf8), firstResponse)
            } else {
                return (Data("second".utf8), secondResponse)
            }
        }

        let vm = ComposeViewModel(executor: executor)
        vm.url = "https://example.com"

        let firstTask = Task { @MainActor in
            await vm.send()
        }

        try? await Task.sleep(for: .milliseconds(50))

        await vm.send()

        if case let .success(result) = vm.responseState {
            #expect(result.statusCode == 201)
            #expect(result.bodyText == "second")
        } else {
            Issue.record("Expected success state from second send")
        }

        firstContinuation.yield()
        firstContinuation.finish()
        await firstTask.value

        if case let .success(result) = vm.responseState {
            #expect(result.statusCode == 201)
        } else {
            Issue.record("Expected second send to still win after first completes")
        }
    }

    // MARK: - Binary Response Fallback

    @Test("Binary response produces fallback text")
    func binaryResponseFallback() async throws {
        let binaryData = Data([0x00, 0x01, 0xFF, 0xFE])
        let response = try makeResponse(headerFields: ["Content-Type": "application/octet-stream"])
        let executor = MockComposeExecutor { _ in
            (binaryData, response)
        }

        let vm = ComposeViewModel(executor: executor)
        vm.url = "https://example.com"
        await vm.send()

        if case let .success(result) = vm.responseState {
            #expect(result.bodyText == nil)
            #expect(result.bodyDisplayText.contains("4"))
            #expect(result.bodyDisplayText.contains("binary"))
        } else {
            Issue.record("Expected success state")
        }
    }

    // MARK: - Query Sync

    @Test("Editing query items updates URL")
    func queryToURLSync() {
        let vm = ComposeViewModel()
        vm.url = "https://api.example.com/users"
        vm.lastSyncedURL = vm.url
        vm.queryItems = [
            EditableQueryItem(name: "page", value: "1"),
            EditableQueryItem(name: "limit", value: "20"),
        ]
        vm.syncQueryToURL()

        #expect(vm.url.contains("page=1"))
        #expect(vm.url.contains("limit=20"))
    }

    @Test("Editing URL updates query items")
    func uRLToQuerySync() {
        let vm = ComposeViewModel()
        vm.url = "https://api.example.com/users?status=active&role=admin"
        vm.syncURLToQuery()

        #expect(vm.queryItems.count == 2)
        #expect(vm.queryItems[0].name == "status")
        #expect(vm.queryItems[0].value == "active")
        #expect(vm.queryItems[1].name == "role")
        #expect(vm.queryItems[1].value == "admin")
    }

    @Test("lastSyncedURL prevents infinite sync loop")
    func syncGuardPreventsLoop() {
        let vm = ComposeViewModel()
        vm.url = "https://example.com?a=1"
        vm.syncURLToQuery()

        let queryCountAfterFirstSync = vm.queryItems.count

        vm.syncURLToQuery()
        #expect(vm.queryItems.count == queryCountAfterFirstSync)
    }

    @Test("Empty query items are excluded from URL rebuild")
    func emptyQueryItemsExcluded() {
        let vm = ComposeViewModel()
        vm.url = "https://api.example.com/data"
        vm.lastSyncedURL = vm.url
        vm.queryItems = [
            EditableQueryItem(name: "", value: "ignored"),
            EditableQueryItem(name: "keep", value: "this"),
        ]
        vm.syncQueryToURL()

        #expect(vm.url.contains("keep=this"))
        #expect(!vm.url.contains("ignored"))
    }

    // MARK: - Header Management

    @Test("Add and remove headers")
    func headerManagement() {
        let vm = ComposeViewModel()
        #expect(vm.headers.isEmpty)

        vm.addHeader()
        #expect(vm.headers.count == 1)

        let headerId = vm.headers[0].id
        vm.removeHeader(id: headerId)
        #expect(vm.headers.isEmpty)
    }

    // MARK: - Raw Request Text

    @Test("Raw request text assembles correctly")
    func testRawRequestText() {
        let vm = ComposeViewModel()
        vm.method = "POST"
        vm.url = "https://api.example.com/users?page=1"
        vm.headers = [
            EditableReplayHeader(name: "Content-Type", value: "application/json"),
        ]
        vm.body = "{\"name\":\"test\"}"

        let raw = vm.rawRequestText
        #expect(raw.contains("POST /users?page=1 HTTP/1.1"))
        #expect(raw.contains("Host: api.example.com"))
        #expect(raw.contains("Content-Type: application/json"))
        #expect(raw.contains("{\"name\":\"test\"}"))
    }

    // MARK: - Unsupported Request Types

    @Test("WebSocket prefill sets unsupported state")
    func webSocketPrefillUnsupported() {
        let transaction = TestFixtures.makeWebSocketTransaction()
        let vm = ComposeViewModel()
        vm.prefill(from: transaction)

        #expect(vm.sourceIsWebSocket == true)
        #expect(vm.isUnsupportedForReplay == true)
        if case .unsupported = vm.responseState {} else {
            Issue.record("Expected unsupported state for WebSocket transaction")
        }
    }

    @Test("CONNECT prefill sets unsupported state")
    func connectPrefillUnsupported() {
        let transaction = TestFixtures.makeTransaction(method: "CONNECT", url: "https://example.com:443")
        let vm = ComposeViewModel()
        vm.prefill(from: transaction)

        #expect(vm.sourceIsWebSocket == false)
        #expect(vm.isUnsupportedForReplay == true)
        if case .unsupported = vm.responseState {} else {
            Issue.record("Expected unsupported state for CONNECT transaction")
        }
    }

    @Test("Send on unsupported draft does not invoke executor")
    func sendUnsupportedDoesNotCallExecutor() async {
        let callCount = ManagedAtomic(0)
        let executor = MockComposeExecutor { _ in
            _ = callCount.increment()
            throw URLError(.badURL)
        }

        let transaction = TestFixtures.makeWebSocketTransaction()
        let vm = ComposeViewModel(executor: executor)
        vm.prefill(from: transaction)

        await vm.send()

        #expect(callCount.currentValue == 0)
        if case .unsupported = vm.responseState {} else {
            Issue.record("Expected unsupported state after send attempt")
        }
    }

    @Test("Normal HTTP prefill keeps supported state")
    func normalPrefillSupported() {
        let transaction = TestFixtures.makeTransaction(method: "GET", url: "https://api.example.com/test")
        let vm = ComposeViewModel()
        vm.prefill(from: transaction)

        #expect(vm.sourceIsWebSocket == false)
        #expect(vm.isUnsupportedForReplay == false)
        if case .empty = vm.responseState {} else {
            Issue.record("Expected empty state for normal HTTP transaction")
        }
    }

    @Test("Switching from unsupported to supported draft clears unsupported state")
    func switchingDraftsClearsUnsupported() {
        let vm = ComposeViewModel()

        let wsTransaction = TestFixtures.makeWebSocketTransaction()
        vm.prefill(from: wsTransaction)
        if case .unsupported = vm.responseState {} else {
            Issue.record("Expected unsupported state after WS prefill")
        }

        let normalTransaction = TestFixtures.makeTransaction()
        vm.prefill(from: normalTransaction)
        #expect(vm.sourceIsWebSocket == false)
        #expect(vm.isUnsupportedForReplay == false)
        if case .empty = vm.responseState {} else {
            Issue.record("Expected empty state after switching to normal draft")
        }
    }

    @Test("Changing method from CONNECT to GET clears unsupported response state")
    func connectToGetClearsUnsupported() {
        let transaction = TestFixtures.makeTransaction(method: "CONNECT", url: "https://example.com:443")
        let vm = ComposeViewModel()
        vm.prefill(from: transaction)

        #expect(vm.isUnsupportedForReplay == true)
        if case .unsupported = vm.responseState {} else {
            Issue.record("Expected unsupported state for CONNECT draft")
        }

        vm.method = "GET"
        vm.syncUnsupportedState()
        #expect(vm.isUnsupportedForReplay == false)
        if case .empty = vm.responseState {} else {
            Issue.record("Expected empty state after changing CONNECT to GET")
        }
    }

    @Test("Changing method from GET to CONNECT while empty transitions to unsupported")
    func getToConnectTransitionsToUnsupported() {
        let transaction = TestFixtures.makeTransaction(method: "GET", url: "https://example.com")
        let vm = ComposeViewModel()
        vm.prefill(from: transaction)

        if case .empty = vm.responseState {} else {
            Issue.record("Expected empty state for GET draft")
        }

        vm.method = "CONNECT"
        vm.syncUnsupportedState()
        #expect(vm.isUnsupportedForReplay == true)
        if case .unsupported = vm.responseState {} else {
            Issue.record("Expected unsupported state after changing GET to CONNECT")
        }
    }

    @Test("Changing method to CONNECT while response is success does not overwrite")
    func connectDoesNotOverwriteSuccess() async throws {
        let response = try makeResponse()
        let executor = MockComposeExecutor { _ in
            (Data("ok".utf8), response)
        }
        let vm = ComposeViewModel(executor: executor)
        vm.url = "https://example.com"
        await vm.send()

        if case .success = vm.responseState {} else {
            Issue.record("Expected success state after send")
        }

        vm.method = "CONNECT"
        vm.syncUnsupportedState()

        if case .success = vm.responseState {} else {
            Issue.record("Expected success state to be preserved when switching to CONNECT")
        }
    }

    // MARK: Private

    // MARK: - Test Helpers

    private func makeResponse(
        url: String = "https://example.com",
        statusCode: Int = 200,
        headerFields: [String: String]? = nil
    )
        throws -> HTTPURLResponse
    {
        let parsedURL = try #require(URL(string: url))
        return try #require(
            HTTPURLResponse(
                url: parsedURL,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headerFields
            )
        )
    }
}

// MARK: - ManagedAtomic

/// Simple thread-safe counter for test coordination.
private final class ManagedAtomic: @unchecked Sendable {
    // MARK: Lifecycle

    init(_ initial: Int) {
        value = initial
    }

    // MARK: Internal

    var currentValue: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }

    // MARK: Private

    private var value: Int
    private let lock = NSLock()
}
