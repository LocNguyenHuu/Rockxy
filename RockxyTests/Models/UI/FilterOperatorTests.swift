import Foundation
@testable import Rockxy
import Testing

// Regression tests for `FilterOperator` in the models ui layer.

// MARK: - FilterOperatorTests

struct FilterOperatorTests {
    // MARK: - Contains

    @Test("Contains matches substring")
    func containsSubstring() {
        #expect(FilterOperator.contains.matches("hello world", against: "world"))
    }

    @Test("Contains is case-insensitive")
    func containsCaseInsensitive() {
        #expect(FilterOperator.contains.matches("Hello World", against: "hello"))
    }

    @Test("Contains rejects absent text")
    func containsRejectsAbsent() {
        #expect(!FilterOperator.contains.matches("hello world", against: "xyz"))
    }

    // MARK: - Is

    @Test("Is matches exact string")
    func isExactMatch() {
        #expect(FilterOperator.is.matches("hello", against: "hello"))
    }

    @Test("Is is case-insensitive")
    func isCaseInsensitive() {
        #expect(FilterOperator.is.matches("Hello", against: "hello"))
    }

    @Test("Is rejects partial match")
    func isRejectsPartial() {
        #expect(!FilterOperator.is.matches("hello world", against: "hello"))
    }

    // MARK: - Starts With

    @Test("StartsWith matches prefix")
    func startsWithMatch() {
        #expect(FilterOperator.startsWith.matches("https://example.com", against: "https://"))
    }

    @Test("StartsWith rejects non-prefix")
    func startsWithRejects() {
        #expect(!FilterOperator.startsWith.matches("https://example.com", against: "example"))
    }

    // MARK: - Ends With

    @Test("EndsWith matches suffix")
    func endsWithMatch() {
        #expect(FilterOperator.endsWith.matches("api.example.com", against: ".com"))
    }

    @Test("EndsWith rejects non-suffix")
    func endsWithRejects() {
        #expect(!FilterOperator.endsWith.matches("api.example.com", against: ".org"))
    }

    // MARK: - Does Not Contain

    @Test("DoesNotContain passes when absent")
    func doesNotContainAbsent() {
        #expect(FilterOperator.doesNotContain.matches("hello world", against: "xyz"))
    }

    @Test("DoesNotContain fails when present")
    func doesNotContainPresent() {
        #expect(!FilterOperator.doesNotContain.matches("hello world", against: "hello"))
    }

    // MARK: - Not Equal

    @Test("NotEqual passes for different strings")
    func notEqualDifferent() {
        #expect(FilterOperator.notEqual.matches("hello", against: "world"))
    }

    @Test("NotEqual fails for same string case-insensitive")
    func notEqualSameCaseInsensitive() {
        #expect(!FilterOperator.notEqual.matches("Hello", against: "hello"))
    }

    // MARK: - Regex

    @Test("Regex matches valid pattern")
    func regexValidPattern() {
        #expect(FilterOperator.regex.matches("/users/123/posts", against: "/users/\\d+/posts"))
    }

    @Test("Regex is case-insensitive")
    func regexCaseInsensitive() {
        #expect(FilterOperator.regex.matches("Hello World", against: "hello"))
    }

    @Test("Regex returns false for invalid pattern")
    func regexInvalidPattern() {
        #expect(!FilterOperator.regex.matches("anything", against: "[invalid"))
    }

    @Test("Regex matches character classes")
    func regexCharacterClasses() {
        #expect(FilterOperator.regex.matches("abc123", against: "^[a-z]+\\d+$"))
    }

    @Test("Regex rejects non-matching pattern")
    func regexRejectsNonMatch() {
        #expect(!FilterOperator.regex.matches("hello", against: "^\\d+$"))
    }
}
