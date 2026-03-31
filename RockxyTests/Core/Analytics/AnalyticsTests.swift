// Disabled: analytics analyzers (ErrorAnalyzer, PerformanceAnalyzer,
// TimelineDependencyAnalyzer) are not yet implemented. These tests will not
// compile until the Analytics module is added. Remove #if false when ready.
#if false

import Foundation
@testable import Rockxy
import Testing

// Tests for the analytics subsystem: `ErrorAnalyzer` (HTTP + log error grouping,
// URL normalization), `PerformanceAnalyzer` (percentile latency, error rates),
// `TimelineDependencyAnalyzer` (ordering, offsets), and `TrendTracker` (direction, change%).

// MARK: - AnalyticsTests

struct AnalyticsTests {
    // MARK: - ErrorAnalyzer Tests

    @Test("ErrorAnalyzer groups HTTP 4xx/5xx by normalized URL pattern and status code")
    func errorAnalyzerGroupsHTTPErrors() {
        let t1 = TestFixtures.makeTransaction(
            url: "https://api.example.com/users/1", statusCode: 404
        )
        let t2 = TestFixtures.makeTransaction(
            url: "https://api.example.com/users/2", statusCode: 404
        )
        let t3 = TestFixtures.makeTransaction(
            url: "https://api.example.com/posts/1", statusCode: 500, state: .failed
        )

        let groups = ErrorAnalyzer.analyze(transactions: [t1, t2, t3], logs: [])

        #expect(groups.count == 2)
        let notFoundGroup = groups.first { $0.pattern.contains("404") }
        #expect(notFoundGroup != nil)
        #expect(notFoundGroup?.count == 2)
    }

    @Test("ErrorAnalyzer groups log errors at level >= .error")
    func errorAnalyzerGroupsLogErrors() {
        let log1 = TestFixtures.makeLogEntry(level: .error, message: "Connection failed")
        let log2 = TestFixtures.makeLogEntry(level: .error, message: "Connection failed")
        let log3 = TestFixtures.makeLogEntry(level: .fault, message: "Fatal crash")
        let log4 = TestFixtures.makeLogEntry(level: .info, message: "All good")

        let groups = ErrorAnalyzer.analyze(transactions: [], logs: [log1, log2, log3, log4])

        #expect(groups.count == 2)
        let connectionGroup = groups.first { $0.pattern.contains("Connection failed") }
        #expect(connectionGroup?.count == 2)
    }

    @Test("ErrorAnalyzer tracks correct count, firstSeen, lastSeen for repeated errors")
    func errorAnalyzerMultiOccurrence() {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        let request1 = TestFixtures.makeRequest(url: "https://api.example.com/data")
        let t1 = HTTPTransaction(
            timestamp: baseDate, request: request1, state: .completed
        )
        t1.response = TestFixtures.makeResponse(statusCode: 500)

        let request2 = TestFixtures.makeRequest(url: "https://api.example.com/data")
        let laterDate = baseDate.addingTimeInterval(60)
        let t2 = HTTPTransaction(
            timestamp: laterDate, request: request2, state: .failed
        )
        t2.response = TestFixtures.makeResponse(statusCode: 500)

        let request3 = TestFixtures.makeRequest(url: "https://api.example.com/data")
        let latestDate = baseDate.addingTimeInterval(120)
        let t3 = HTTPTransaction(
            timestamp: latestDate, request: request3, state: .failed
        )
        t3.response = TestFixtures.makeResponse(statusCode: 500)

        let groups = ErrorAnalyzer.analyze(transactions: [t1, t2, t3], logs: [])

        #expect(groups.count == 1)
        let group = groups[0]
        #expect(group.count == 3)
        #expect(group.firstSeen == baseDate)
        #expect(group.lastSeen == latestDate)
    }

    @Test("ErrorAnalyzer normalizeURL replaces UUIDs and numeric IDs with {id}")
    func normalizeURLReplacesIDs() throws {
        let uuidURL =
            try #require(URL(string: "https://api.example.com/users/550e8400-e29b-41d4-a716-446655440000/posts"))
        let numericURL = try #require(URL(string: "https://api.example.com/users/12345/posts"))

        let normalizedUUID = ErrorAnalyzer.normalizeURL(uuidURL)
        let normalizedNumeric = ErrorAnalyzer.normalizeURL(numericURL)

        #expect(normalizedUUID == "/users/{id}/posts")
        #expect(normalizedNumeric == "/users/{id}/posts")
    }

    // MARK: - PerformanceAnalyzer Tests

    @Test("PerformanceAnalyzer returns empty for fewer than 2 transactions per endpoint")
    func performanceAnalyzerRequiresMinimumTransactions() {
        let t1 = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/users"
        )

        let metrics = PerformanceAnalyzer.analyze(transactions: [t1])

