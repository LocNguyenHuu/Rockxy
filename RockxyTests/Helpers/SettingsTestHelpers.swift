import Foundation
@testable import Rockxy

/// All UserDefaults keys written by AppSettingsStorage.
let appSettingsKeys = [
    "com.amunx.Rockxy.proxyPort",
    "com.amunx.Rockxy.autoStart",
    "com.amunx.Rockxy.recordOnLaunch",
    "com.amunx.Rockxy.onlyListenOnLocalhost",
    "com.amunx.Rockxy.listenIPv6",
    "com.amunx.Rockxy.autoSelectPort",
]

/// Shared lock ensuring tests that mutate AppSettings UserDefaults keys do not race.
let settingsTestLock = NSLock()

/// Captures current UserDefaults values for all AppSettings keys, acquires the shared lock,
/// and returns a cleanup closure that restores originals and unlocks.
func installSettingsTestGuard() -> (() -> Void) {
    settingsTestLock.lock()
    let defaults = UserDefaults.standard
    let originals = appSettingsKeys.map { ($0, defaults.object(forKey: $0)) }

    return {
        for (key, original) in originals {
            if let original {
                defaults.set(original, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
        settingsTestLock.unlock()
    }
}
