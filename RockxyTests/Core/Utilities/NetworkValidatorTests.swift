import Foundation
@testable import Rockxy
import Testing

struct NetworkValidatorTests {
    @Test("Preserves normal header value")
    func normalValue() {
        let input = "text/html; charset=utf-8"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == input)
    }

    @Test("Preserves tab characters")
    func preservesTabs() {
        let input = "value\twith\ttabs"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == input)
    }

    @Test("Strips carriage return")
    func stripsCR() {
        let input = "value\rwith\rcr"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == "valuewithcr")
    }

    @Test("Strips line feed")
    func stripsLF() {
        let input = "value\nwith\nnewlines"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == "valuewithnewlines")
    }

    @Test("Strips CRLF")
    func stripsCRLF() {
        let input = "example.com\r\nX-Injected: evil"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == "example.comX-Injected: evil")
    }

    @Test("Strips null bytes")
    func stripsNull() {
        let input = "value\u{0000}with\u{0000}nulls"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == "valuewithnulls")
    }

    @Test("Strips DEL character")
    func stripsDEL() {
        let input = "value\u{7F}withDEL"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == "valuewithDEL")
    }

    @Test("Preserves non-ASCII Unicode")
    func preservesUnicode() {
        let input = "application/json; name=日本語"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == input)
    }

    @Test("Handles empty string")
    func emptyString() {
        #expect(NetworkValidator.sanitizeHeaderValue("") == "")
    }

    @Test("Strips C0 control characters U+0001-U+001F except tab")
    func stripsOtherC0Controls() {
        let input = "value\u{01}\u{02}\u{03}\u{04}\u{05}\u{06}\u{07}\u{08}\u{0B}\u{0C}\u{0E}\u{0F}\u{10}\u{1F}end"
        #expect(NetworkValidator.sanitizeHeaderValue(input) == "valueend")
    }
}
