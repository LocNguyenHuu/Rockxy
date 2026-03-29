import AppKit
import Foundation
import os

// Owns selection and presentation state for the plugin settings experience.

// MARK: - PluginSettingsViewModel

@MainActor @Observable
final class PluginSettingsViewModel {
    // MARK: Internal

    internal(set) var plugins: [PluginInfo] = []
    var selectedPluginID: String?
    var searchText = ""
    var selectedCategory: PluginType?

    var filteredPlugins: [PluginInfo] {
        var result = plugins
        if let category = selectedCategory {
            result = result.filter { $0.manifest.types.contains(category) }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.manifest.name.lowercased().contains(query)
                    || $0.manifest.description.lowercased().contains(query)
            }
        }
        return result
    }

    var selectedPlugin: PluginInfo? {
        plugins.first { $0.id == selectedPluginID }
    }

    func loadPlugins() async {
        await pluginManager.loadAllPlugins()
        plugins = await pluginManager.plugins
    }

    func togglePlugin(id: String) async {
        guard let index = plugins.firstIndex(where: { $0.id == id }) else {
            return
        }
        plugins[index].isEnabled.toggle()
        let enabled = plugins[index].isEnabled
        plugins[index].status = enabled ? .active : .disabled
        UserDefaults.standard.set(enabled, forKey: "com.amunx.Rockxy.plugin.\(id).enabled")
    }

    func reloadPlugin(id: String) async {
        try? await pluginManager.reloadPlugin(id: id)
        plugins = await pluginManager.plugins
    }

    func uninstallPlugin(id: String) async {
        try? await pluginManager.uninstallPlugin(id: id)
        plugins = await pluginManager.plugins
        if selectedPluginID == id {
            selectedPluginID = nil
        }
    }

    func reinstallPlugin(id: String) async {
        guard let plugin = plugins.first(where: { $0.id == id }) else {
            return
        }
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.copyItem(at: plugin.bundlePath, to: tempDir)
            try? await pluginManager.uninstallPlugin(id: id)
            try await PluginDiscovery().installPlugin(from: tempDir)
            try? FileManager.default.removeItem(at: tempDir)
        } catch {
            Self.logger.error("Failed to reinstall plugin: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: tempDir)
        }
        await loadPlugins()
        selectedPluginID = id
    }

    func updateConfig(pluginID: String, key: String, value: Any) {
        UserDefaults.standard.set(value, forKey: "com.amunx.Rockxy.plugin.\(pluginID).config.\(key)")
    }

    func configValue(pluginID: String, key: String) -> Any? {
        UserDefaults.standard.object(forKey: "com.amunx.Rockxy.plugin.\(pluginID).config.\(key)")
    }

    func revealInFinder(plugin: PluginInfo) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: plugin.bundlePath.path)
    }

    func openPluginsFolder() {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rockxy/Plugins")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }

    func installFromFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = String(localized: "Select Plugin Folder")
        panel.prompt = String(localized: "Install")
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    try await PluginDiscovery().installPlugin(from: url)
                    await loadPlugins()
                } catch {
                    Self.logger.error("Failed to install plugin: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: Private

    private static let logger = Logger(subsystem: "com.amunx.Rockxy", category: "PluginSettingsViewModel")

    private let pluginManager = ScriptPluginManager()
}
