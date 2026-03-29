import Foundation
@testable import Rockxy
import Testing

// Regression tests for `PreviewRenderer` in the core utilities layer.

struct PreviewRendererTests {
    // MARK: - Empty Body

    @Test("Nil body returns empty result")
    func nilBody() {
        let result = PreviewRenderer.render(body: nil, mode: .json)
        if case let .empty(reason) = result {
            #expect(reason.contains("No body"))
        } else {
            Issue.record("Expected empty result")
        }
    }

    @Test("Empty data returns empty result")
    func emptyData() {
        let result = PreviewRenderer.render(body: Data(), mode: .raw)
        if case .empty = result {
            // Expected
        } else {
            Issue.record("Expected empty result")
        }
    }

    // MARK: - JSON

    @Test("JSON mode pretty-prints valid JSON")
    func jsonPrettyPrint() {
        let body = Data("{\"name\":\"test\",\"value\":42}".utf8)
        let result = PreviewRenderer.render(body: body, mode: .json)
        if case let .text(text) = result {
            #expect(text.contains("\"name\" : \"test\""))
            #expect(text.contains("\"value\" : 42"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("JSON mode falls back to raw text for invalid JSON")
    func jsonInvalidFallback() {
        let body = Data("not json at all".utf8)
        let result = PreviewRenderer.render(body: body, mode: .json)
        if case let .text(text) = result {
            #expect(text == "not json at all")
        } else {
            Issue.record("Expected text fallback")
        }
    }

    // MARK: - JSON Tree

    @Test("JSON tree returns parsed object")
    func jsonTree() {
        let body = Data("{\"key\":\"value\"}".utf8)
        let result = PreviewRenderer.render(body: body, mode: .jsonTree)
        if case let .json(obj) = result {
            let dict = obj as? [String: Any]
            #expect(dict?["key"] as? String == "value")
        } else {
            Issue.record("Expected json result")
        }
    }

    @Test("JSON tree returns empty for invalid JSON")
    func jsonTreeInvalid() {
        let body = Data("not json".utf8)
        let result = PreviewRenderer.render(body: body, mode: .jsonTree)
        if case let .empty(reason) = result {
            #expect(reason.contains("JSON"))
        } else {
            Issue.record("Expected empty result")
        }
    }

    // MARK: - Form URL-Encoded

    @Test("Form URL-encoded decodes pairs")
    func formURLEncoded() {
        let body = Data("name=John+Doe&age=30&city=New%20York".utf8)
        let result = PreviewRenderer.render(body: body, mode: .formURLEncoded)
        if case let .text(text) = result {
            #expect(text.contains("name = John Doe"))
            #expect(text.contains("age = 30"))
            #expect(text.contains("city = New York"))
        } else {
            Issue.record("Expected text result")
        }
    }

    // MARK: - HTML

    @Test("HTML mode returns text")
    func htmlText() {
        let body = Data("<html><body>Hello</body></html>".utf8)
        let result = PreviewRenderer.render(body: body, mode: .html)
        if case let .text(text) = result {
            #expect(text.contains("<html>"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("HTML preview returns text for WKWebView")
    func htmlPreview() {
        let body = Data("<h1>Title</h1>".utf8)
        let result = PreviewRenderer.render(body: body, mode: .htmlPreview)
        if case let .text(text) = result {
            #expect(text == "<h1>Title</h1>")
        } else {
            Issue.record("Expected text result")
        }
    }

    // MARK: - Hex

    @Test("Hex dump formats correctly")
    func hexDump() {
        let body = Data("Hello, World!".utf8)
        let result = PreviewRenderer.render(body: body, mode: .hex)
        if case let .hex(text) = result {
            #expect(text.contains("00000000"))
            #expect(text.contains("48 65 6C 6C"))
            #expect(text.contains("Hello, World!"))
        } else {
            Issue.record("Expected hex result")
        }
    }

    @Test("Hex dump handles binary data with non-printable chars")
    func hexBinary() {
        let body = Data([0x00, 0x01, 0xFF, 0x7F, 0x41])
        let result = PreviewRenderer.render(body: body, mode: .hex)
        if case let .hex(text) = result {
            #expect(text.contains("00 01 FF 7F 41"))
            #expect(text.contains("....A"))
        } else {
            Issue.record("Expected hex result")
        }
    }

    @Test("formatHexDump spaces between 8th and 9th byte")
    func hexSpacing() {
        let body = Data(repeating: 0x41, count: 16)
        let hex = PreviewRenderer.formatHexDump(body)
        // Should have double space between 8th and 9th byte
        #expect(hex.contains("41 41 41 41 41 41 41 41  41 41 41 41 41 41 41 41"))
    }

    // MARK: - Raw

    @Test("Raw mode returns UTF-8 text")
    func rawText() {
        let body = Data("plain text content".utf8)
        let result = PreviewRenderer.render(body: body, mode: .raw)
        if case let .text(text) = result {
            #expect(text == "plain text content")
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("Raw mode returns empty for binary")
    func rawBinary() {
        let body = Data([0x00, 0xFF, 0xFE])
        let result = PreviewRenderer.render(body: body, mode: .raw)
        if case let .empty(reason) = result {
            #expect(reason.contains("Binary"))
        } else {
            Issue.record("Expected empty result for binary")
        }
    }

    // MARK: - Images

    @Test("Image mode returns image data")
    func imageData() {
        let body = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header
        let result = PreviewRenderer.render(body: body, mode: .images)
        if case let .imageData(data, _, _) = result {
            #expect(data == body)
        } else {
            Issue.record("Expected imageData result")
        }
    }

    // MARK: - CSS / JavaScript

    @Test("CSS mode returns text")
    func cssText() {
        let body = Data("body { color: red; }".utf8)
        let result = PreviewRenderer.render(body: body, mode: .css)
        if case let .text(text) = result {
            #expect(text.contains("color: red"))
        } else {
            Issue.record("Expected text result")
        }
    }

    @Test("JavaScript mode returns text")
    func jsText() {
        let body = Data("function hello() { return 42; }".utf8)
        let result = PreviewRenderer.render(body: body, mode: .javascript)
        if case let .text(text) = result {
            #expect(text.contains("function hello"))
        } else {
            Issue.record("Expected text result")
        }
    }

    // MARK: - XML

    @Test("XML mode returns text")
    func xmlText() {
        let body = Data("<root><item>value</item></root>".utf8)
        let result = PreviewRenderer.render(body: body, mode: .xml)
        if case let .text(text) = result {
            #expect(text.contains("<root>"))
        } else {
            Issue.record("Expected text result")
        }
    }

    // MARK: - Beautify

    @Test("HTML beautify with flag adds indentation")
    func htmlBeautify() {
        let body = Data("<div><p>Hello</p></div>".utf8)
        let result = PreviewRenderer.render(body: body, mode: .html, beautify: true)
        if case let .text(text) = result {
            #expect(text.contains("\n"))
            #expect(text.contains("  <p>"))
        } else {
            Issue.record("Expected beautified text")
        }
    }
}
