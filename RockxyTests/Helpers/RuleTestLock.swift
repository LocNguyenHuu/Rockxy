import Foundation

/// Serializes all tests that mutate `RuleEngine.shared` or `RulePolicyGate.shared`.
///
/// Swift Testing's `@Suite(.serialized)` only serializes within a single suite.
/// When xcodebuild assigns tests from multiple suites to the same process,
/// they run concurrently and contend for the shared `RuleEngine` actor.
/// This actor-based lock forces cross-suite serialization.
actor RuleTestLock {
    // MARK: Internal

    static let shared = RuleTestLock()

    func acquire() async {
        if !isLocked {
            isLocked = true
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        if let next = waiters.first {
            waiters.removeFirst()
            next.resume()
        } else {
            isLocked = false
        }
    }

    // MARK: Private

    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
}
