import Foundation
@testable import Rockxy
import Testing

// Regression tests for `DiffTransactionStore` in the views diff layer.

@MainActor
struct DiffTransactionStoreTests {
    @Test("setPending stores transactions")
    func setPendingStores() {
        let store = DiffTransactionStore.shared
        let txA = TestFixtures.makeTransaction(url: "https://api.example.com/a")
        let txB = TestFixtures.makeTransaction(url: "https://api.example.com/b")

        store.setPending(txA, txB)

        #expect(store.pendingTransactionA === txA)
        #expect(store.pendingTransactionB === txB)
        #expect(store.hasPendingComparison == true)

        // Clean up shared state
        _ = store.consumePending()
    }

    @Test("consumePending returns pair and clears state")
    func consumeClears() {
        let store = DiffTransactionStore.shared
        let txA = TestFixtures.makeTransaction(url: "https://api.example.com/left")
        let txB = TestFixtures.makeTransaction(url: "https://api.example.com/right")

        store.setPending(txA, txB)
        let result = store.consumePending()

        #expect(result != nil)
        #expect(result?.0 === txA)
        #expect(result?.1 === txB)
        #expect(store.pendingTransactionA == nil)
        #expect(store.pendingTransactionB == nil)
        #expect(store.hasPendingComparison == false)
    }

    @Test("consumePending returns nil when nothing is pending")
    func consumeWhenEmpty() {
        let store = DiffTransactionStore.shared
        // Ensure clean state
        _ = store.consumePending()

        let result = store.consumePending()
        #expect(result == nil)
    }

    @Test("hasPendingComparison is false when only one transaction set")
    func partialPending() {
        let store = DiffTransactionStore.shared
        // Ensure clean state
        _ = store.consumePending()

        store.pendingTransactionA = TestFixtures.makeTransaction()
        store.pendingTransactionB = nil

        #expect(store.hasPendingComparison == false)

        // Clean up
        store.pendingTransactionA = nil
    }
}
