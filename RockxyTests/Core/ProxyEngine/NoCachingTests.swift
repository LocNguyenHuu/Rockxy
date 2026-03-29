import Foundation
@testable import Rockxy
import Testing

/// NoCacheHeaderMutator tests validate header mutation logic at the utility boundary.
/// The actual forwarding paths in HTTPProxyHandler.forwardRequest and
/// HTTPSProxyRelayHandler.forwardHTTPSRequest call NoCacheHeaderMutator.apply() on the NIO
/// HTTPHeaders before upstream write. Direct forwarding-path testing requires a full NIO pipeline
/// which is impractical for unit tests. The mutator tests prove the header transformation
/// contract: when isEnabled is true, anti-cache headers are added and conditional headers removed.
struct NoCachingTests {
    @Test("adds Cache-Control and Pragma headers to empty headers")
    func addsAntiCacheHeaders() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Host", value: "example.com"),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        #expect(result.contains { $0.name == "Cache-Control" && $0.value == "no-cache, no-store, must-revalidate" })
        #expect(result.contains { $0.name == "Pragma" && $0.value == "no-cache" })
        #expect(result.contains { $0.name == "Host" && $0.value == "example.com" })
    }

    @Test("removes If-Modified-Since header")
    func removesIfModifiedSince() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Host", value: "example.com"),
            HTTPHeader(name: "If-Modified-Since", value: "Thu, 01 Jan 2025 00:00:00 GMT"),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        #expect(!result.contains { $0.name.caseInsensitiveCompare("If-Modified-Since") == .orderedSame })
    }

    @Test("removes If-None-Match header")
    func removesIfNoneMatch() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Host", value: "example.com"),
            HTTPHeader(name: "If-None-Match", value: "\"abc123\""),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        #expect(!result.contains { $0.name.caseInsensitiveCompare("If-None-Match") == .orderedSame })
    }

    @Test("replaces existing Cache-Control without duplicating")
    func replacesExistingCacheControl() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Host", value: "example.com"),
            HTTPHeader(name: "Cache-Control", value: "max-age=3600"),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        let cacheControlHeaders = result.filter { $0.name.caseInsensitiveCompare("Cache-Control") == .orderedSame }
        #expect(cacheControlHeaders.count == 1)
        #expect(cacheControlHeaders.first?.value == "no-cache, no-store, must-revalidate")
    }

    @Test("replaces existing Pragma without duplicating")
    func replacesExistingPragma() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Pragma", value: "some-value"),
            HTTPHeader(name: "Accept", value: "text/html"),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        let pragmaHeaders = result.filter { $0.name.caseInsensitiveCompare("Pragma") == .orderedSame }
        #expect(pragmaHeaders.count == 1)
        #expect(pragmaHeaders.first?.value == "no-cache")
        #expect(result.contains { $0.name == "Accept" && $0.value == "text/html" })
    }

    @Test("preserves unrelated headers")
    func preservesOtherHeaders() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Host", value: "example.com"),
            HTTPHeader(name: "Authorization", value: "Bearer token123"),
            HTTPHeader(name: "Content-Type", value: "application/json"),
            HTTPHeader(name: "Accept-Language", value: "en-US"),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        #expect(result.contains { $0.name == "Host" && $0.value == "example.com" })
        #expect(result.contains { $0.name == "Authorization" && $0.value == "Bearer token123" })
        #expect(result.contains { $0.name == "Content-Type" && $0.value == "application/json" })
        #expect(result.contains { $0.name == "Accept-Language" && $0.value == "en-US" })
    }

    @Test("handles case-insensitive header names for removal")
    func caseInsensitiveRemoval() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "if-modified-since", value: "Thu, 01 Jan 2025 00:00:00 GMT"),
            HTTPHeader(name: "IF-NONE-MATCH", value: "\"xyz\""),
            HTTPHeader(name: "cache-control", value: "public"),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        #expect(!result.contains { $0.name.caseInsensitiveCompare("If-Modified-Since") == .orderedSame })
        #expect(!result.contains { $0.name.caseInsensitiveCompare("If-None-Match") == .orderedSame })
        let cacheControlHeaders = result.filter { $0.name.caseInsensitiveCompare("Cache-Control") == .orderedSame }
        #expect(cacheControlHeaders.count == 1)
        #expect(cacheControlHeaders.first?.value == "no-cache, no-store, must-revalidate")
    }

    @Test("Mutator applied to request data model produces correct headers")
    func mutatorAppliedToRequestData() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Accept", value: "application/json"),
            HTTPHeader(name: "If-Modified-Since", value: "Thu, 01 Jan 2025"),
            HTTPHeader(name: "If-None-Match", value: "\"abc123\""),
            HTTPHeader(name: "Cache-Control", value: "max-age=3600"),
        ]

        let mutated = NoCacheHeaderMutator.apply(to: headers)

        #expect(mutated.contains { $0.name == "Cache-Control" && $0.value == "no-cache, no-store, must-revalidate" })
        #expect(mutated.contains { $0.name == "Pragma" && $0.value == "no-cache" })
        #expect(!mutated.contains { $0.name.caseInsensitiveCompare("If-Modified-Since") == .orderedSame })
        #expect(!mutated.contains { $0.name.caseInsensitiveCompare("If-None-Match") == .orderedSame })
        #expect(mutated.contains { $0.name == "Accept" })
        #expect(mutated.filter { $0.name == "Cache-Control" }.count == 1)
    }

    @Test("isEnabled reads from UserDefaults")
    func isEnabledReadsUserDefaults() {
        UserDefaults.standard.set(true, forKey: NoCacheHeaderMutator.userDefaultsKey)
        #expect(NoCacheHeaderMutator.isEnabled)
        UserDefaults.standard.set(false, forKey: NoCacheHeaderMutator.userDefaultsKey)
        #expect(!NoCacheHeaderMutator.isEnabled)
    }

    @Test("full mutation scenario with all header types present")
    func fullMutationScenario() {
        let headers: [HTTPHeader] = [
            HTTPHeader(name: "Host", value: "api.example.com"),
            HTTPHeader(name: "Cache-Control", value: "max-age=600"),
            HTTPHeader(name: "Pragma", value: "cache"),
            HTTPHeader(name: "If-Modified-Since", value: "Mon, 15 Jan 2025 10:00:00 GMT"),
            HTTPHeader(name: "If-None-Match", value: "\"etag-value\""),
            HTTPHeader(name: "Accept", value: "*/*"),
        ]

        let result = NoCacheHeaderMutator.apply(to: headers)

        #expect(result.count == 4)
        #expect(result.contains { $0.name == "Host" && $0.value == "api.example.com" })
        #expect(result.contains { $0.name == "Accept" && $0.value == "*/*" })
        #expect(result.contains { $0.name == "Cache-Control" && $0.value == "no-cache, no-store, must-revalidate" })
        #expect(result.contains { $0.name == "Pragma" && $0.value == "no-cache" })
    }
}