        #expect(metrics.isEmpty)
    }

    @Test("PerformanceAnalyzer computes P50/P95/P99 latency accurately")
    func performanceAnalyzerPercentileAccuracy() {
        var transactions: [HTTPTransaction] = []
        for i in 0 ..< 10 {
            let duration = Double(i + 1) * 0.1
            let t = TestFixtures.makeTransactionWithTiming(
                url: "https://api.example.com/data",
                dns: 0.001,
                tcp: 0.001,
                tls: 0.001,
                ttfb: duration - 0.003,
                transfer: 0.0
            )
            transactions.append(t)
        }

        let metrics = PerformanceAnalyzer.analyze(transactions: transactions)

        #expect(metrics.count == 1)
        let metric = metrics[0]
        #expect(metric.requestCount == 10)
        #expect(metric.p50Latency > 0)
        #expect(metric.p95Latency >= metric.p50Latency)
        #expect(metric.p99Latency >= metric.p95Latency)
    }

    @Test("PerformanceAnalyzer calculates error rate correctly")
    func performanceAnalyzerErrorRate() {
        let ok1 = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/data", statusCode: 200
        )
        let ok2 = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/data", statusCode: 200
        )
        let err1 = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/data", statusCode: 500
        )
        let err2 = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/data", statusCode: 404
        )

        let metrics = PerformanceAnalyzer.analyze(
            transactions: [ok1, ok2, err1, err2]
        )

        #expect(metrics.count == 1)
        #expect(metrics[0].errorRate == 0.5)
    }

    // MARK: - TimelineDependencyAnalyzer Tests

    @Test("TimelineDependencyAnalyzer returns entries sorted by timestamp")
    func timelineAnalyzerSortedByTimestamp() {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        let request1 = TestFixtures.makeRequest(url: "https://api.example.com/first")
        let t1 = HTTPTransaction(
            timestamp: baseDate.addingTimeInterval(10), request: request1
        )
        let request2 = TestFixtures.makeRequest(url: "https://api.example.com/second")
        let t2 = HTTPTransaction(
            timestamp: baseDate, request: request2
        )

        let entries = TimelineDependencyAnalyzer.analyze(transactions: [t1, t2])

        #expect(entries.count == 2)
        #expect(entries[0].transaction.id == t2.id)
        #expect(entries[1].transaction.id == t1.id)
    }

    @Test("TimelineDependencyAnalyzer startOffset is relative to first transaction")
    func timelineAnalyzerStartOffset() {
        let baseDate = Date(timeIntervalSince1970: 1_000_000)
        let request1 = TestFixtures.makeRequest(url: "https://api.example.com/first")
        let t1 = HTTPTransaction(timestamp: baseDate, request: request1)
        let request2 = TestFixtures.makeRequest(url: "https://api.example.com/second")
        let t2 = HTTPTransaction(
            timestamp: baseDate.addingTimeInterval(5), request: request2
        )

        let entries = TimelineDependencyAnalyzer.analyze(transactions: [t1, t2])

        #expect(entries[0].startOffset == 0)
        #expect(abs(entries[1].startOffset - 5.0) < 0.001)
    }

    // MARK: - TrendTracker Tests

    @Test("TrendTracker returns empty for empty baseline")
    func trendTrackerEmptyBaseline() {
        let current = [TestFixtures.makeTransaction()]
        let trends = TrendTracker.compare(current: current, baseline: [])

        #expect(trends.isEmpty)
    }

    @Test("TrendTracker computes correct direction based on threshold")
    func trendTrackerDirection() {
        let baselineTx = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/test",
            dns: 0.01, tcp: 0.01, tls: 0.01, ttfb: 0.1, transfer: 0.01
        )
        let fasterTx = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/test",
            dns: 0.005, tcp: 0.005, tls: 0.005, ttfb: 0.05, transfer: 0.005
        )
        let slowerTx = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/test",
            dns: 0.02, tcp: 0.02, tls: 0.02, ttfb: 0.2, transfer: 0.02
        )

        let upTrends = TrendTracker.compare(
            current: [slowerTx], baseline: [baselineTx]
        )
        let downTrends = TrendTracker.compare(
            current: [fasterTx], baseline: [baselineTx]
        )

        let latencyUp = upTrends.first { $0.metric == "Average Latency (s)" }
        let latencyDown = downTrends.first { $0.metric == "Average Latency (s)" }

        #expect(latencyUp?.direction == .up)
        #expect(latencyDown?.direction == .down)
    }

    @Test("TrendTracker computes correct changePercent")
    func trendTrackerChangePercent() throws {
        let baselineTx = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/test",
            dns: 0.01, tcp: 0.01, tls: 0.01, ttfb: 0.1, transfer: 0.01
        )
        let currentTx = TestFixtures.makeTransactionWithTiming(
            url: "https://api.example.com/test",
            dns: 0.02, tcp: 0.02, tls: 0.02, ttfb: 0.2, transfer: 0.02
        )

        let trends = TrendTracker.compare(
            current: [currentTx], baseline: [baselineTx]
        )
        let latencyTrend = trends.first { $0.metric == "Average Latency (s)" }

        #expect(latencyTrend != nil)
        #expect(try #require(latencyTrend?.changePercent) > 0)
        #expect(try #require(latencyTrend?.currentValue) > latencyTrend!.historicalBaseline)
    }
}

#endif
