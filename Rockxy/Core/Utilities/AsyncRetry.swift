import Foundation

// Provides reusable async retry logic for transient failures in app workflows.

// MARK: - AsyncRetry

/// Small async retry helper for transient operations such as XPC reachability probes.
enum AsyncRetry {
    static func retry<T>(
        attempts: Int,
        delay: Duration = .zero,
        shouldRetry: @escaping @Sendable (Error) -> Bool = { !($0 is CancellationError) },
        onRetry: @escaping @Sendable (_ failedAttempt: Int, _ error: Error) async -> Void = { _, _ in },
        operation: @escaping @Sendable () async throws -> T
    )
        async throws -> T
    {
        let totalAttempts = max(attempts, 1)
        var lastError: Error?

        for attempt in 1 ... totalAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                guard attempt < totalAttempts, shouldRetry(error) else {
                    throw error
                }

                await onRetry(attempt, error)

                if delay > .zero {
                    try await Task.sleep(for: delay)
                }
            }
        }

        throw lastError ?? CancellationError()
    }
}
