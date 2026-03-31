import Foundation

enum PluginValidator {
    // MARK: Internal

    static func isValidPluginID(_ id: String) -> Bool {
        !id.isEmpty && id.count <= 128
            && id.unicodeScalars.allSatisfy { validIDCharacters.contains($0) }
    }

    static func isValidKey(_ key: String) -> Bool {
        !key.isEmpty && key.count <= 256
            && key.unicodeScalars.allSatisfy { validIDCharacters.contains($0) }
    }

    // MARK: Private

    private static let validIDCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-_"))
}
