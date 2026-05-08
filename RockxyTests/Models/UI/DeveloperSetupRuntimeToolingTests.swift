import Foundation
@testable import Rockxy
import Testing

struct DeveloperSetupRuntimeToolingTests {
    @Test("PATH discovery finds python3 executables outside the system path")
    func pathDiscoveryFindsPython3Executable() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DeveloperSetupRuntimeToolingTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let executableURL = tempDirectory.appendingPathComponent("python3")
        try "#!/bin/sh\nexit 0\n".write(to: executableURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executableURL.path)

        let discovered = DeveloperSetupRuntimeTooling.executableURLsOnPath(
            named: "python3",
            path: "\(tempDirectory.path):/usr/bin"
        )

        #expect(discovered.contains(executableURL))
    }

    @Test("Node candidates include PATH, Homebrew, system, and nvm locations")
    func nodeCandidatesIncludeCommonInstallLocations() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DeveloperSetupNodeCandidates-\(UUID().uuidString)", isDirectory: true)
        let pathBin = tempDirectory.appendingPathComponent("path-bin", isDirectory: true)
        let nvmBin = tempDirectory.appendingPathComponent(".nvm/versions/node/v22.11.0/bin", isDirectory: true)
        try FileManager.default.createDirectory(at: pathBin, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nvmBin, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let pathNode = pathBin.appendingPathComponent("node")
        let nvmNode = nvmBin.appendingPathComponent("node")
        try "#!/bin/sh\nexit 0\n".write(to: pathNode, atomically: true, encoding: .utf8)
        try "#!/bin/sh\nexit 0\n".write(to: nvmNode, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: pathNode.path)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: nvmNode.path)

        let candidates = DeveloperSetupRuntimeTooling.nodeExecutableCandidates(
            path: pathBin.path,
            homeDirectory: tempDirectory
        ).map(\.path)

        #expect(candidates.first == pathNode.path)
        #expect(candidates.contains("/usr/local/bin/node"))
        #expect(candidates.contains("/opt/homebrew/bin/node"))
        #expect(candidates.contains("/usr/bin/node"))
        #expect(candidates.contains(where: { $0.hasSuffix("/.nvm/versions/node/v22.11.0/bin/node") }))
    }
}
