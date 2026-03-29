import Foundation

/// Limits concurrent upstream connections per destination to prevent file descriptor exhaustion.
///
/// Modeled after mitmproxy's `max_conns` semaphore pattern: each (host, port) pair gets at most
/// `maxPerDestination` concurrent connections. Callers must `acquire` before opening a connection
/// and `release` when the connection closes.
///
/// Thread-safe via `NSLock` for use from NIO event loops.
final class ConnectionLimiter: @unchecked Sendable {
    // MARK: Lifecycle

    init(maxPerDestination: Int = 6) {
        self.maxPerDestination = maxPerDestination
    }

    // MARK: Internal

    /// Attempts to reserve a connection slot. Returns `true` if allowed, `false` if at capacity.
    func acquire(host: String, port: Int) -> Bool {
        let dest = Destination(host: host, port: port)
        lock.lock()
        defer { lock.unlock() }
        let current = counts[dest, default: 0]
        guard current < maxPerDestination else {
            return false
        }
        counts[dest] = current + 1
        return true
    }

    /// Releases a connection slot when the upstream channel closes.
    func release(host: String, port: Int) {
        let dest = Destination(host: host, port: port)
        lock.lock()
        defer { lock.unlock() }
        let current = counts[dest, default: 0]
        counts[dest] = max(0, current - 1)
    }

    // MARK: Private

    private struct Destination: Hashable {
        let host: String
        let port: Int
    }

    private let maxPerDestination: Int
    private var counts: [Destination: Int] = [:]
    private let lock = NSLock()
}
