import Dispatch
import Foundation
@testable import Rockxy
import Testing

// Regression tests for `RecentFailureTracker` in the core proxy engine layer.

struct RecentFailureTrackerTests {
    @Test("first failure starts a new window")
    func firstFailureStartsNewWindow() {
        let tracker = RecentFailureTracker(
            nowProvider: {
                DispatchTime(uptimeNanoseconds: 1_000_000_000)
            }
        )

        let info = tracker.recordFailure(host: "example.com")

        #expect(info.count == 1)
        #expect(info.lastFailed.uptimeNanoseconds == 1_000_000_000)
    }

    @Test("failure within the window increments count")
    func failureWithinWindowIncrementsCount() {
        var timestamps: [UInt64] = [1_000_000_000, 5_000_000_000]
        let tracker = RecentFailureTracker(
            windowSeconds: 30,
            nowProvider: {
                DispatchTime(uptimeNanoseconds: timestamps.removeFirst())
            }
        )

        _ = tracker.recordFailure(host: "example.com")
        let info = tracker.recordFailure(host: "example.com")

        #expect(info.count == 2)
        #expect(info.lastFailed.uptimeNanoseconds == 5_000_000_000)
    }

    @Test("failure outside the window resets count")
    func failureOutsideWindowResetsCount() {
        var timestamps: [UInt64] = [1_000_000_000, 40_000_000_000]
        let tracker = RecentFailureTracker(
            windowSeconds: 30,
            nowProvider: {
                DispatchTime(uptimeNanoseconds: timestamps.removeFirst())
            }
        )

        _ = tracker.recordFailure(host: "example.com")
        let info = tracker.recordFailure(host: "example.com")

        #expect(info.count == 1)
        #expect(info.lastFailed.uptimeNanoseconds == 40_000_000_000)
    }

    @Test("out-of-order timestamps do not underflow and still update the host")
    func outOfOrderTimestampsDoNotUnderflow() {
        var timestamps: [UInt64] = [5_000_000_000, 1_000_000_000]
        let tracker = RecentFailureTracker(
            windowSeconds: 30,
            nowProvider: {
                DispatchTime(uptimeNanoseconds: timestamps.removeFirst())
            }
        )

        _ = tracker.recordFailure(host: "img.alicdn.com")
        let info = tracker.recordFailure(host: "img.alicdn.com")

        #expect(info.count == 2)
        #expect(info.lastFailed.uptimeNanoseconds == 1_000_000_000)
    }
}
