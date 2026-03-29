import Foundation
@testable import Rockxy
import Testing

// Regression tests for `MapLocalDraftStore` in the views rules layer.

struct MapLocalDraftStoreTests {
    @Test("setPending stores draft and increments version")
    @MainActor
    func setPending() {
        let store = MapLocalDraftStore.shared
        let initialVersion = store.draftVersion

        let draft = MapLocalDraft(
            origin: .selectedTransaction,
            suggestedName: "Test Rule",
            sourceHost: "api.example.com"
        )
        store.setPending(draft)

        #expect(store.pendingDraft != nil)
        #expect(store.pendingDraft?.suggestedName == "Test Rule")
        #expect(store.draftVersion == initialVersion &+ 1)

        // Cleanup
        _ = store.consumePending()
    }

    @Test("consumePending returns draft once then nil")
    @MainActor
    func consumeOnce() {
        let store = MapLocalDraftStore.shared

        let draft = MapLocalDraft(
            origin: .domainQuickCreate,
            suggestedName: "Domain Rule",
            sourceHost: "example.com"
        )
        store.setPending(draft)

        let first = store.consumePending()
        #expect(first != nil)
        #expect(first?.suggestedName == "Domain Rule")

        let second = store.consumePending()
        #expect(second == nil)
    }

    @Test("draftVersion increments on each setPending call")
    @MainActor
    func versionIncrement() {
        let store = MapLocalDraftStore.shared
        let v0 = store.draftVersion

        let draft = MapLocalDraft(
            origin: .selectedTransaction,
            suggestedName: "Rule 1",
            sourceHost: "host1.com"
        )
        store.setPending(draft)
        #expect(store.draftVersion == v0 &+ 1)

        store.setPending(draft)
        #expect(store.draftVersion == v0 &+ 2)

        // Cleanup
        _ = store.consumePending()
    }

    @Test("consumePending on empty store returns nil")
    @MainActor
    func consumeEmpty() {
        let store = MapLocalDraftStore.shared
        // Ensure empty
        _ = store.consumePending()

        let result = store.consumePending()
        #expect(result == nil)
    }
}
