import Foundation
@testable import Rockxy
import Testing

// Regression tests for `MimeTypeResolver` in the core utilities layer.

struct MimeTypeResolverTests {
    @Test("JSON extension resolves to application/json")
    func jsonMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/data.json") == "application/json")
    }

    @Test("JavaScript extension resolves to application/javascript")
    func jsMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/app.js") == "application/javascript")
        #expect(MimeTypeResolver.mimeType(for: "/tmp/module.mjs") == "application/javascript")
    }

    @Test("CSS extension resolves to text/css")
    func cssMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/style.css") == "text/css")
    }

    @Test("HTML extension resolves to text/html")
    func htmlMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/index.html") == "text/html")
        #expect(MimeTypeResolver.mimeType(for: "/tmp/page.htm") == "text/html")
    }

    @Test("PNG extension resolves to image/png")
    func pngMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/icon.png") == "image/png")
    }

    @Test("JPEG extensions resolve correctly")
    func jpegMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/photo.jpg") == "image/jpeg")
        #expect(MimeTypeResolver.mimeType(for: "/tmp/photo.jpeg") == "image/jpeg")
    }

    @Test("Unknown extension falls back to application/octet-stream")
    func unknownFallback() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/file.xyz") == "application/octet-stream")
        #expect(MimeTypeResolver.mimeType(for: "/tmp/noext") == "application/octet-stream")
    }

    @Test("Extension matching is case-insensitive")
    func caseInsensitive() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/data.JSON") == "application/json")
        #expect(MimeTypeResolver.mimeType(for: "/tmp/style.CSS") == "text/css")
    }

    @Test("URL-based MIME detection works")
    func urlBasedMime() throws {
        let url = try #require(URL(string: "https://example.com/api/data.json"))
        #expect(MimeTypeResolver.mimeType(for: url) == "application/json")
    }

    @Test("inferExtension from Content-Type returns correct extension")
    func inferFromContentType() {
        #expect(MimeTypeResolver.inferExtension(fromContentType: "application/json") == "json")
        #expect(MimeTypeResolver.inferExtension(fromContentType: "text/html") == "html")
        #expect(MimeTypeResolver.inferExtension(fromContentType: "image/png") == "png")
    }

    @Test("inferExtension handles Content-Type with parameters")
    func inferFromContentTypeWithParams() {
        #expect(MimeTypeResolver.inferExtension(fromContentType: "application/json; charset=utf-8") == "json")
        #expect(MimeTypeResolver.inferExtension(fromContentType: "text/html; charset=UTF-8") == "html")
    }

    @Test("inferExtension returns nil for unknown Content-Type")
    func inferUnknownContentType() {
        #expect(MimeTypeResolver.inferExtension(fromContentType: "application/x-custom") == nil)
        #expect(MimeTypeResolver.inferExtension(fromContentType: nil) == nil)
    }

    @Test("Map file resolves to application/json")
    func mapFileMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/bundle.js.map") == "application/json")
    }

    @Test("WASM file resolves to application/wasm")
    func wasmMime() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/module.wasm") == "application/wasm")
    }

    @Test("Font files resolve correctly")
    func fontMimes() {
        #expect(MimeTypeResolver.mimeType(for: "/tmp/font.woff") == "font/woff")
        #expect(MimeTypeResolver.mimeType(for: "/tmp/font.woff2") == "font/woff2")
        #expect(MimeTypeResolver.mimeType(for: "/tmp/font.ttf") == "font/ttf")
    }
}
