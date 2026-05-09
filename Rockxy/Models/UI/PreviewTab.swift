import Foundation

// Defines the UI model for custom request and response preview tabs.

// MARK: - PreviewRenderMode

enum PreviewRenderMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case json
    case jsonTree
    case formURLEncoded
    case html
    case htmlPreview
    case css
    case javascript
    case xml
    case images
    case hex
    case raw

    // MARK: Internal

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .json: "JSON"
        case .jsonTree: "JSON Treeview"
        case .formURLEncoded: "Form URL-Encoded"
        case .html: "HTML"
        case .htmlPreview: "HTML Preview"
        case .css: "CSS"
        case .javascript: "JavaScript"
        case .xml: "XML"
        case .images: "Images"
        case .hex: "Hex"
        case .raw: "Raw"
        }
    }
}

// MARK: - PreviewPanel

enum PreviewPanel: String, Codable, Sendable {
    case request
    case response
}

// MARK: - PreviewTab

struct PreviewTab: Identifiable, Codable, Hashable, Sendable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        name: String? = nil,
        renderMode: PreviewRenderMode,
        panel: PreviewPanel,
        isBuiltIn: Bool = true
    ) {
        self.id = id
        self.name = name ?? renderMode.displayName
        self.renderMode = renderMode
        self.panel = panel
        self.isBuiltIn = isBuiltIn
    }

    // MARK: Internal

    let id: UUID
    var name: String
    var renderMode: PreviewRenderMode
    var panel: PreviewPanel
    var isBuiltIn: Bool
}
