import Foundation
@testable import Rockxy
import Testing

@MainActor
struct ProxyDisplayStateTests {
    @Test("Coordinator reports stopped by default")
    func stoppedByDefault() {
        let coordinator = MainContentCoordinator()

        #expect(coordinator.proxyDisplayState == .stopped)
    }

    @Test("Coordinator reports starting while proxy startup is in flight")
    func startingDuringProxyStartup() {
        let coordinator = MainContentCoordinator()

        coordinator.isProxyStarting = true

        #expect(coordinator.proxyDisplayState == .starting)
    }

    @Test("Coordinator reports running after proxy start")
    func runningAfterProxyStart() {
        let coordinator = MainContentCoordinator()

        coordinator.isProxyRunning = true
        coordinator.isRecording = true

        #expect(coordinator.proxyDisplayState == .running)
    }

    @Test("Coordinator reports paused when proxy runs but recording is off")
    func pausedWhenRecordingOff() {
        let coordinator = MainContentCoordinator()

        coordinator.isProxyRunning = true
        coordinator.isRecording = false

        #expect(coordinator.proxyDisplayState == .paused)
    }

    @Test("Coordinator reports stopped after failed start clears startup state")
    func stoppedAfterFailedStart() {
        let coordinator = MainContentCoordinator()

        coordinator.isProxyStarting = false
        coordinator.isProxyRunning = false

        #expect(coordinator.proxyDisplayState == .stopped)
    }
}
