import Foundation
@testable import Rockxy
import Testing

// Regression tests for `PluginSettingsViewModel` in the view models layer.

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
            makePlugin(id: "c", name: "Gamma", types: [.exporter])
        ]

        #expect(viewModel.filteredPlugins.count == 3)
    }

    @Test("filteredPlugins filters by category inspector")
    func filteredPluginsByCategoryInspector() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "Alpha", types: [.script]),
            makePlugin(id: "b", name: "Beta", types: [.inspector]),
            makePlugin(id: "c", name: "Gamma", types: [.inspector, .exporter])
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
            makePlugin(id: "c", name: "JSON Formatter", types: [.script])
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
            makePlugin(id: "c", name: "HAR Exporter", types: [.exporter])
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
            makePlugin(id: "b", name: "Beta", types: [.inspector])
        ]
        viewModel.selectedPluginID = "b"

        #expect(viewModel.selectedPlugin?.id == "b")
        #expect(viewModel.selectedPlugin?.manifest.name == "Beta")
    }

    @Test("selectedPlugin returns nil for unknown ID")
    func selectedPluginReturnsNilForUnknownID() {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "a", name: "Alpha", types: [.script])
        ]
        viewModel.selectedPluginID = "nonexistent"

        #expect(viewModel.selectedPlugin == nil)
    }

    @Test("togglePlugin flips isEnabled and updates status")
    func togglePluginFlipsEnabled() async {
        let viewModel = PluginSettingsViewModel()
        viewModel.plugins = [
            makePlugin(id: "toggle-test", name: "Toggle Me", types: [.script], enabled: true)
        ]
        #expect(viewModel.plugins[0].isEnabled == true)
        #expect(viewModel.plugins[0].status == .active)

        await viewModel.togglePlugin(id: "toggle-test")

        #expect(viewModel.plugins[0].isEnabled == false)
        #expect(viewModel.plugins[0].status == .disabled)

        await viewModel.togglePlugin(id: "toggle-test")

        #expect(viewModel.plugins[0].isEnabled == true)
        #expect(viewModel.plugins[0].status == .active)
    }

    // MARK: Private

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
