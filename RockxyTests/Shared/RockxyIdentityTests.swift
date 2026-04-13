import Foundation
@testable import Rockxy
import Testing

struct RockxyIdentityTests {
    // MARK: - Display Name

    @Test("displayName resolves from CFBundleDisplayName")
    func displayNameFromBundleDisplayName() {
        let identity = RockxyIdentity(infoDictionary: [
            "CFBundleDisplayName": "Rockxy",
            "CFBundleName": "FallbackName",
        ])
        #expect(identity.displayName == "Rockxy")
    }

    @Test("displayName falls back to CFBundleName")
    func displayNameFallbackToBundleName() {
        let identity = RockxyIdentity(infoDictionary: [
            "CFBundleName": "Rockxy App",
        ])
        #expect(identity.displayName == "Rockxy App")
    }

    @Test("displayName falls back to Rockxy when both keys missing")
    func displayNameFallbackToDefault() {
        let identity = RockxyIdentity(infoDictionary: [:])
        #expect(identity.displayName == "Rockxy")
    }

    // MARK: - Allowlist Parsing

    @Test("allowedCallerIdentifiers parses space-separated list")
    func allowlistParsesSpaceSeparated() {
        let identity = RockxyIdentity(infoDictionary: [
            "RockxyAllowedCallerIdentifiers": "com.a com.b com.c",
        ])
        #expect(identity.allowedCallerIdentifiers == ["com.a", "com.b", "com.c"])
    }

    @Test("Default allowlist includes both community and bare identifiers")
    func defaultAllowlist() {
        let identity = RockxyIdentity(infoDictionary: [
            "RockxyAllowedCallerIdentifiers": "com.amunx.rockxy.community com.amunx.rockxy",
        ])
        #expect(identity.allowedCallerIdentifiers.contains("com.amunx.rockxy.community"))
        #expect(identity.allowedCallerIdentifiers.contains("com.amunx.rockxy"))
    }

    @Test("Unknown identifier is not in allowlist")
    func unknownIdentifierNotInAllowlist() {
        let identity = RockxyIdentity(infoDictionary: [
            "RockxyAllowedCallerIdentifiers": "com.amunx.rockxy.community com.amunx.rockxy",
        ])
        #expect(!identity.allowedCallerIdentifiers.contains("com.evil.app"))
    }

    @Test("Missing allowlist key falls back to app bundle identifier")
    func allowlistFallbackToAppBundleId() {
        let identity = RockxyIdentity(infoDictionary: [:])
        #expect(identity.allowedCallerIdentifiers == ["com.amunx.rockxy.community"])
    }

    // MARK: - Namespace Defaults

    @Test("Missing keys resolve to expected defaults")
    func defaultValues() {
        let identity = RockxyIdentity(infoDictionary: [:])
        #expect(identity.familyNamespace == "com.amunx.rockxy")
        #expect(identity.appBundleIdentifier == "com.amunx.rockxy.community")
        #expect(identity.helperBundleIdentifier == "com.amunx.rockxy.helper")
        #expect(identity.helperMachServiceName == "com.amunx.rockxy.helper")
        #expect(identity.sharedCertificateLabelPrefix == "com.amunx.rockxy.rootCA")
    }

    @Test("Custom keys override defaults")
    func customValues() {
        let identity = RockxyIdentity(infoDictionary: [
            "RockxyFamilyNamespace": "com.test.custom",
            "CFBundleIdentifier": "com.test.custom.app",
        ])
        #expect(identity.familyNamespace == "com.test.custom")
        #expect(identity.appBundleIdentifier == "com.test.custom.app")
    }

    // MARK: - Derived Properties

    @Test("defaultsKey prefixes correctly")
    func defaultsKeyPrefix() {
        let identity = RockxyIdentity(infoDictionary: [
            "RockxyDefaultsPrefix": "com.test",
        ])
        #expect(identity.defaultsKey("favorites") == "com.test.favorites")
    }

    @Test("notificationName uses notification prefix")
    func notificationNamePrefix() {
        let identity = RockxyIdentity(infoDictionary: [
            "RockxyNotificationPrefix": "com.test.notify",
        ])
        #expect(identity.notificationName("rulesChanged").rawValue == "com.test.notify.rulesChanged")
    }
}
