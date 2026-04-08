import Foundation

/// XPC protocol shared between the Rockxy macOS app and RockxyHelperTool.
/// All methods use the `withReply:` pattern required by NSXPCConnection.
@objc
protocol RockxyHelperProtocol {
    /// Override system HTTP+HTTPS proxy to 127.0.0.1:<port> and associate it
    /// with the owning Rockxy app process for crash cleanup.
    func overrideSystemProxy(port: Int, ownerPID: Int32, withReply reply: @escaping (Bool, String?) -> Void)

    /// Restore original proxy settings saved before override.
    func restoreSystemProxy(withReply reply: @escaping (Bool, String?) -> Void)

    /// Check current proxy state: (isOverridden, currentPort).
    func getProxyStatus(withReply reply: @escaping (Bool, Int) -> Void)

    /// Return structured helper info: binaryVersion, buildNumber, protocolVersion.
    func getHelperInfo(withReply reply: @escaping (String, Int, Int) -> Void)

    /// Uninstall: restore proxy + prepare for removal.
    func prepareForUninstall(withReply reply: @escaping (Bool) -> Void)

    /// Install root CA certificate in system keychain and trust it for SSL.
    func installRootCertificate(_ derData: Data, withReply reply: @escaping (Bool, String?) -> Void)

    /// Remove Rockxy root CA certificate and trust settings from system keychain.
    func removeRootCertificate(withReply reply: @escaping (Bool, String?) -> Void)

    /// Verify that a certificate with the given SHA-256 fingerprint is trusted.
    func verifyRootCertificateTrusted(_ fingerprint: String, withReply reply: @escaping (Bool) -> Void)

    /// Remove stale Rockxy Root CA certificates, keeping only the one matching activeFingerprint. Returns count
    /// removed.
    func cleanupStaleCertificates(_ activeFingerprint: String, withReply reply: @escaping (Int, String?) -> Void)

    /// Set the system proxy bypass domain list on all enabled network services.
    func setBypassDomains(_ domains: [String], withReply reply: @escaping (Bool, String?) -> Void)
}
