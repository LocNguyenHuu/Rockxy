import Foundation
import os

// Persists and coordinates custom preview tab configuration for the inspector.

@MainActor @Observable
final class PreviewTabStore {
    // MARK: Lifecycle

    init() {
        load()
    }

    // MARK: Internal

    var requestTabs: [PreviewTab] = []
    var responseTabs: [PreviewTab] = []
    var autoBeautify: Bool = true {
        didSet {
            saveBeautifyPreference()
        }
    }

    // MARK: - Tab Management

    @discardableResult
    func enableTab(renderMode: PreviewRenderMode, panel: PreviewPanel) -> PreviewTab {
        let tab = PreviewTab(renderMode: renderMode, panel: panel)
        switch panel {
        case .request:
            if let existingTab = requestTabs.first(where: { $0.renderMode == renderMode && $0.isBuiltIn }) {
                return existingTab
            }
            requestTabs.append(tab)
        case .response:
            if let existingTab = responseTabs.first(where: { $0.renderMode == renderMode && $0.isBuiltIn }) {
                return existingTab
            }
            responseTabs.append(tab)
        }
        save()
        Self.logger.info("Enabled preview tab: \(renderMode.displayName) in \(panel.rawValue) panel")
        return tab
    }

    func disableTab(renderMode: PreviewRenderMode, panel: PreviewPanel) {
        switch panel {
        case .request:
            requestTabs.removeAll { $0.renderMode == renderMode && $0.isBuiltIn }
        case .response:
            responseTabs.removeAll { $0.renderMode == renderMode && $0.isBuiltIn }
        }
        save()
        Self.logger.info("Disabled preview tab: \(renderMode.displayName) from \(panel.rawValue) panel")
    }

    func isEnabled(renderMode: PreviewRenderMode, panel: PreviewPanel) -> Bool {
        switch panel {
        case .request:
            requestTabs.contains { $0.renderMode == renderMode && $0.isBuiltIn }
        case .response:
            responseTabs.contains { $0.renderMode == renderMode && $0.isBuiltIn }
        }
    }

    func toggleTab(renderMode: PreviewRenderMode, panel: PreviewPanel) {
        if isEnabled(renderMode: renderMode, panel: panel) {
            disableTab(renderMode: renderMode, panel: panel)
        } else {
            enableTab(renderMode: renderMode, panel: panel)
        }
    }

    func removeTab(id: UUID) {
        requestTabs.removeAll { $0.id == id }
        responseTabs.removeAll { $0.id == id }
        save()
    }

    @discardableResult
    func addCustomTab(name: String, panel: PreviewPanel) -> PreviewTab {
        let normalizedName = uniqueCustomTabName(
            name.trimmingCharacters(in: .whitespacesAndNewlines),
            panel: panel
        )
        let tab = PreviewTab(name: normalizedName, renderMode: .raw, panel: panel, isBuiltIn: false)
        switch panel {
        case .request:
            requestTabs.append(tab)
        case .response:
            responseTabs.append(tab)
        }
        save()
        Self.logger.info("Added custom tab: \(normalizedName) in \(panel.rawValue) panel")
        return tab
    }

    func customTabs(for panel: PreviewPanel) -> [PreviewTab] {
        switch panel {
        case .request:
            requestTabs.filter { !$0.isBuiltIn }
        case .response:
            responseTabs.filter { !$0.isBuiltIn }
        }
    }

    // MARK: Private

    private static let logger = Logger(subsystem: RockxyIdentity.current.logSubsystem, category: "PreviewTabStore")
    private static let storageKey = RockxyIdentity.current.defaultsKey("previewTabs")
    private static let beautifyKey = RockxyIdentity.current.defaultsKey("previewAutoBeautify")

    private func uniqueCustomTabName(_ name: String, panel: PreviewPanel) -> String {
        let baseName = name.isEmpty ? String(localized: "Custom") : name
        let existingNames = Set(customTabs(for: panel).map { $0.name.lowercased() })
        guard existingNames.contains(baseName.lowercased()) else {
            return baseName
        }

        var suffix = 2
        while existingNames.contains("\(baseName) \(suffix)".lowercased()) {
            suffix += 1
        }
        return "\(baseName) \(suffix)"
    }

    // MARK: - Persistence

    private func save() {
        do {
            let allTabs = requestTabs + responseTabs
            let data = try JSONEncoder().encode(allTabs)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
            saveBeautifyPreference()
        } catch {
            Self.logger.error("Failed to save preview tabs: \(error.localizedDescription)")
        }
    }

    private func saveBeautifyPreference() {
        UserDefaults.standard.set(autoBeautify, forKey: Self.beautifyKey)
    }

    private func load() {
        autoBeautify = UserDefaults.standard.object(forKey: Self.beautifyKey) as? Bool ?? true

        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            return
        }
        do {
            let allTabs = try JSONDecoder().decode([PreviewTab].self, from: data)
            requestTabs = allTabs.filter { $0.panel == .request }
            responseTabs = allTabs.filter { $0.panel == .response }
            Self.logger.info("Loaded \(allTabs.count) preview tabs")
        } catch {
            Self.logger.error("Failed to load preview tabs: \(error.localizedDescription)")
        }
    }
}
