import Foundation

extension HelperManager {
    enum ForceRemoveError: LocalizedError, Equatable {
        case commandFailed(exitCode: Int32, output: String)
        case commandTerminated(signal: Int32, output: String)

        var errorDescription: String? {
            switch self {
            case let .commandFailed(exitCode, output):
                if output.localizedCaseInsensitiveContains("User canceled") {
                    return String(localized: "The administrator authorization prompt was cancelled.")
                }
                if output.isEmpty {
                    return String(localized: "Force reset failed with exit code \(exitCode).")
                }
                return String(localized: "Force reset failed with exit code \(exitCode): \(output)")
            case let .commandTerminated(signal, output):
                if output.isEmpty {
                    return String(localized: "Force reset was interrupted by signal \(signal).")
                }
                return String(localized: "Force reset was interrupted by signal \(signal): \(output)")
            }
        }
    }

    struct ForceRemoveResult: Equatable {
        let resetBackgroundItems: Bool
        let commandOutput: String

        var localizedSummary: String {
            if resetBackgroundItems {
                return String(
                    localized: """
                    Rockxy removed stale helper files and asked macOS to reset Login and Background Items data.
                    """
                )
            }

            return String(localized: "Rockxy removed stale helper files and launchd registration state.")
        }
    }

    nonisolated static func forceRemoveShellScript(
        identity: RockxyIdentity,
        resetBackgroundItems: Bool
    )
        -> String
    {
        let label = shellQuote(identity.helperMachServiceName)
        let helperPath = shellQuote("/Library/PrivilegedHelperTools/\(identity.helperMachServiceName)")
        let launchDaemonPath = shellQuote("/Library/LaunchDaemons/\(identity.helperPlistName)")
        let helperProcessPattern = shellQuote("[R]ockxyHelperTool")
        var commands = [
            consoleUserShellPrelude(),
            directWatchdogCleanupCommand(identity: identity),
            "/bin/launchctl bootout system/\(label) 2>/dev/null || true",
            "/usr/bin/pkill -f \(helperProcessPattern) 2>/dev/null || true",
            "/bin/rm -f \(helperPath)",
            "/bin/rm -f \(launchDaemonPath)",
        ]

        if resetBackgroundItems {
            commands.append("/usr/bin/sfltool resetbtm 2>/dev/null || true")
        }

        commands.append(contentsOf: [
            loadedJobVerificationCommand(label: label),
            "if [ -e \(helperPath) ]; then echo 'Rockxy helper binary still exists.' >&2; exit 21; fi",
            "if [ -e \(launchDaemonPath) ]; then echo 'Rockxy launch daemon plist still exists.' >&2; exit 22; fi",
            "echo 'Rockxy helper registration files were removed.'",
        ])

        return commands.joined(separator: "; ")
    }

    nonisolated static func shouldUseLegacyInstallFallbackForCurrentBundle(
        bundleURL: URL = Bundle.main.bundleURL
    ) -> Bool {
        let path = bundleURL.path
        return path.contains("/DerivedData/") && path.contains("/Build/Products/")
    }

    nonisolated static func legacyInstalledHelperPath(identity: RockxyIdentity) -> String {
        "/Library/PrivilegedHelperTools/\(identity.helperMachServiceName)"
    }

    nonisolated static func legacyLaunchDaemonPlistPath(identity: RockxyIdentity) -> String {
        "/Library/LaunchDaemons/\(identity.helperPlistName)"
    }

