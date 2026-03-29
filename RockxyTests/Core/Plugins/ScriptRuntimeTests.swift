import Foundation
import JavaScriptCore
@testable import Rockxy
import Testing

// Regression tests for `ScriptRuntime` in the core plugins layer.

struct ScriptRuntimeTests {
    // MARK: Internal

    @Test("Load plugin with onRequest that adds header, verify header added")
    func onRequestAddsHeader() async throws {
        let runtime = ScriptRuntime()
        let script = """
        function onRequest(ctx) {
            ctx.setHeader('X-Test-Plugin', 'injected');
            return ctx;
        }
        """

        let plugin = try makeTempPlugin(id: "com.test.header-adder", script: script)
        try await runtime.loadPlugin(plugin)

        let requestContext = makeRequestContext()

        let result = try await runtime.callOnRequest(
            pluginID: plugin.id,
            context: requestContext
        )

        #expect(result.headers["X-Test-Plugin"] == "injected")
        #expect(result.headers["Content-Type"] == "application/json")
    }

    @Test("callOnRequest on unloaded plugin throws pluginNotLoaded")
    func callOnUnloadedPluginThrows() async throws {
        let runtime = ScriptRuntime()
        let requestContext = makeRequestContext()

        await #expect(throws: ScriptRuntimeError.self) {
            try await runtime.callOnRequest(
                pluginID: "com.test.nonexistent",
                context: requestContext
            )
        }
    }

    @Test("unloadPlugin removes plugin so subsequent call throws")
    func unloadRemovesPlugin() async throws {
        let runtime = ScriptRuntime()
        let script = "function onRequest(ctx) { return ctx; }"

        let plugin = try makeTempPlugin(id: "com.test.unload-test", script: script)
        try await runtime.loadPlugin(plugin)

        #expect(await runtime.hasPlugin(id: plugin.id) == true)

        await runtime.unloadPlugin(id: plugin.id)

        #expect(await runtime.hasPlugin(id: plugin.id) == false)

        let requestContext = makeRequestContext()

        await #expect(throws: ScriptRuntimeError.self) {
            try await runtime.callOnRequest(
                pluginID: plugin.id,
                context: requestContext
            )
        }
    }

    // MARK: Private

    private func makeTempPlugin(id: String, script: String) throws -> PluginInfo {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RockxyTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let scriptFile = tempDir.appendingPathComponent("main.js")
        try script.write(to: scriptFile, atomically: true, encoding: .utf8)

        let manifest = PluginManifest(
            id: id,
            name: "Test Plugin",
            version: "1.0.0",
            author: PluginAuthor(name: "Test", url: nil),
            description: "Test plugin",
            types: [.script],
            entryPoints: ["script": "main.js"],
            capabilities: ["modifyRequest"]
        )

        return PluginInfo(
            id: id,
            manifest: manifest,
            bundlePath: tempDir,
            isEnabled: true,
            status: .active
        )
    }

    private func makeRequestContext(
        method: String = "GET",
        url: String = "https://example.com/api",
        headers: [HTTPHeader] = [HTTPHeader(name: "Content-Type", value: "application/json")]
    )
        -> ScriptRequestContext
    {
        let request = HTTPRequestData(
            method: method,
            url: URL(string: url)!,
            httpVersion: "HTTP/1.1",
            headers: headers,
            body: nil
        )
        return ScriptRequestContext(from: request)
    }
}
