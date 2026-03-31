import Foundation
@testable import Rockxy
import Testing

struct RegexValidatorTests {
    @Test("Compiles valid simple pattern")
    func validSimplePattern() throws {
        let regex = try RegexValidator.compile(".*\\.example\\.com").get()
        #expect(regex.pattern.contains("example"))
    }

    @Test("Compiles valid URL pattern")
    func validURLPattern() throws {
        let regex = try RegexValidator.compile("https?://api\\.example\\.com/v[0-9]+/.*").get()
        #expect(regex.pattern == "https?://api\\.example\\.com/v[0-9]+/.*")
    }

    @Test("Rejects invalid regex (unbalanced parentheses)")
    func invalidUnbalancedParens() {
        let result = RegexValidator.compile("((abc)")
        #expect(throws: RegexValidator.ValidationError.self) { try result.get() }
    }

    @Test("Rejects invalid regex (bad character class)")
    func invalidCharClass() {
        let result = RegexValidator.compile("[abc")
        #expect(throws: RegexValidator.ValidationError.self) { try result.get() }
    }

    @Test("Rejects pattern exceeding max length")
    func patternTooLong() {
        let longPattern = String(repeating: "a", count: 501)
        if case let .failure(.patternTooLong(length)) = RegexValidator.compile(longPattern) {
            #expect(length == 501)
        } else {
            Issue.record("Expected patternTooLong failure")
        }
    }

    @Test("Accepts pattern at exactly max length")
    func patternAtMaxLength() throws {
        let pattern = String(repeating: "a", count: 500)
        _ = try RegexValidator.compile(pattern).get()
    }

    @Test("Compiles wildcard pattern")
    func wildcardPattern() throws {
        _ = try RegexValidator.compile(".*").get()
    }

    @Test("Rejects lone backslash")
    func invalidLoneBackslash() {
        let result = RegexValidator.compile("\\")
        #expect(throws: RegexValidator.ValidationError.self) { try result.get() }
    }
}
