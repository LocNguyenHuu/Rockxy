import Foundation
import os

/// Shared store for passing transaction pairs to the diff window.
/// The context menu sets the pending pair, opens the diff window, and
/// `DiffWindowView` picks it up on appear.
@MainActor @Observable
final class DiffTransactionStore {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = DiffTransactionStore()

    var pendingTransactionA: HTTPTransaction?
    var pendingTransactionB: HTTPTransaction?

    var hasPendingComparison: Bool {
        pendingTransactionA != nil && pendingTransactionB != nil
    }

    func setPending(_ a: HTTPTransaction, _ b: HTTPTransaction) {
        pendingTransactionA = a
        pendingTransactionB = b
    }

    func consumePending() -> (HTTPTransaction, HTTPTransaction)? {
        guard let a = pendingTransactionA, let b = pendingTransactionB else {
            return nil
        }
        pendingTransactionA = nil
        pendingTransactionB = nil
        return (a, b)
    }
}
