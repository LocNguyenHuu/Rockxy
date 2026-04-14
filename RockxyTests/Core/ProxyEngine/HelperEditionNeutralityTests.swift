import Foundation
import Testing

/// Lightweight smoke check that product-specific logic has not leaked into
/// the helper, shared, or core layers. This is a sanity check, not a
/// strong architecture guarantee — the real rule is enforced by code
/// review and architecture docs.
struct HelperEditionNeutralityTests {
    // MARK: Internal

    // MARK: - Tests

    @Test("Shared/ does not reference policy or gate types")
    func sharedIsNeutral() throws {
        let root = try Self.resolveProjectRoot()
        let violations = Self.swiftFiles(in: "Shared", root: root).filter(Self.containsPolicyReference)
        #expect(violations.isEmpty, "Shared/ must not reference policy types: \(violations.map(\.lastPathComponent))")
    }

    @Test("RockxyHelperTool/ does not reference policy or gate types")
    func helperIsNeutral() throws {
        let root = try Self.resolveProjectRoot()
        let violations = Self.swiftFiles(in: "RockxyHelperTool", root: root).filter(Self.containsPolicyReference)
        #expect(
            violations.isEmpty,
            "RockxyHelperTool/ must not reference policy types: \(violations.map(\.lastPathComponent))"
        )
    }

    @Test("Core/ does not reference policy or gate types")
    func coreIsNeutral() throws {
        let root = try Self.resolveProjectRoot()
        let violations = Self.swiftFiles(in: "Rockxy/Core", root: root).filter(Self.containsPolicyReference)
        #expect(violations.isEmpty, "Core/ must not reference policy types: \(violations.map(\.lastPathComponent))")
    }

    // MARK: Private

    private enum ResolveError: Error, CustomStringConvertible {
        case rootNotFound(filePath: String)

        // MARK: Internal

        var description: String {
            switch self {
            case let .rootNotFound(filePath):
                "Could not locate RockxyTests directory from \(filePath)"
            }
        }
    }

    // MARK: - Helpers

    private static func resolveProjectRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "RockxyTests", url.path != "/" {
            url.deleteLastPathComponent()
        }
        guard url.lastPathComponent == "RockxyTests" else {
            throw ResolveError.rootNotFound(filePath: #filePath)
        }
        url.deleteLastPathComponent()
        return url
    }

    private static func swiftFiles(in directory: String, root: URL) -> [URL] {
        let dir = root.appendingPathComponent(directory)
        guard let enumerator = FileManager.default.enumerator(
            at: dir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        var files: [URL] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            files.append(url)
        }
        return files
    }

    private static func containsPolicyReference(_ url: URL) -> Bool {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return false
        }
        return contents.contains("AppPolicy")
            || contents.contains("DefaultAppPolicy")
            || contents.contains("RulePolicyGate")
            || contents.contains("ScriptPolicyGate")
            || contents.contains("ProductEdition")
            || contents.contains("EditionCapabilities")
    }
}
