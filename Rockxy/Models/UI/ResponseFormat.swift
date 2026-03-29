import Foundation

/// Display format options for the response body viewer.
enum ResponseFormat: String, CaseIterable {
    case json
    case xml
    case raw
    case hex

    // MARK: Internal

    var displayName: String {
        switch self {
        case .json: "JSON"
        case .xml: "XML"
        case .raw: "Raw"
        case .hex: "Hex"
        }
    }
}
