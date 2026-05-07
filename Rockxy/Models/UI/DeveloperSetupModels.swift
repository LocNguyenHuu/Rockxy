import Foundation

// MARK: - SetupTargetCategory

enum SetupTargetCategory: String, CaseIterable, Identifiable {
    case pinned
    case runtime
    case browserClient
    case device
    case framework
    case environment
    case savedProfile

    // MARK: Internal

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .pinned:
            String(localized: "Pinned")
        case .runtime:
            String(localized: "Runtimes")
        case .browserClient:
            String(localized: "Browsers & Clients")
        case .device:
            String(localized: "Devices")
        case .framework:
            String(localized: "Frameworks")
        case .environment:
            String(localized: "Environments")
        case .savedProfile:
            String(localized: "Saved Profiles")
        }
    }
}

// MARK: - SetupTargetSection

struct SetupTargetSection: Identifiable, Equatable {
    let category: SetupTargetCategory
    let targets: [SetupTarget]

    var id: String {
        category.id
    }
}

// MARK: - SetupSupportStatus

enum SetupSupportStatus: String, Equatable {
    case availableNow
    case guideOnly
    case notYetSupported

    // MARK: Internal

    var title: String {
        switch self {
        case .availableNow:
            String(localized: "Available now")
        case .guideOnly:
            String(localized: "Guide only")
        case .notYetSupported:
            String(localized: "Not yet supported")
        }
    }

    var bannerTitle: String {
        switch self {
        case .availableNow:
            String(localized: "Setup guide available")
        case .guideOnly:
            String(localized: "Guide-only target")
        case .notYetSupported:
            String(localized: "Not yet supported")
        }
    }
}

// MARK: - SetupAutomationSupport

enum SetupAutomationSupport: String, Equatable {
    case none
    case runtimeTerminal
    case deviceAutomation

    // MARK: Internal

    var title: String {
        switch self {
        case .none:
            String(localized: "Manual Setup")
        case .runtimeTerminal:
            String(localized: "Automatic Setup")
        case .deviceAutomation:
            String(localized: "Automatic Device Setup")
        }
    }

    var badgeTitle: String {
        switch self {
        case .none:
            String(localized: "Manual Setup")
        case .runtimeTerminal,
             .deviceAutomation:
            String(localized: "Automatic Setup")
        }
    }

    var isAvailable: Bool {
        self != .none
    }

    var entryActionTitle: String {
        switch self {
        case .none:
            String(localized: "Use Manual Setup")
        case .runtimeTerminal:
            String(localized: "Automatic Setup…")
        case .deviceAutomation:
            String(localized: "Automatic Device Setup…")
        }
    }

    var sheetPrimaryActionTitle: String {
        switch self {
        case .none:
            String(localized: "Use Manual Setup")
        case .runtimeTerminal:
            String(localized: "Open Prepared Terminal")
        case .deviceAutomation:
            String(localized: "Start Automatic Device Setup")
        }
    }
}

// MARK: - SetupDetailTab

enum SetupDetailTab: String, CaseIterable, Identifiable, Hashable {
    case overview
    case setup
    case snippets
    case validate
    case troubleshooting

    // MARK: Internal

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .overview:
            String(localized: "Overview")
        case .setup:
            String(localized: "Setup")
        case .snippets:
            String(localized: "Snippets")
        case .validate:
            String(localized: "Validate")
        case .troubleshooting:
            String(localized: "Troubleshooting")
        }
    }
}

// MARK: - SetupActionKind

enum SetupActionKind: Equatable {
    case verifyProxy
    case openCertificate
    case copySnippet
    case runValidation
}

// MARK: - SetupModeSelection

enum SetupModeSelection: String, CaseIterable, Identifiable, Equatable {
    case manual
    case automatic

    // MARK: Internal

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .manual:
            String(localized: "Manual Setup")
        case .automatic:
            String(localized: "Automatic Setup")
        }
    }

    var systemImage: String {
        switch self {
        case .manual:
            "list.bullet.rectangle"
        case .automatic:
            "bolt.fill"
        }
    }
}

// MARK: - SetupModeActionState

struct SetupModeActionState: Equatable {
    // MARK: Lifecycle

    init(target: SetupTarget) {
        preferredMode = target.automationSupport.isAvailable ? .automatic : .manual
        manualTitle = String(localized: "Manual Setup")
        manualCaption = String(localized: "Follow the proxy, certificate, snippet, device, or runtime guide.")
        automaticTitle = String(localized: "Automatic Setup")
        isAutomaticEnabled = target.automationSupport.isAvailable
        automaticCaption = target.automationSupport.isAvailable
            ? String(localized: "Open a scoped Rockxy-prepared session for this target.")
            : String(localized: "Manual Setup is available for this target; Automatic Setup is not shipped here yet.")
    }

