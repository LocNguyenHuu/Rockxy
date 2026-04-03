import Foundation
@testable import Rockxy
import Testing

// Regression tests for autoSelectPort default migration in settings storage.

@Suite(.serialized)
struct AutoSelectPortMigrationTests {
    // MARK: Internal

    @Test("unset key loads as true (new default)")
    func unsetKeyDefaultsToTrue() {
        let cleanup = installSettingsTestGuard()
        defer { cleanup() }

        UserDefaults.standard.removeObject(forKey: Self.key)
        let settings = AppSettingsStorage.load()
        #expect(settings.autoSelectPort == true)
    }

    @Test("explicitly set to false loads as false")
    func explicitFalseRespected() {
        let cleanup = installSettingsTestGuard()
        defer { cleanup() }

        UserDefaults.standard.set(false, forKey: Self.key)
        let settings = AppSettingsStorage.load()
        #expect(settings.autoSelectPort == false)
    }

    @Test("explicitly set to true loads as true")
    func explicitTrueRespected() {
        let cleanup = installSettingsTestGuard()
        defer { cleanup() }

        UserDefaults.standard.set(true, forKey: Self.key)
        let settings = AppSettingsStorage.load()
        #expect(settings.autoSelectPort == true)
    }

    // MARK: Private

    private static let key = "com.amunx.Rockxy.autoSelectPort"
}
