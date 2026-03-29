import Foundation

// Defines `ProxyRestoreCommandBuilder`, which builds proxy restore command values for
// traffic capture and system proxy coordination.

// MARK: - ProxyRestoreCommandBuilder

enum ProxyRestoreCommandBuilder {
    static func commands(service: String, snapshot: ServiceProxySnapshot) -> [[String]] {
        var commands: [[String]] = [
            ["-setwebproxystate", service, "off"],
            ["-setsecurewebproxystate", service, "off"],
            ["-setsocksfirewallproxystate", service, "off"],
        ]

        if snapshot.httpEnabled {
            commands.append(["-setwebproxy", service, snapshot.httpHost, String(snapshot.httpPort)])
            commands.append(["-setwebproxystate", service, "on"])
        }

        if snapshot.httpsEnabled {
            commands.append([
                "-setsecurewebproxy", service, snapshot.httpsHost, String(snapshot.httpsPort),
            ])
            commands.append(["-setsecurewebproxystate", service, "on"])
        }

        if snapshot.socksEnabled {
            commands.append([
                "-setsocksfirewallproxy", service, snapshot.socksHost, String(snapshot.socksPort),
            ])
            commands.append(["-setsocksfirewallproxystate", service, "on"])
        }

        return commands
    }
}
