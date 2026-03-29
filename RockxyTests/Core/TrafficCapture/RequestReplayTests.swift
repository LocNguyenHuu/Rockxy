import Foundation
@testable import Rockxy
import Testing

// Regression tests for `RequestReplay` in the core traffic capture layer.

struct RequestReplayTests {
    @Test("proxyBypassSession disables HTTP proxy")
    func httpProxyDisabled() {
        let config = RequestReplay.proxyBypassSession.configuration
        let dict = config.connectionProxyDictionary ?? [:]
        if let httpEnable = dict[kCFNetworkProxiesHTTPEnable as String] as? Bool {
            #expect(httpEnable == false)
        } else if let httpEnable = dict[kCFNetworkProxiesHTTPEnable as String] as? Int {
            #expect(httpEnable == 0)
        }
    }

    @Test("proxyBypassSession disables HTTPS proxy")
    func httpsProxyDisabled() {
        let config = RequestReplay.proxyBypassSession.configuration
        let dict = config.connectionProxyDictionary ?? [:]
        if let httpsEnable = dict[kCFNetworkProxiesHTTPSEnable as String] as? Bool {
            #expect(httpsEnable == false)
        } else if let httpsEnable = dict[kCFNetworkProxiesHTTPSEnable as String] as? Int {
            #expect(httpsEnable == 0)
        }
    }

    @Test("proxyBypassSession is not URLSession.shared")
    func notSharedSession() {
        #expect(RequestReplay.proxyBypassSession !== URLSession.shared)
    }
}
