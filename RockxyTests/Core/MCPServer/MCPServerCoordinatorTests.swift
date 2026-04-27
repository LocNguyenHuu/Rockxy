@testable import Rockxy
import Testing

@MainActor
@Suite("MCP Server Coordinator", .serialized)
struct MCPServerCoordinatorTests {
    @Test("Initial state is not running")
    func initialState() {
        let coordinator = MCPServerCoordinator()
        #expect(!coordinator.isRunning)
        #expect(coordinator.activePort == nil)
        #expect(coordinator.lastError == nil)
    }

    @Test("Start when disabled does nothing")
    func startWhenDisabled() async {
        let originalSettings = AppSettingsManager.shared.settings
        defer { AppSettingsManager.shared.settings = originalSettings }

        var settings = originalSettings
        settings.mcpServerEnabled = false
        AppSettingsManager.shared.settings = settings

        let coordinator = MCPServerCoordinator()
        await coordinator.startIfEnabled()
        #expect(!coordinator.isRunning)
        #expect(coordinator.activePort == nil)
    }

    @Test("Stop when not running is safe")
    func stopWhenNotRunning() async {
        let coordinator = MCPServerCoordinator()
        await coordinator.stop()
        #expect(!coordinator.isRunning)
        #expect(coordinator.activePort == nil)
        #expect(coordinator.lastError == nil)
    }

    @Test("Restart when disabled stays stopped")
    func restartWhenDisabled() async {
        let originalSettings = AppSettingsManager.shared.settings
        defer { AppSettingsManager.shared.settings = originalSettings }

        var settings = originalSettings
        settings.mcpServerEnabled = false
        AppSettingsManager.shared.settings = settings

        let coordinator = MCPServerCoordinator()
        await coordinator.restart()
        #expect(!coordinator.isRunning)
    }

    @Test("Detach providers when none attached is safe")
    func detachWithoutAttach() {
        let coordinator = MCPServerCoordinator()
        coordinator.detachProviders()
        #expect(!coordinator.isRunning)
    }
}
