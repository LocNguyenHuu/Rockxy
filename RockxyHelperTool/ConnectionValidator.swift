import Foundation
import os
import Security

/// XPC Caller Validation Model (two-layer defense-in-depth):
///
/// 1. **Certificate chain comparison** (Pearcleaner pattern): extracts the helper's own
///    signing certificate chain and compares it byte-by-byte against the caller's.
///    Validates that both binaries were signed by the same developer certificate.
///    Immune to Info.plist tampering since certificates are embedded in the code signature.
///
/// 2. **Bundle identity requirement** (Apple SecRequirement pattern): validates the caller
///    matches one of the configured Rockxy app bundle identifiers, not just any app sharing
///    the same developer certificate. Uses the connection's audit token for
///    PID-race-resistant caller identification, then checks against a `SecRequirement`
///    string for each allowed bundle identifier.
///
/// Both checks must pass for a connection to be accepted.
///
/// References:
/// - Pearcleaner `CodesignCheck.swift` for certificate chain comparison
/// - smjobbless `XPCServer.swift` for `SecRequirement`-based audit token validation
/// - Apple `SecCodeCheckValidity` / `SecRequirementCreateWithString` documentation
///
enum ConnectionValidator {
    // MARK: Internal

    // MARK: - Public API

    static func isValidCaller(_ connection: NSXPCConnection) -> Bool {
        let pid = connection.processIdentifier

        // Primary path: delegate both layers to the shared CallerValidation primitive.
        // This uses PID-based SecCode lookup (equivalent to the audit-token fallback path).
        let pidValid = CallerValidation.validateCaller(
            pid: pid,
            allowedIdentifiers: allowedCallerIdentifiers
        )

        if pidValid {
            // If PID-based validation passed, also try audit-token-based SecCode for
            // defense-in-depth (audit tokens are immune to PID recycling attacks).
            if let auditCode = codeFromAuditToken(connection: connection) {
                let auditSatisfied = CallerValidation.callerSatisfiesAnyIdentifier(
                    callerCode: auditCode,
                    allowedIdentifiers: allowedCallerIdentifiers
                )
                if !auditSatisfied {
                    logger.error("SECURITY: PID validation passed but audit token check failed for pid \(pid)")
                    return false
                }
            }
            logger.info("SECURITY: Two-layer validation passed for pid \(pid)")
            return true
        }

        logger.error("SECURITY: Caller validation failed for pid \(pid)")
        return false
    }

    // MARK: Private

    private static let logger = Logger(
        subsystem: RockxyIdentity.current.logSubsystem,
        category: "ConnectionValidator"
    )

    private static let allowedCallerIdentifiers = RockxyIdentity.current.allowedCallerIdentifiers

    /// Attempts to obtain a `SecCode` using the connection's audit token.
    ///
    /// `NSXPCConnection` stores the audit token internally but the property was not
    /// publicly exposed until macOS 15 / Xcode 16 SDK. We access it via KVC as a
    /// `Data`-valued property, which has been stable since macOS 10.7. If KVC access
    /// fails (e.g., Apple removes or renames the property), we return nil and the
    /// caller falls back to PID-based lookup.
    private static func codeFromAuditToken(connection: NSXPCConnection) -> SecCode? {
        // KVC access to the audit token. The underlying Obj-C property wraps
        // audit_token_t in an NSData when accessed via valueForKey:.
        guard let tokenValue = connection.value(forKey: "auditToken") else {
            logger.debug("SECURITY: auditToken KVC returned nil")
            return nil
        }

        // The KVC result may come back as Data (NSData) containing the raw audit_token_t bytes.
        let tokenData: Data
        if let data = tokenValue as? Data {
            tokenData = data
        } else {
            // If the runtime returns audit_token_t as a struct wrapped in NSValue,
            // extract its bytes. This branch handles future SDK changes gracefully.
            var token = audit_token_t()
            let expectedSize = MemoryLayout<audit_token_t>.size
            guard let nsValue = tokenValue as? NSValue else {
                logger.debug("SECURITY: auditToken KVC returned unexpected type: \(type(of: tokenValue))")
                return nil
            }
            nsValue.getValue(&token, size: expectedSize)
            tokenData = Data(bytes: &token, count: expectedSize)
        }

        guard tokenData.count == MemoryLayout<audit_token_t>.size else {
            logger.debug("SECURITY: auditToken data size mismatch: \(tokenData.count)")
            return nil
        }

        let attributes = [kSecGuestAttributeAudit: tokenData] as CFDictionary

        var code: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, attributes, [], &code)

        guard status == errSecSuccess, let code else {
            logger.debug("SecCodeCopyGuestWithAttributes (audit token) failed: \(status)")
            return nil
        }

        return code
    }
}
