import Foundation
@testable import Rockxy
import Testing

/// Tests for the Map Local quick-create trigger path: draft builder, store side effects,
/// and notification posting. Uses MapLocalDraftBuilder (the same helper the coordinator calls).
struct MapLocalQuickCreateTests {
    // MARK: - Draft Builder (real logic used by coordinator)

    @Test("Transaction draft builder produces correct fields")
    @MainActor
    func transactionDraftBuilder() {
        let transaction = TestFixtures.makeTransaction(
            method: "GET",
            url: "https://api.example.com/v2/users?page=1",
            statusCode: 200
        )
        transaction.response = TestFixtures.makeResponse(
            statusCode: 200,
            body: "{\"users\":[]}".data(using: .utf8)
        )

        let draft = MapLocalDraftBuilder.fromTransaction(transaction)

        #expect(draft.origin == .selectedTransaction)
        #expect(draft.sourceHost == "api.example.com")
        #expect(draft.sourcePath == "/v2/users")
        #expect(draft.sourceMethod == "GET")
        #expect(draft.sourceURL?.absoluteString == "https://api.example.com/v2/users?page=1")
        #expect(draft.suggestedName.contains("api.example.com"))
        #expect(draft.hasResponseBody == true)
    }

    @Test("Domain draft builder produces correct fields")
    @MainActor
    func domainDraftBuilder() {
        let draft = MapLocalDraftBuilder.fromDomain("api.example.com")

        #expect(draft.origin == .domainQuickCreate)
        #expect(draft.sourceHost == "api.example.com")
        #expect(draft.sourceURL == nil)
        #expect(draft.sourcePath == nil)
        #expect(draft.sourceMethod == nil)
        #expect(draft.hasResponseBody == false)
        #expect(draft.suggestedName.contains("api.example.com"))
    }

    // MARK: - Store Side Effects (real trigger path)

    @Test("Transaction quick-create sets draft on store via builder")
    @MainActor
    func transactionSetsStore() {
        let store = MapLocalDraftStore.shared
        _ = store.consumePending() // clear

        let transaction = TestFixtures.makeTransaction(
            method: "POST",
            url: "https://api.example.com/v2/orders",
            statusCode: 201
        )

        let draft = MapLocalDraftBuilder.fromTransaction(transaction)
        store.setPending(draft)

        #expect(store.pendingDraft != nil)
        #expect(store.pendingDraft?.sourceHost == "api.example.com")
        #expect(store.pendingDraft?.sourceMethod == "POST")

        _ = store.consumePending()
    }

    @Test("Domain quick-create sets draft on store via builder")
    @MainActor
    func domainSetsStore() {
        let store = MapLocalDraftStore.shared
        _ = store.consumePending()

        let draft = MapLocalDraftBuilder.fromDomain("cdn.example.com")
        store.setPending(draft)

        #expect(store.pendingDraft != nil)
        #expect(store.pendingDraft?.origin == .domainQuickCreate)
        #expect(store.pendingDraft?.sourceHost == "cdn.example.com")

        _ = store.consumePending()
    }

    // MARK: - Notification Posting

    @Test("Quick-create posts openMapLocalWindow notification")
    @MainActor
    func postsNotification() async {
        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .openMapLocalWindow,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }

        let draft = MapLocalDraftBuilder.fromDomain("example.com")
        MapLocalDraftStore.shared.setPending(draft)
        NotificationCenter.default.post(name: .openMapLocalWindow, object: nil)

        // Allow notification delivery
        try? await Task.sleep(for: .milliseconds(50))

        #expect(notificationReceived)

        NotificationCenter.default.removeObserver(observer)
        _ = MapLocalDraftStore.shared.consumePending()
    }

    // MARK: - Draft Properties

    @Test("hasResponseBody is false when body is nil")
    func noBody() {
        let draft = MapLocalDraft(
            origin: .selectedTransaction,
            suggestedName: "Test",
            sourceHost: "example.com",
            responseBody: nil
        )
        #expect(draft.hasResponseBody == false)
    }

    @Test("hasResponseBody is false when body is empty")
    func emptyBody() {
        let draft = MapLocalDraft(
            origin: .selectedTransaction,
            suggestedName: "Test",
            sourceHost: "example.com",
            responseBody: Data()
        )
        #expect(draft.hasResponseBody == false)
    }

    @Test("hasResponseBody is true when body has data")
    func withBody() {
        let draft = MapLocalDraft(
            origin: .selectedTransaction,
            suggestedName: "Test",
            sourceHost: "example.com",
            responseBody: "{}".data(using: .utf8)
        )
        #expect(draft.hasResponseBody == true)
    }

    @Test("Transaction builder infers JSON extension from Content-Type")
    @MainActor
    func infersExtension() {
        let transaction = TestFixtures.makeTransaction(
            method: "GET",
            url: "https://api.example.com/data",
            statusCode: 200
        )
        transaction.response = TestFixtures.makeResponse(
            statusCode: 200,
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: "{}".data(using: .utf8)
        )

        let draft = MapLocalDraftBuilder.fromTransaction(transaction)
        #expect(draft.inferredExtension == "json")
        #expect(draft.responseContentType == "application/json")
    }
}
