import Foundation
@testable import Rockxy
import Testing

// Regression tests for `NetworkConditionsDraftStore` in the views rules layer.

@Suite(.serialized)
struct NetworkConditionsDraftStoreTests {
    @Test("set and consume roundtrip")
    @MainActor
    func setAndConsumeRoundtrip() {
        let store = NetworkConditionsDraftStore.shared
        _ = store.consumePending()

        let draft = NetworkConditionsDraft(
            origin: .selectedTransaction,
            suggestedName: "Slow Test",
            sourceURL: URL(string: "https://example.com/api"),
            sourceHost: "example.com",
            sourcePath: "/api",
            sourceMethod: "GET"
        )
        store.setPending(draft)

        let consumed = store.consumePending()
        #expect(consumed != nil)
        #expect(consumed?.suggestedName == "Slow Test")
        #expect(consumed?.sourceHost == "example.com")
        #expect(consumed?.origin == .selectedTransaction)
    }

    @Test("second consume returns nil")
    @MainActor
    func secondConsumeReturnsNil() {
        let store = NetworkConditionsDraftStore.shared
        _ = store.consumePending()

        let draft = NetworkConditionsDraft(
            origin: .domainQuickCreate,
            suggestedName: "Domain Draft",
            sourceURL: nil,
            sourceHost: "example.com",
            sourcePath: nil,
            sourceMethod: nil
        )
        store.setPending(draft)

        let first = store.consumePending()
        #expect(first != nil)
        #expect(first?.suggestedName == "Domain Draft")

        let second = store.consumePending()
        #expect(second == nil)
    }

    @Test("draftVersion increments")
    @MainActor
    func draftVersionIncrements() {
        let store = NetworkConditionsDraftStore.shared
        _ = store.consumePending()

        let v0 = store.draftVersion
        let draft = NetworkConditionsDraft(
            origin: .domainQuickCreate,
            suggestedName: "Version Test",
            sourceURL: nil,
            sourceHost: "example.com",
            sourcePath: nil,
            sourceMethod: nil
        )
        store.setPending(draft)

        #expect(store.draftVersion == v0 &+ 1)

        store.setPending(draft)
        #expect(store.draftVersion == v0 &+ 2)

        _ = store.consumePending()
    }
}