    // MARK: Internal

    let preferredMode: SetupModeSelection
    let manualTitle: String
    let manualCaption: String
    let automaticTitle: String
    let automaticCaption: String
    let isAutomaticEnabled: Bool
}

// MARK: - SetupIssue

enum SetupIssue: String, CaseIterable, Equatable, Identifiable {
    case runtimeNotInstalled
    case proxyStopped
    case recordingPaused
    case certificateNotTrusted
    case certificateExportUnavailable
    case deviceProxyUnreachable
    case noTrafficDetected
    case localProbeUnavailable
    case localProbeNotCaptured
    case allowListBlockedValidation
    case wrongSnippetChosen
    case manualValidationOnly
    case targetIsGuideOnly

    // MARK: Internal

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .runtimeNotInstalled:
            String(localized: "Runtime not installed")
        case .proxyStopped:
            String(localized: "Proxy stopped")
        case .recordingPaused:
            String(localized: "Recording paused")
        case .certificateNotTrusted:
            String(localized: "Certificate not trusted")
        case .certificateExportUnavailable:
            String(localized: "Certificate export/setup incomplete")
        case .deviceProxyUnreachable:
            String(localized: "Device proxy unreachable")
        case .noTrafficDetected:
            String(localized: "No traffic detected")
        case .localProbeUnavailable:
            String(localized: "Local probe unavailable")
        case .localProbeNotCaptured:
            String(localized: "Local probe not captured")
        case .allowListBlockedValidation:
            String(localized: "Allow List hides the validation probe")
        case .wrongSnippetChosen:
            String(localized: "Wrong snippet chosen")
        case .manualValidationOnly:
            String(localized: "Manual validation only")
        case .targetIsGuideOnly:
            String(localized: "Guide-only target")
        }
    }

    var message: String {
        switch self {
        case .runtimeNotInstalled:
            String(localized: "Install the selected runtime, toolchain, or client on this Mac before validating this manual flow.")
        case .proxyStopped:
            String(localized: "Start the Rockxy proxy before validating captured traffic.")
        case .recordingPaused:
            String(localized: "Resume recording so new requests appear in the traffic list.")
        case .certificateNotTrusted:
            String(localized: "Install and trust the Rockxy root certificate before validating HTTPS traffic.")
        case .certificateExportUnavailable:
            String(localized: "Generate and export the Rockxy root certificate so the selected client can trust it.")
        case .deviceProxyUnreachable:
            String(
                localized: """
                Physical devices cannot reach Rockxy while the proxy only listens on localhost. \
                Turn off Only Listen on localhost, restart the proxy, and use the Device Proxy host plus active port.
                """
            )
        case .noTrafficDetected:
            String(localized: "Run the test request again and make sure it points at the Rockxy proxy port.")
        case .localProbeUnavailable:
            String(localized: "Rockxy could not start the local validation probe on 127.0.0.1. Close and reopen Developer Setup Hub, then try again.")
        case .localProbeNotCaptured:
            String(localized: "Run the local probe again and make sure the selected runtime sends it through Rockxy's proxy port.")
        case .allowListBlockedValidation:
            String(localized: "Allow List is active and does not allow the local validation probe URL, so Rockxy forwards it but does not record it.")
        case .wrongSnippetChosen:
            String(localized: "Switch to the snippet that matches the runtime, library, or tool you are using.")
        case .manualValidationOnly:
            String(localized: "Use the manual validation steps in this Dev Hub guide.")
        case .targetIsGuideOnly:
            String(localized: "This target currently ships as guidance only.")
        }
    }

    var actionTitle: String {
        switch self {
        case .runtimeNotInstalled:
            String(localized: "View Setup")
        case .proxyStopped,
             .recordingPaused:
            String(localized: "Verify Proxy")
        case .certificateNotTrusted,
             .certificateExportUnavailable:
            String(localized: "Open Certificate")
        case .deviceProxyUnreachable:
            String(localized: "Open Proxy Settings")
        case .noTrafficDetected:
            String(localized: "Run Test Again")
        case .localProbeUnavailable:
            String(localized: "Retry")
        case .localProbeNotCaptured:
            String(localized: "Run Probe Again")
        case .allowListBlockedValidation:
            String(localized: "Open Allow List")
        case .wrongSnippetChosen:
            String(localized: "View Snippets")
        case .manualValidationOnly:
            String(localized: "View Validation")
        case .targetIsGuideOnly:
            String(localized: "View Overview")
        }
    }
}

// MARK: - SetupStep

struct SetupStep: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let actionTitle: String
    let actionKind: SetupActionKind
    let isComplete: Bool
    let isEnabled: Bool
}

// MARK: - VerificationState

enum VerificationState: Equatable {
    case idle
    case readinessFailed
    case readyToVerify
    case waitingForTraffic
    case success
    case timedOut
    case cancelled

