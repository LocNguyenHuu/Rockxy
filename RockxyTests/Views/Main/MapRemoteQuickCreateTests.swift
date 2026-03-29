import Foundation
@testable import Rockxy
import Testing

// Regression tests for `MapRemoteQuickCreate` in the views main layer.

struct MapRemoteQuickCreateTests {
    @Test("Transaction quick-create via builder sets store")
    @MainActor
    func transactionSetsStore() {
        let store = MapRemoteDraftStore.shared
        _ = store.consumePending()

        let transaction = TestFixtures.makeTransaction(
            method: "POST",
            url: "https://api.prod.example.com/v2/orders",
            statusCode: 200
        )
        let draft = MapRemoteDraftBuilder.fromTransaction(transaction)
        store.setPending(draft)

        #expect(store.pendingDraft != nil)
        #expect(store.pendingDraft?.sourceHost == "api.prod.example.com")
        #expect(store.pendingDraft?.sourceMethod == "POST")
        _ = store.consumePending()
    }

    @Test("Domain quick-create via builder sets store")
    @MainActor
    func domainSetsStore() {
        let store = MapRemoteDraftStore.shared
        _ = store.consumePending()

        let draft = MapRemoteDraftBuilder.fromDomain("cdn.example.com")
        store.setPending(draft)

        #expect(store.pendingDraft != nil)
        #expect(store.pendingDraft?.origin == .domainQuickCreate)
        #expect(store.pendingDraft?.sourceHost == "cdn.example.com")
        _ = store.consumePending()
    }

    @Test("Quick-create posts openMapRemoteWindow notification")
    @MainActor
    func postsNotification() async {
        var received = false
        let observer = NotificationCenter.default.addObserver(
            forName: .openMapRemoteWindow, object: nil, queue: .main
        ) { _ in received = true }

        let draft = MapRemoteDraftBuilder.fromDomain("example.com")
        MapRemoteDraftStore.shared.setPending(draft)
        NotificationCenter.default.post(name: .openMapRemoteWindow, object: nil)

        try? await Task.sleep(for: .milliseconds(50))
        #expect(received)

        NotificationCenter.default.removeObserver(observer)
        _ = MapRemoteDraftStore.shared.consumePending()
    }
}
