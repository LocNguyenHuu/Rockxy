import Foundation
@testable import Rockxy
import Testing

// Regression tests for `DiffFormatter` in the views diff layer.

struct DiffFormatterTests {
    @Test("Request formatting produces structured sections")
    func requestFormatting() {
        let transaction = TestFixtures.makeTransaction(
            method: "GET",
            url: "https://api.example.com/v2/users?page=1",
            statusCode: 200
        )
        let sections = DiffFormatter.format(transaction: transaction, target: .request)

        #expect(sections.count >= 4)
        #expect(sections[0].0 == "Request Line")
        #expect(sections[0].1.contains("GET"))
        #expect(sections[1].0 == "Host")
        #expect(sections[1].1 == "api.example.com")
        #expect(sections[2].0 == "Query")
        #expect(sections[3].0 == "Headers")
    }

    @Test("Response formatting produces structured sections")
    func responseFormatting() {
        let transaction = TestFixtures.makeTransaction(
            method: "GET",
            url: "https://api.example.com/test",
            statusCode: 200
        )
        let sections = DiffFormatter.format(transaction: transaction, target: .response)

        #expect(sections.count >= 2)
        #expect(sections[0].0 == "Status Line")
        #expect(sections[0].1.contains("200"))
    }

    @Test("Timing formatting produces timing section")
    func timingFormatting() {
        let transaction = TestFixtures.makeTransactionWithTiming()
        let sections = DiffFormatter.format(transaction: transaction, target: .timing)

        #expect(sections.count == 1)
        #expect(sections[0].0 == "Timing")
        #expect(sections[0].1.contains("DNS"))
        #expect(sections[0].1.contains("Total"))
    }

    @Test("No timing data shows fallback")
    func noTimingFallback() {
        let transaction = TestFixtures.makeTransaction()
        transaction.timingInfo = nil
        let sections = DiffFormatter.format(transaction: transaction, target: .timing)

        #expect(sections[0].1.contains("No timing data"))
    }

    @Test("No response shows fallback")
    func noResponseFallback() {
        let transaction = TestFixtures.makeTransaction(statusCode: nil)
        let sections = DiffFormatter.format(transaction: transaction, target: .response)

        #expect(sections[0].1.contains("No response"))
    }

    @Test("Empty body shows fallback text")
    func emptyBodyFallback() {
        let transaction = TestFixtures.makeTransaction()
        let sections = DiffFormatter.format(transaction: transaction, target: .request)
        let bodySection = sections.first { $0.0 == "Body" }
        #expect(bodySection != nil)
        #expect(bodySection?.1.contains("No request body") == true)
    }

    @Test("JSON body is pretty-printed")
    func jsonPrettyPrint() {
        let transaction = TestFixtures.makeTransaction()
        transaction.response = TestFixtures.makeResponse(
            statusCode: 200,
            body: "{\"name\":\"Alice\",\"age\":30}".data(using: .utf8)
        )
        let sections = DiffFormatter.format(transaction: transaction, target: .response)
        let bodySection = sections.first { $0.0 == "Body" }
        #expect(bodySection?.1.contains("\"name\"") == true)
        #expect(bodySection?.1.contains("\n") == true)
    }

    @Test("Diff between two transactions produces structured result")
    func diffBetweenTransactions() {
        let left = TestFixtures.makeTransaction(url: "https://api.example.com/v1/users", statusCode: 200)
        let right = TestFixtures.makeTransaction(url: "https://api.example.com/v2/users", statusCode: 200)

        let result = DiffFormatter.diff(left: left, right: right, target: .request)

        #expect(result.sections.count >= 4)
        #expect(result.differenceCount > 0)
    }

    // MARK: - Regression tests

    @Test("Response diff with no-response vs full-response produces aligned sections")
    func noResponseVsFullResponse() {
        let noResp = TestFixtures.makeTransaction(statusCode: nil)
        let fullResp = TestFixtures.makeTransaction(statusCode: 200)

        let result = DiffFormatter.diff(left: noResp, right: fullResp, target: .response)

        // Both sides should have Status Line, Headers, Body sections
        #expect(result.sections.count == 3)
        #expect(result.sections[0].title == "Status Line")
        #expect(result.sections[1].title == "Headers")
        #expect(result.sections[2].title == "Body")
    }

    @Test("HTTP version normalization renders correctly for HTTP/1.1 input")
    func httpVersionWithPrefix() {
        let transaction = TestFixtures.makeTransaction()
        let sections = DiffFormatter.format(transaction: transaction, target: .request)
        let requestLine = sections.first { $0.0 == "Request Line" }
        #expect(requestLine?.1.contains("HTTP/1.1") == true)
        #expect(requestLine?.1.contains("HTTP/HTTP/") == false)
    }
}
