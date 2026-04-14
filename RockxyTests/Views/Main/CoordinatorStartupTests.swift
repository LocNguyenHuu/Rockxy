import Foundation
@testable import Rockxy
import Testing

@Suite(.serialized)
@MainActor
struct CoordinatorStartupTests {
    @Test("ensureRulesLoaded sets rulesLoaded to true")
    func ensureRulesLoadedSetsFlag() async {
        await RuleTestLock.shared.acquire()
        let engineSnapshot = await RuleEngine.shared.allRules
        let coordinator = MainContentCoordinator()
        #expect(!coordinator.rulesLoaded)

        await coordinator.ensureRulesLoaded()
        #expect(coordinator.rulesLoaded)

        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }

    @Test("ruleLoadTask is cleared after ensureRulesLoaded completes")
    func ruleLoadTaskClearedAfterCompletion() async {
        await RuleTestLock.shared.acquire()
        let engineSnapshot = await RuleEngine.shared.allRules
        let coordinator = MainContentCoordinator()
        #expect(coordinator.ruleLoadTask == nil)

        await coordinator.ensureRulesLoaded()
        // Completion clears the task handle so the coordinator no longer retains it.
        #expect(coordinator.ruleLoadTask == nil)
        #expect(coordinator.rulesLoaded)

        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }

    @Test("ensureRulesLoaded early-returns when rules are already loaded")
    func ensureRulesLoadedIdempotent() async {
        await RuleTestLock.shared.acquire()
        let engineSnapshot = await RuleEngine.shared.allRules
        let coordinator = MainContentCoordinator()

        await coordinator.ensureRulesLoaded()
        #expect(coordinator.rulesLoaded)
        #expect(coordinator.ruleLoadTask == nil)

        // Second call sees `rulesLoaded == true` and returns without spawning a new task.
        await coordinator.ensureRulesLoaded()
        #expect(coordinator.rulesLoaded)
        #expect(coordinator.ruleLoadTask == nil)

        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }

    @Test("loadInitialRules stores ruleLoadTask without blocking")
    func loadInitialRulesStoresTask() async {
        await RuleTestLock.shared.acquire()
        let engineSnapshot = await RuleEngine.shared.allRules
        let coordinator = MainContentCoordinator()
        coordinator.loadInitialRules()

        #expect(coordinator.ruleLoadTask != nil)
        #expect(!coordinator.rulesLoaded)

        // Await completion so the background Task doesn't contend with later tests
        await coordinator.ruleLoadTask?.value
        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }

    @Test("loadInitialRules is a no-op when ruleLoadTask already exists")
    func loadInitialRulesNoOpWhenTaskExists() async {
        await RuleTestLock.shared.acquire()
        let engineSnapshot = await RuleEngine.shared.allRules
        let coordinator = MainContentCoordinator()
        await coordinator.ensureRulesLoaded()
        #expect(coordinator.rulesLoaded)

        coordinator.loadInitialRules()
        #expect(coordinator.ruleLoadTask != nil)
        #expect(coordinator.rulesLoaded)

        await RuleEngine.shared.replaceAll(engineSnapshot)
        await RuleTestLock.shared.release()
    }
}
