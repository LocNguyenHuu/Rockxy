import AppKit
import ServiceManagement

@MainActor
enum HelperRecoveryPresenter {
    // MARK: Internal

    static func presentForceReset(stopCapture: (() -> Void)? = nil) {
        let confirmation = NSAlert()
        confirmation.alertStyle = .critical
        confirmation.messageText = String(localized: "Force reset the Rockxy Helper?")
        confirmation.informativeText = String(
            localized: """
            Rockxy will stop capture, request administrator approval, remove stale launchd and privileged helper files, \
            then recheck the helper. System proxy settings may be restored during the reset.

            Use this only when install, uninstall, and recheck are stuck.
            """
        )
        confirmation.addButton(withTitle: String(localized: "Force Reset"))
        confirmation.addButton(withTitle: String(localized: "Cancel"))

        guard confirmation.runModal() == .alertFirstButtonReturn else {
            return
        }

        runForceReset(stopCapture: stopCapture, resetBackgroundItems: false)
    }

    // MARK: Private

    private static func runForceReset(
        stopCapture: (() -> Void)?,
        resetBackgroundItems: Bool
    ) {
        NotificationCenter.default.post(name: .stopProxyRequested, object: nil)
        stopCapture?()

        Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 750_000_000)
                let result = try await HelperManager.shared.forceRemoveHelper(
                    resetBackgroundItems: resetBackgroundItems
                )
                await ReadinessCoordinator.shared.deepRefresh()
                presentSuccess(result: result)
            } catch {
                presentFailure(
                    error: error,
                    stopCapture: stopCapture,
                    canTryBackgroundItemsReset: !resetBackgroundItems
                )
            }
        }
    }

    private static func presentSuccess(result: HelperManager.ForceRemoveResult) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = String(localized: "Helper reset complete")
        alert.informativeText = String(
            localized: """
            \(result.localizedSummary)

            Install the helper again, then approve Rockxy in System Settings > Login Items if macOS asks.
            """
        )
        alert.addButton(withTitle: String(localized: "Install Helper"))
        alert.addButton(withTitle: String(localized: "Open Login Items"))
        alert.addButton(withTitle: String(localized: "OK"))

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            Task { @MainActor in
                do {
                    try await HelperManager.shared.install()
                    await ReadinessCoordinator.shared.deepRefresh()
                    if HelperManager.shared.status == .requiresApproval {
                        SMAppService.openSystemSettingsLoginItems()
                    }
                } catch {
                    presentInstallFailure(error)
                }
            }
        case .alertSecondButtonReturn:
            SMAppService.openSystemSettingsLoginItems()
        default:
            break
        }
    }

    private static func presentFailure(
        error: Error,
        stopCapture: (() -> Void)?,
        canTryBackgroundItemsReset: Bool
    ) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = String(localized: "Helper reset failed")
        alert.informativeText = error.localizedDescription

        if canTryBackgroundItemsReset {
            alert.addButton(withTitle: String(localized: "Try Background Items Reset"))
        }
        alert.addButton(withTitle: String(localized: "Copy Details"))
        alert.addButton(withTitle: String(localized: "OK"))

        let response = alert.runModal()
        if canTryBackgroundItemsReset, response == .alertFirstButtonReturn {
            presentBackgroundItemsResetConfirmation(stopCapture: stopCapture)
            return
        }

        let copyDetailsResponse: NSApplication.ModalResponse = canTryBackgroundItemsReset
            ? .alertSecondButtonReturn
            : .alertFirstButtonReturn
        if response == copyDetailsResponse {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(error.localizedDescription, forType: .string)
        }
    }

    private static func presentBackgroundItemsResetConfirmation(stopCapture: (() -> Void)?) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = String(localized: "Reset macOS Login and Background Items data?")
        alert.informativeText = String(
            localized: """
            This runs sfltool resetbtm after removing Rockxy helper files. It can reset Background Items state \
            for other apps, so use it only when the normal force reset cannot recover Rockxy.
            """
        )
        alert.addButton(withTitle: String(localized: "Reset Background Items"))
        alert.addButton(withTitle: String(localized: "Cancel"))

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        runForceReset(stopCapture: stopCapture, resetBackgroundItems: true)
    }

    private static func presentInstallFailure(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Helper install failed")
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: String(localized: "OK"))
        alert.runModal()
    }
}
