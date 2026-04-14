import Foundation
import Security

/// Testable caller-validation primitives shared between the helper and app test targets.
/// `ConnectionValidator` delegates to these for its two-layer validation:
/// 1. Certificate chain comparison (same-developer check)
/// 2. Bundle identity requirement (allowlist check)
enum CallerValidation {
    // MARK: Internal

    /// Compares two DER-encoded certificate chains byte-by-byte.
    /// Returns `true` if both chains have the same length and every certificate matches.
    static func certificateDataChainsMatch(_ lhs: [Data], _ rhs: [Data]) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        return zip(lhs, rhs).allSatisfy { $0 == $1 }
    }

    /// Checks whether a caller process satisfies any of the allowed bundle identifiers
    /// by constructing a `SecRequirement` for each identifier and validating the caller's `SecCode`.
    static func callerSatisfiesAnyIdentifier(
        callerCode: SecCode,
        allowedIdentifiers: [String]
    )
        -> Bool
    {
        for identifier in allowedIdentifiers {
            var requirement: SecRequirement?
            let status = SecRequirementCreateWithString(
                "identifier \"\(identifier)\" and anchor apple generic" as CFString,
                [],
                &requirement
            )
            guard status == errSecSuccess, let requirement else {
                continue
            }
            if SecCodeCheckValidity(callerCode, [], requirement) == errSecSuccess {
                return true
            }
        }
        return false
    }

    /// Extracts DER certificate data from `SecCertificate` objects for comparison.
    static func certificateDERData(from certificates: [SecCertificate]) -> [Data] {
        certificates.map { SecCertificateCopyData($0) as Data }
    }

    // MARK: - Full Caller Validation by PID

    /// Performs the same two-layer validation as `ConnectionValidator.isValidCaller(_:)`
    /// but accepts a `pid_t` directly, making it testable without a real `NSXPCConnection`.
    ///
    /// Layer 1: Extracts certificate chains for the current process and the caller PID,
    ///          then compares them byte-by-byte (same-developer check).
    /// Layer 2: Constructs `SecRequirement` for each allowed identifier and validates
    ///          the caller's `SecCode` against them (bundle identity check).
    static func validateCaller(pid: pid_t, allowedIdentifiers: [String]) -> Bool {
        guard let selfCerts = certificatesForSelf() else {
            return false
        }
        guard let callerCerts = certificatesForProcess(pid: pid) else {
            return false
        }

        let selfDER = certificateDERData(from: selfCerts)
        let callerDER = certificateDERData(from: callerCerts)
        guard certificateDataChainsMatch(selfDER, callerDER) else {
            return false
        }

        guard let callerCode = secCodeForPID(pid) else {
            return false
        }
        return callerSatisfiesAnyIdentifier(callerCode: callerCode, allowedIdentifiers: allowedIdentifiers)
    }

    // MARK: - Security Framework Helpers

    static func secCodeForPID(_ pid: pid_t) -> SecCode? {
        let attributes = [kSecGuestAttributePid: pid] as CFDictionary
        var code: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, attributes, [], &code)
        guard status == errSecSuccess else {
            return nil
        }
        return code
    }

    static func certificatesForSelf() -> [SecCertificate]? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let selfCode = code else {
            return nil
        }
        return certificatesFromCode(selfCode)
    }

    static func certificatesForProcess(pid: pid_t) -> [SecCertificate]? {
        guard let code = secCodeForPID(pid) else {
            return nil
        }
        return certificatesFromCode(code)
    }

    // MARK: Private

    private static func certificatesFromCode(_ code: SecCode) -> [SecCertificate]? {
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess,
              let sc = staticCode else
        {
            return nil
        }
        guard SecStaticCodeCheckValidity(sc, SecCSFlags([]), nil) == errSecSuccess else {
            return nil
        }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(
            sc, SecCSFlags(rawValue: kSecCSSigningInformation), &info
        ) == errSecSuccess,
            let dict = info as? [String: Any],
            let certs = dict[kSecCodeInfoCertificates as String] as? [SecCertificate],
            !certs.isEmpty else
        {
            return nil
        }
        return certs
    }
}
