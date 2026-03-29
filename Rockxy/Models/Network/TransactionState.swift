import Foundation

/// Lifecycle state of an HTTP transaction as it flows through the proxy pipeline.
/// Transitions: `.pending` -> `.active` -> `.completed` / `.failed` / `.blocked`.
enum TransactionState: String {
    case pending
    case active
    case completed
    case failed
    case blocked
}
