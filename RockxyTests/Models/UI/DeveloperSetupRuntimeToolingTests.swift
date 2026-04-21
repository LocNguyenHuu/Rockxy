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
}
