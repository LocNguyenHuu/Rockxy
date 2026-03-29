import Foundation
@testable import Rockxy
import Testing

// Regression tests for `AsyncRetry` in the core utilities layer.

// MARK: - RetryTestError

private enum RetryTestError: Error, Equatable {
    case transient
    case terminal
}

// MARK: - RetryAttemptCounter

private actor RetryAttemptCounter {
    // MARK: Internal

    func increment() -> Int {
        value += 1
        return value
    }

    func current() -> Int {
        value
    }

    // MARK: Private

    private var value = 0
}

// MARK: - AsyncRetryTests

struct AsyncRetryTests {
    @Test("retries transient failures until success")
    func retriesUntilSuccess() async throws {
        let counter = RetryAttemptCounter()

        let result = try await AsyncRetry.retry(attempts: 3, delay: .zero, shouldRetry: { error in
            error as? RetryTestError == .transient
        }) {
            let attempt = await counter.increment()
            if attempt < 3 {
                throw RetryTestError.transient
            }
            return "ok"
        }

        #expect(result == "ok")
        #expect(await counter.current() == 3)
    }

    @Test("stops immediately for non-retryable failures")
    func stopsOnNonRetryableFailure() async {
        let counter = RetryAttemptCounter()

        await #expect(throws: RetryTestError.self) {
            try await AsyncRetry.retry(attempts: 3, delay: .zero, shouldRetry: { error in
                error as? RetryTestError == .transient
            }) {
                _ = await counter.increment()
                throw RetryTestError.terminal
            }
        }

        #expect(await counter.current() == 1)
    }

    @Test("runs retry hook before the next attempt")
    func runsRetryHook() async throws {
        let counter = RetryAttemptCounter()
        let hookCounter = RetryAttemptCounter()

        let result = try await AsyncRetry.retry(
            attempts: 2,
            delay: .zero,
            shouldRetry: { error in
                error as? RetryTestError == .transient
            },
            onRetry: { _, _ in
                _ = await hookCounter.increment()
            }
        ) {
            let attempt = await counter.increment()
            if attempt == 1 {
                throw RetryTestError.transient
            }
            return "recovered"
        }

        #expect(result == "recovered")
        #expect(await counter.current() == 2)
        #expect(await hookCounter.current() == 1)
    }
}