    nonisolated static func legacyInstallShellScript(
        identity: RockxyIdentity,
        bundledHelperPath: String
    )
        -> String
    {
        let label = shellQuote(identity.helperMachServiceName)
        let sourceHelperPath = shellQuote(bundledHelperPath)
        let installedHelperPath = legacyInstalledHelperPath(identity: identity)
        let launchDaemonPlistPath = legacyLaunchDaemonPlistPath(identity: identity)
        let helperPath = shellQuote(installedHelperPath)
        let launchDaemonPath = shellQuote(launchDaemonPlistPath)
        let plist = legacyLaunchDaemonPlist(identity: identity, helperPath: installedHelperPath)
        let plistBase64 = shellQuote(Data(plist.utf8).base64EncodedString())

        return [
            consoleUserShellPrelude(),
            directWatchdogCleanupCommand(identity: identity),
            "/bin/launchctl bootout system/\(label) 2>/dev/null || true",
            "/usr/bin/pkill -f '[R]ockxyHelperTool' 2>/dev/null || true",
            "/usr/bin/install -o root -g wheel -m 755 \(sourceHelperPath) \(helperPath)",
            "/bin/echo \(plistBase64) | /usr/bin/base64 -D > \(launchDaemonPath)",
            "/usr/sbin/chown root:wheel \(launchDaemonPath)",
            "/bin/chmod 644 \(launchDaemonPath)",
            "/bin/launchctl bootstrap system \(launchDaemonPath)",
            "/bin/launchctl enable system/\(label) 2>/dev/null || true",
            "/bin/launchctl kickstart -k system/\(label) 2>/dev/null || true",
            "if ! /bin/launchctl print system/\(label) >/dev/null 2>&1; then echo 'Rockxy helper launchd job was not registered.' >&2; exit 30; fi",
            "echo 'Rockxy helper was installed into the privileged helper location.'",
        ].joined(separator: "; ")
    }

    nonisolated static func privilegedAppleScript(for shellScript: String) -> String {
        let escapedScript = shellScript
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "do shell script \"\(escapedScript)\" with administrator privileges"
    }

    nonisolated static func runPrivilegedShellScript(_ shellScript: String) async throws -> String {
        let appleScript = privilegedAppleScript(for: shellScript)

        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", appleScript]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard process.terminationStatus == 0 else {
                if process.terminationReason == .uncaughtSignal {
                    throw ForceRemoveError.commandTerminated(
                        signal: process.terminationStatus,
                        output: output
                    )
                }

                throw ForceRemoveError.commandFailed(
                    exitCode: process.terminationStatus,
                    output: output
                )
            }

            return output
        }.value
    }

    nonisolated private static func loadedJobVerificationCommand(label: String) -> String {
        "if /bin/launchctl print system/\(label) >/dev/null 2>&1; then " +
            "echo 'Rockxy helper launchd job is still loaded.' >&2; exit 20; fi"
    }

    nonisolated private static func directWatchdogCleanupCommand(identity: RockxyIdentity) -> String {
        let label = shellQuote("\(identity.appBundleIdentifier).direct-proxy-watchdog")
        let backupPath = "\"$CONSOLE_HOME/Library/Application Support/\(shellDoubleQuotedPathComponent(identity.appSupportDirectoryName))/proxy-backup-direct.plist\""
        return """
        if [ -n "$CONSOLE_UID" ]; then /bin/launchctl bootout gui/$CONSOLE_UID/\(label) 2>/dev/null || true; fi; \
        /bin/rm -f \(backupPath) 2>/dev/null || true
        """
    }

    nonisolated private static func consoleUserShellPrelude() -> String {
        """
        CONSOLE_USER=$(/usr/bin/stat -f %Su /dev/console 2>/dev/null || true); \
        if [ -n "$CONSOLE_USER" ] && [ "$CONSOLE_USER" != "root" ]; then \
        CONSOLE_UID=$(/usr/bin/id -u "$CONSOLE_USER" 2>/dev/null || true); \
        CONSOLE_HOME=$(/usr/bin/dscl . -read "/Users/$CONSOLE_USER" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}' || true); \
        else CONSOLE_UID=""; CONSOLE_HOME=""; fi
        """
    }

    nonisolated private static func legacyLaunchDaemonPlist(identity: RockxyIdentity, helperPath: String) -> String {
        let associatedBundleIdentifiers = identity.allowedCallerIdentifiers
            .map { "\t\t<string>\(xmlEscaped($0))</string>" }
            .joined(separator: "\n")
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>Label</key>
        \t<string>\(xmlEscaped(identity.helperMachServiceName))</string>
        \t<key>ProgramArguments</key>
        \t<array>
        \t\t<string>\(xmlEscaped(helperPath))</string>
        \t</array>
        \t<key>MachServices</key>
        \t<dict>
        \t\t<key>\(xmlEscaped(identity.helperMachServiceName))</key>
        \t\t<true/>
        \t</dict>
        \t<key>AssociatedBundleIdentifiers</key>
        \t<array>
        \(associatedBundleIdentifiers)
        \t</array>
        </dict>
        </plist>
        """
    }

    nonisolated private static func xmlEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    nonisolated private static func shellDoubleQuotedPathComponent(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")
    }

    nonisolated private static func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
