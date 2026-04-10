import Foundation

// Built-in inspector plugin for JSON content. Declares support for JSON
// content type. View rendering is handled by JSONInspectorView in Views/.

// MARK: - JSONInspector

struct JSONInspector: InspectorPlugin {
    let name = "JSON Inspector"
    let supportedContentTypes: [ContentType] = [.json]
}
