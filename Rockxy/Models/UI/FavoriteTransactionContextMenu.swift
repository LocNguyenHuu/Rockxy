import Foundation

// Defines the testable action model for Pinned/Saved transaction context menus.

// MARK: - FavoriteTransactionSection

enum FavoriteTransactionSection: String, CaseIterable {
    case pinned
    case saved

    var deleteTitle: String {
        String(localized: "Delete")
    }

    var displayName: String {
        switch self {
        case .pinned:
            String(localized: "Pinned")
        case .saved:
            String(localized: "Saved")
        }
    }

    func sidebarItem(for id: UUID) -> SidebarItem {
        switch self {
        case .pinned:
            .pinnedTransaction(id: id)
        case .saved:
            .savedTransaction(id: id)
        }
    }

    var fallbackSidebarItem: SidebarItem {
        switch self {
        case .pinned:
            .allPinned
        case .saved:
            .allSaved
        }
    }
}

// MARK: - FavoriteTransactionToolAction

enum FavoriteTransactionToolAction: String, CaseIterable {
    case breakpoint
    case mapLocal
    case mapRemote
    case blockList
    case allowList
    case networkConditions

    var title: String {
        switch self {
        case .breakpoint:
            String(localized: "Breakpoint...")
        case .mapLocal:
            String(localized: "Map Local...")
        case .mapRemote:
            String(localized: "Map Remote...")
        case .blockList:
            String(localized: "Block List...")
        case .allowList:
            String(localized: "Allow List...")
        case .networkConditions:
            String(localized: "Network Conditions...")
        }
    }

    var systemImage: String {
        switch self {
        case .breakpoint:
            "pause.circle"
        case .mapLocal:
            "doc.on.clipboard"
        case .mapRemote:
            "arrow.triangle.swap"
        case .blockList:
            "nosign"
        case .allowList:
            "line.3.horizontal.decrease.circle"
        case .networkConditions:
            "wifi.exclamationmark"
        }
    }
}

// MARK: - FavoriteTransactionExportFormat

enum FavoriteTransactionExportFormat: String, CaseIterable {
    case rockxySession
    case har
    case rawRequestAndResponse
    case requestBody
    case responseBody

    var title: String {
        switch self {
        case .rockxySession:
            String(localized: "as Rockxy Session...")
        case .har:
            String(localized: "as HAR (HTTP Archive)...")
        case .rawRequestAndResponse:
            String(localized: "Raw Request & Response...")
        case .requestBody:
            String(localized: "Request Body...")
        case .responseBody:
            String(localized: "Response Body...")
        }
    }

    var systemImage: String {
        switch self {
        case .rockxySession:
            "star.circle"
        case .har:
            "doc.badge.gearshape"
        case .rawRequestAndResponse:
            "doc.plaintext"
        case .requestBody:
            "arrow.up.doc"
        case .responseBody:
            "arrow.down.doc"
        }
    }

    var fileExtension: String {
        switch self {
        case .rockxySession:
            "rockxysession"
        case .har:
            "har"
        case .rawRequestAndResponse:
            "txt"
        case .requestBody, .responseBody:
            "bin"
        }
    }
}

// MARK: - FavoriteTransactionMenuOption

struct FavoriteTransactionMenuOption<Action: Hashable>: Hashable {
    let action: Action
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let disabledReason: String?

    init(
        action: Action,
        title: String,
        systemImage: String,
        isEnabled: Bool = true,
        disabledReason: String? = nil
    ) {
        self.action = action
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.disabledReason = disabledReason
    }
}

// MARK: - FavoriteTransactionContextMenuModel

struct FavoriteTransactionContextMenuModel: Hashable {
    let section: FavoriteTransactionSection
    let deleteTitle: String
    let sslProxyingTitle: String
    let canToggleSSLProxying: Bool
    let sslProxyingDisabledReason: String?
    let tools: [FavoriteTransactionMenuOption<FavoriteTransactionToolAction>]
    let exports: [FavoriteTransactionMenuOption<FavoriteTransactionExportFormat>]

    init(
        transaction: HTTPTransaction,
        section: FavoriteTransactionSection,
        isSSLProxyingEnabled: Bool
    ) {
        self.section = section
        self.deleteTitle = section.deleteTitle
        self.sslProxyingTitle = isSSLProxyingEnabled
            ? String(localized: "Disable SSL Proxying")
            : String(localized: "Enable SSL Proxying")

        let hasHost = !transaction.request.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        self.canToggleSSLProxying = hasHost
        self.sslProxyingDisabledReason = hasHost ? nil : String(localized: "This request has no host.")

        self.tools = FavoriteTransactionToolAction.allCases.map {
            FavoriteTransactionMenuOption(action: $0, title: $0.title, systemImage: $0.systemImage)
        }

        self.exports = [
            FavoriteTransactionMenuOption(
                action: .rockxySession,
                title: FavoriteTransactionExportFormat.rockxySession.title,
                systemImage: FavoriteTransactionExportFormat.rockxySession.systemImage
            ),
            FavoriteTransactionMenuOption(
                action: .har,
                title: FavoriteTransactionExportFormat.har.title,
                systemImage: FavoriteTransactionExportFormat.har.systemImage
            ),
            FavoriteTransactionMenuOption(
                action: .rawRequestAndResponse,
                title: FavoriteTransactionExportFormat.rawRequestAndResponse.title,
                systemImage: FavoriteTransactionExportFormat.rawRequestAndResponse.systemImage,
                isEnabled: transaction.response != nil,
                disabledReason: transaction.response == nil
                    ? String(localized: "No response has been captured for this request.")
                    : nil
            ),
            FavoriteTransactionMenuOption(
                action: .requestBody,
                title: FavoriteTransactionExportFormat.requestBody.title,
                systemImage: FavoriteTransactionExportFormat.requestBody.systemImage,
                isEnabled: transaction.request.body != nil,
                disabledReason: transaction.request.body == nil
                    ? String(localized: "This request has no body.")
                    : nil
            ),
            FavoriteTransactionMenuOption(
                action: .responseBody,
                title: FavoriteTransactionExportFormat.responseBody.title,
                systemImage: FavoriteTransactionExportFormat.responseBody.systemImage,
                isEnabled: transaction.response?.body != nil,
                disabledReason: transaction.response?.body == nil
                    ? String(localized: "This response has no body.")
                    : nil
            ),
        ]
    }
}
