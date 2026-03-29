import Foundation
@testable import Rockxy
import Testing

// Regression tests for `MapRemoteDraftStore` in the views rules layer.

struct MapRemoteDraftStoreTests {
    @Test("setPending stores draft and increments version")
    @MainActor
    func setPending() {
        let store = MapRemoteDraftStore.shared
        let v0 = store.draftVersion

        let draft = MapRemoteDraft(
            origin: .selectedTransaction,
            suggestedName: "Test",
            sourceURL: nil,
            sourceHost: "example.com",
            sourcePath: nil,
            sourceMethod: nil
        )
        store.setPending(draft)

        #expect(store.pendingDraft != nil)
        #expect(store.draftVersion == v0 &+ 1)
        _ = store.consumePending()
    }

    @Test("consumePending returns draft once then nil")
    @MainActor
    func consumeOnce() {
        let store = MapRemoteDraftStore.shared
        let draft = MapRemoteDraft(
            origin: .domainQuickCreate,
            suggestedName: "Domain",
            sourceURL: nil,
            sourceHost: "example.com",
            sourcePath: nil,
            sourceMethod: nil
        )
        store.setPending(draft)

        let first = store.consumePending()
        #expect(first != nil)
        #expect(first?.suggestedName == "Domain")

        let second = store.consumePending()
        #expect(second == nil)
    }

    @Test("consumePending on empty store returns nil")
    @MainActor
    func consumeEmpty() {
        let store = MapRemoteDraftStore.shared
        _ = store.consumePending()
        #expect(store.consumePending() == nil)
    }
}
