import Foundation
@testable import Rockxy
import Testing

// Regression tests for `RuleSyncService` in the core rule engine layer.

@Suite(.serialized)
struct RuleSyncServiceTests {
    // MARK: Internal

    @Test("addRule adds to RuleEngine.shared")
    func addRuleSync() async {
        // Swift's `defer` cannot await, so cleanup is handled through a wrapper that
        // always restores shared state and releases the lock after the body — including
        // if the body records an `Issue` or future revisions add throwing paths.
        await withRuleTestLock { [self] in
            await RuleSyncService.replaceAllRules([])

            let rule = ProxyRule(
                name: "Test Rule",
                matchCondition: RuleMatchCondition(urlPattern: ".*test.*"),
                action: .block(statusCode: 403)
            )
            await RuleSyncService.addRule(rule)

            let allRules = await RuleEngine.shared.allRules
            #expect(allRules.contains(where: { $0.id == rule.id }))
        }
    }

    @Test("removeRule removes from RuleEngine.shared")
    func removeRuleSync() async {
        await withRuleTestLock { [self] in
            let rule = ProxyRule(
                name: "Temp",
                matchCondition: RuleMatchCondition(urlPattern: ".*"),
                action: .block(statusCode: 403)
            )
            await RuleSyncService.replaceAllRules([rule])

            await RuleSyncService.removeRule(id: rule.id)

            let allRules = await RuleEngine.shared.allRules
            #expect(!allRules.contains(where: { $0.id == rule.id }))
        }
    }

    @Test("updateRule updates in RuleEngine.shared")
    func updateRuleSync() async {
        await withRuleTestLock { [self] in
            var rule = ProxyRule(
                name: "Original",
                matchCondition: RuleMatchCondition(urlPattern: ".*"),
                action: .block(statusCode: 403)
            )
            await RuleSyncService.replaceAllRules([rule])

            rule.name = "Updated"
            await RuleSyncService.updateRule(rule)

            let allRules = await RuleEngine.shared.allRules
            let found = allRules.first(where: { $0.id == rule.id })
            #expect(found?.name == "Updated")
        }
    }

    // MARK: Private

    private struct RulesBackup {
        let diskData: Data?
        let engineRules: [ProxyRule]
    }

    private static let rulesPath: URL = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return appSupport
            .appendingPathComponent(TestIdentity.appSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(TestIdentity.rulesPathComponent)
    }()

    private func backupRules() async -> RulesBackup {
        let diskData = try? Data(contentsOf: Self.rulesPath)
        let engineRules = await RuleEngine.shared.allRules
        return RulesBackup(diskData: diskData, engineRules: engineRules)
    }

    private func restoreRules(_ backup: RulesBackup) async {
        if let data = backup.diskData {
            try? data.write(to: Self.rulesPath)
        } else {
            try? FileManager.default.removeItem(at: Self.rulesPath)
        }
        await RuleEngine.shared.replaceAll(backup.engineRules)
    }

    /// Runs `body` between `RuleTestLock` acquire/release with shared rule state
    /// backed up and restored afterwards. Swift's `defer` cannot await, so the
    /// cleanup is inlined here and executed unconditionally after the body returns.
    private func withRuleTestLock(_ body: () async -> Void) async {
        await RuleTestLock.shared.acquire()
        let backup = await backupRules()
        await body()
        await restoreRules(backup)
        await RuleTestLock.shared.release()
    }
}
