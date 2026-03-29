import Foundation

/// Configuration for the local proxy server. Controls which address and port the
/// server binds to.
struct ProxyConfiguration {
    static let `default` = ProxyConfiguration(
        port: 9090,
        listenAddress: "127.0.0.1",
        listenIPv6: false
    )

    let port: Int
    let listenAddress: String
    let listenIPv6: Bool
}
