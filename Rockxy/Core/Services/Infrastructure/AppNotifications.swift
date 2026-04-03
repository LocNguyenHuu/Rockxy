import Foundation

/// Application-wide `NotificationCenter` names for cross-component communication.
/// Used where direct dependency injection would create tight coupling between
/// the proxy engine, certificate manager, session buffer, and UI layers.
extension Notification.Name {
    static let proxyDidStart = Notification.Name("com.amunx.Rockxy.proxyDidStart")
    static let proxyDidStop = Notification.Name("com.amunx.Rockxy.proxyDidStop")
    static let systemProxyDidChange = Notification.Name("com.amunx.Rockxy.systemProxyDidChange")
    static let certificateStatusChanged = Notification.Name("com.amunx.Rockxy.certificateStatusChanged")
    static let helperStatusChanged = Notification.Name("com.amunx.Rockxy.helperStatusChanged")
    static let sessionCleared = Notification.Name("com.amunx.Rockxy.sessionCleared")
    static let bufferEvictionRequested = Notification.Name("com.amunx.Rockxy.bufferEvictionRequested")
    static let showCertificateWizard = Notification.Name("com.amunx.Rockxy.showCertificateWizard")
    static let welcomeDidComplete = Notification.Name("com.amunx.Rockxy.welcomeDidComplete")
    static let showWelcomeSheet = Notification.Name("com.amunx.Rockxy.showWelcomeSheet")
    static let systemProxyVPNWarning = Notification.Name("com.amunx.Rockxy.systemProxyVPNWarning")
    static let rootCANotTrusted = Notification.Name("com.amunx.Rockxy.rootCANotTrusted")
    static let tlsMitmRejected = Notification.Name("com.amunx.Rockxy.tlsMitmRejected")
    static let bypassProxyListDidChange = Notification.Name("com.amunx.Rockxy.bypassProxyListDidChange")
    static let allowListDidChange = Notification.Name("com.amunx.Rockxy.allowListDidChange")
    static let breakpointHit = Notification.Name("com.amunx.Rockxy.breakpointHit")
    static let breakpointRuleCreated = Notification.Name("com.amunx.Rockxy.breakpointRuleCreated")
    static let rulesDidChange = Notification.Name("com.amunx.Rockxy.rulesDidChange")
    static let openDiffWindow = Notification.Name("com.amunx.Rockxy.openDiffWindow")
    static let openComposeWindow = Notification.Name("com.amunx.Rockxy.openComposeWindow")
    static let openMapLocalWindow = Notification.Name("com.amunx.Rockxy.openMapLocalWindow")
    static let openMapRemoteWindow = Notification.Name("com.amunx.Rockxy.openMapRemoteWindow")
    static let openNetworkConditionsWindow = Notification.Name("com.amunx.Rockxy.openNetworkConditionsWindow")
}