    // MARK: Internal

    var title: String {
        switch self {
        case .idle:
            String(localized: "Idle")
        case .readinessFailed:
            String(localized: "Fix setup first")
        case .readyToVerify:
            String(localized: "Ready to verify")
        case .waitingForTraffic:
            String(localized: "Waiting for local probe")
        case .success:
            String(localized: "Local probe captured")
        case .timedOut:
            String(localized: "Timed out")
        case .cancelled:
            String(localized: "Cancelled")
        }
    }
}

// MARK: - SetupSnapshot

struct SetupSnapshot: Equatable {
    var supportStatus: SetupSupportStatus
    var runtimeReady: Bool
    var runtimeStatusNote: String?
    var proxyRunning: Bool
    var recordingEnabled: Bool
    var activePort: Int
    var effectiveListenAddress: String
    var reachableLANAddress: String?
    var certificateGenerated: Bool
    var certificateTrusted: Bool
    var certificateExportable: Bool
    var certificateFileReady: Bool
    var proxyMode: ProxyMode
    var readinessWarningMessage: String?
    var selectedSnippetID: SetupSnippetID?
    var verificationState: VerificationState
    var matchedTransactionID: UUID?
    var matchedHost: String?
    var matchedMethod: String?
    var matchedPath: String?

    init(
        supportStatus: SetupSupportStatus,
        runtimeReady: Bool = true,
        runtimeStatusNote: String? = nil,
        proxyRunning: Bool,
        recordingEnabled: Bool,
        activePort: Int,
        effectiveListenAddress: String,
        reachableLANAddress: String? = nil,
        certificateGenerated: Bool,
        certificateTrusted: Bool,
        certificateExportable: Bool,
        certificateFileReady: Bool = false,
        proxyMode: ProxyMode,
        readinessWarningMessage: String?,
        selectedSnippetID: SetupSnippetID?,
        verificationState: VerificationState,
        matchedTransactionID: UUID?,
        matchedHost: String?,
        matchedMethod: String?,
        matchedPath: String?
    ) {
        self.supportStatus = supportStatus
        self.runtimeReady = runtimeReady
        self.runtimeStatusNote = runtimeStatusNote
        self.proxyRunning = proxyRunning
        self.recordingEnabled = recordingEnabled
        self.activePort = activePort
        self.effectiveListenAddress = effectiveListenAddress
        self.reachableLANAddress = reachableLANAddress
        self.certificateGenerated = certificateGenerated
        self.certificateTrusted = certificateTrusted
        self.certificateExportable = certificateExportable
        self.certificateFileReady = certificateFileReady
        self.proxyMode = proxyMode
        self.readinessWarningMessage = readinessWarningMessage
        self.selectedSnippetID = selectedSnippetID
        self.verificationState = verificationState
        self.matchedTransactionID = matchedTransactionID
        self.matchedHost = matchedHost
        self.matchedMethod = matchedMethod
        self.matchedPath = matchedPath
    }
}

// MARK: - SetupAutomationStep

struct SetupAutomationStep: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
}

// MARK: - SetupAutomationPreview

struct SetupAutomationPreview: Equatable {
    let title: String
    let summary: String
    let primaryActionTitle: String
    let supplementaryNote: String
    let steps: [SetupAutomationStep]
}

// MARK: - SetupTarget

struct SetupTarget: Identifiable, Hashable {
    enum ID: String, CaseIterable, Hashable, Identifiable {
        case python
        case nodeJS
        case ruby
        case golang
        case rust
        case javaVMs
        case curl
        case firefox
        case postman
        case insomnia
        case paw
        case iosDevice
        case iosSimulator
        case androidDevice
        case androidEmulator
        case tvOSWatchOS
        case visionPro
        case flutter
        case reactNative
        case nextJS
        case electronJS
        case docker

        // MARK: Internal

        var id: String {
            rawValue
        }
    }

    let id: ID
    let title: String
    let category: SetupTargetCategory
    let iconName: String
    let manualSupport: SetupSupportStatus
    let automationSupport: SetupAutomationSupport
    let shortSummary: String
    let manualSummary: String
    let currentSupportSummary: String

    var supportStatus: SetupSupportStatus {
        manualSupport
    }

    var supportsCertificateSharing: Bool {
        switch id {
        case .iosDevice,
             .iosSimulator,
             .androidDevice,
             .androidEmulator,
             .tvOSWatchOS,
             .visionPro,
             .flutter,
             .reactNative:
            true
        default:
            false
        }
    }

    var requiresReachableLANProxy: Bool {
        switch id {
        case .iosDevice,
             .androidDevice,
             .tvOSWatchOS,
             .visionPro:
            true
        default:
            false
        }
    }
}
