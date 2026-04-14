import Foundation
@testable import Rockxy
import Testing

// Regression tests for `PluginSettingsViewModel` in the view models layer.

/// Serialized: mutates shared plugin directory and UserDefaults plugin-enabled keys.
@Suite(.serialized)
@MainActor
struct PluginSettingsViewModelTests {
    // MARK: Internal

    @Test("Default selectedPluginID is nil")
    func defaultSelectedPluginIDIsNil() {
        let viewModel = PluginSettingsViewModel()
        #expect(viewModel.selectedPluginID == nil)
    }

    @Test("Default searchText is empty")
    func defaultSearchTextIsEmpty() {
        let viewModel = PluginSettingsViewModel()
        #expect(viewModel.searchText.isEmpty)
    }

    @Test("Default selectedCategory is nil")
    func defaultSelectedCategoryIsNil() {
        let viewModel = PluginSettingsViewModel()
        #expect(viewModel.selectedCategory == nil)
    }

    @Test("filteredPlugins returns all when no filter is applied")
    func filteredPluginsReturnsAllWhenNoFilter() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "Alpha", types: [.script]),
            makePlugin(id: "b", name: "Beta", types: [.inspector]),
            makePlugin(id: "c", name: "Gamma", types: [.exporter]),
        ]

        #expect(viewModel.filteredPlugins.count == 3)
    }

    @Test("filteredPlugins filters by category inspector")
    func filteredPluginsByCategoryInspector() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "Alpha", types: [.script]),
            makePlugin(id: "b", name: "Beta", types: [.inspector]),
            makePlugin(id: "c", name: "Gamma", types: [.inspector, .exporter]),
        ]
        viewModel.selectedCategory = .inspector

        let filtered = viewModel.filteredPlugins
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.manifest.types.contains(.inspector) })
    }

    @Test("filteredPlugins filters by search text matching name")
    func filteredPluginsBySearchText() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "JSON Viewer", types: [.inspector]),
            makePlugin(id: "b", name: "HAR Exporter", types: [.exporter]),
            makePlugin(id: "c", name: "JSON Formatter", types: [.script]),
        ]
        viewModel.searchText = "json"

        let filtered = viewModel.filteredPlugins
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.manifest.name.lowercased().contains("json") })
    }

    @Test("filteredPlugins applies both search and category filters")
    func filteredPluginsBySearchAndCategory() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "JSON Viewer", types: [.inspector]),
            makePlugin(id: "b", name: "JSON Exporter", types: [.exporter]),
            makePlugin(id: "c", name: "HAR Exporter", types: [.exporter]),
        ]
        viewModel.searchText = "json"
        viewModel.selectedCategory = .exporter

        let filtered = viewModel.filteredPlugins
        #expect(filtered.count == 1)
        #expect(filtered[0].id == "b")
    }

    @Test("selectedPlugin returns correct plugin for matching ID")
    func selectedPluginReturnsCorrectPlugin() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "Alpha", types: [.script]),
            makePlugin(id: "b", name: "Beta", types: [.inspector]),
        ]
        viewModel.selectedPluginID = "b"

        #expect(viewModel.selectedPlugin?.id == "b")
        #expect(viewModel.selectedPlugin?.manifest.name == "Beta")
    }

    @Test("selectedPlugin returns nil for unknown ID")
    func selectedPluginReturnsNilForUnknownID() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "Alpha", types: [.script]),
        ]
        viewModel.selectedPluginID = "nonexistent"

        #expect(viewModel.selectedPlugin == nil)
    }

    // MARK: - Runtime-Backed Toggle Tests

    @Test("togglePlugin disable with real plugin refreshes correctly")
    func toggleDisableRefreshes() async throws {
        let id = "toggle-disable-\(UUID().uuidString.prefix(8))"
        let pluginDir = try createTempPlugin(id: id, enabled: true)
        defer { cleanupTempPlugin(id: id, bundlePath: pluginDir) }

        let manager = ScriptPluginManager()
        await manager.loadAllPlugins()

        let viewModel = PluginSettingsViewModel(pluginManager: manager)
        viewModel.plugins = await manager.plugins
        #expect(viewModel.plugins.first { $0.id == id }?.isEnabled == true)

        await viewModel.togglePlugin(id: id)

        #expect(viewModel.plugins.first { $0.id == id }?.isEnabled == false)
        let managerPlugins = await manager.plugins
        #expect(managerPlugins.first { $0.id == id }?.isEnabled == false)
    }

    @Test("togglePlugin enable for unloadable plugin surfaces error")
    func toggleEnableUnloadablePluginSurfacesError() async throws {
        let id = "broken-\(UUID().uuidString.prefix(8))"
        let pluginDir = try createBrokenPlugin(id: id)
        defer { cleanupTempPlugin(id: id, bundlePath: pluginDir) }

        let manager = ScriptPluginManager()
        await manager.loadAllPlugins()

        let plugins = await manager.plugins
        #expect(plugins.contains { $0.id == id })
        #expect(plugins.first { $0.id == id }?.isEnabled == false)

        // Delete the script file after discovery so runtime.loadPlugin will fail
        try FileManager.default.removeItem(at: pluginDir.appendingPathComponent("index.js"))

        let viewModel = PluginSettingsViewModel(pluginManager: manager)
        viewModel.plugins = plugins

        await viewModel.togglePlugin(id: id)

        // Error should be surfaced to the UI
        #expect(viewModel.lastEnableError != nil)

        // Manager state is authoritative — plugin should be rolled back to disabled
        let managerPlugins = await manager.plugins
        #expect(managerPlugins.first { $0.id == id }?.isEnabled == false)
    }

    @Test("togglePlugin enable with real plugin updates state")
    func toggleEnableRefreshes() async throws {
        let id = "toggle-enable-\(UUID().uuidString.prefix(8))"
        let pluginDir = try createTempPlugin(id: id, enabled: false)
        defer { cleanupTempPlugin(id: id, bundlePath: pluginDir) }

        let manager = ScriptPluginManager()
        await manager.loadAllPlugins()

        let viewModel = PluginSettingsViewModel(pluginManager: manager)
        viewModel.plugins = await manager.plugins
        #expect(viewModel.plugins.first { $0.id == id }?.isEnabled == false)

        await viewModel.togglePlugin(id: id)

        #expect(viewModel.plugins.first { $0.id == id }?.isEnabled == true)
        #expect(viewModel.lastEnableError == nil)
    }

    @Test("Both ViewModels share same ScriptPluginManager instance")
    func sharedManagerState() {
        let manager = ScriptPluginManager()
        let settings = PluginSettingsViewModel(pluginManager: manager)
        let scripting = ScriptingViewModel(pluginManager: manager)

        // Without loading from disk, both start with the same empty state
        #expect(settings.plugins.isEmpty)
        #expect(scripting.plugins.isEmpty)
    }

    // MARK: Private

    /// Creates a valid plugin that passes discovery, then deletes the script
    /// file so that `runtime.loadPlugin` will fail when attempting to enable.
    /// The plugin is created disabled so `loadAllPlugins()` skips the load phase.
    private func createBrokenPlugin(id: String) throws -> URL {
        try createTempPlugin(id: id, enabled: false)
        // Remove the script file AFTER creation — discovery has already validated it
        // during the caller's `loadAllPlugins()` the file must exist for validation,
        // so we return the path and the caller deletes it after discovery.
    }

    private func createTempPlugin(id: String, enabled: Bool) throws -> URL {
        let pluginsDir = RockxyIdentity.current.appSupportPath("Plugins")
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        let bundlePath = pluginsDir.appendingPathComponent(id, isDirectory: true)
        try FileManager.default.createDirectory(at: bundlePath, withIntermediateDirectories: true)

        let manifest = """
        {
            "id": "\(id)",
            "name": "Test Plugin \(id)",
            "version": "1.0.0",
            "author": { "name": "Test" },
            "description": "Test plugin",
            "types": ["script"],
            "entryPoints": { "script": "index.js" },
            "capabilities": []
        }
        """
        try manifest.write(
            to: bundlePath.appendingPathComponent("plugin.json"),
            atomically: true,
            encoding: .utf8
        )

        let script = "module.exports = {};"
        try script.write(
            to: bundlePath.appendingPathComponent("index.js"),
            atomically: true,
            encoding: .utf8
        )

        if enabled {
            UserDefaults.standard.set(true, forKey: RockxyIdentity.current.pluginEnabledKey(pluginID: id))
        } else {
            UserDefaults.standard.removeObject(forKey: RockxyIdentity.current.pluginEnabledKey(pluginID: id))
        }

        return bundlePath
    }

    private func cleanupTempPlugin(id: String, bundlePath: URL) {
        try? FileManager.default.removeItem(at: bundlePath)
        UserDefaults.standard.removeObject(forKey: RockxyIdentity.current.pluginEnabledKey(pluginID: id))
    }

    private func makePlugin(
        id: String,
        name: String,
        types: [PluginType],
        enabled: Bool = true
    )
        -> PluginInfo
    {
        PluginInfo(
            id: id,
            manifest: PluginManifest(
                id: id,
                name: name,
                version: "1.0.0",
                author: PluginAuthor(name: "Test", url: nil),
                description: "Test plugin \(name)",
                types: types,
                entryPoints: ["script": "index.js"],
                capabilities: [],
                configuration: nil
            ),
            bundlePath: FileManager.default.temporaryDirectory.appendingPathComponent(id),
            isEnabled: enabled,
            status: enabled ? .active : .disabled
        )
    }
}
