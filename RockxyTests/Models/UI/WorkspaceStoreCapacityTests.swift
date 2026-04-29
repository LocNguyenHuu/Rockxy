@testable import Rockxy
import Testing

// MARK: - WorkspaceStoreCapacityTests

struct WorkspaceStoreCapacityTests {
    @Test("Custom capacity limit is respected")
    @MainActor
    func customLimit() {
        let store = WorkspaceStore(maxWorkspaces: 3)
        _ = store.createWorkspace(title: "Tab 1")
        _ = store.createWorkspace(title: "Tab 2")
        // 1 default + 2 created = 3 (at limit)
        #expect(store.workspaces.count == 3)
        #expect(store.canCreateWorkspace == false)

        let extra = store.createWorkspace(title: "Over limit")
        #expect(store.workspaces.count == 3)
        #expect(extra.title != "Over limit")
    }

    @Test("Duplicate workspace respects capacity")
    @MainActor
    func duplicateAtCapacity() {
        let store = WorkspaceStore(maxWorkspaces: 2)
        #expect(store.canCreateWorkspace == true)
        _ = store.createWorkspace(title: "Tab 1")
        // 1 default + 1 created = 2 (at limit)
        #expect(store.workspaces.count == 2)
        #expect(store.canCreateWorkspace == false)

        let dup = store.duplicateWorkspace(id: store.workspaces[1].id)
        #expect(dup == nil)
        #expect(store.workspaces.count == 2)
    }

    @Test("Default capacity is 8")
    @MainActor
    func defaultCapacity() {
        let store = WorkspaceStore()
        #expect(store.maxWorkspaces == 8)
    }

    @Test("Policy-injected capacity flows through coordinator")
    @MainActor
    func coordinatorWiresCapacity() {
        let policy = SmallPolicy()
        let coordinator = MainContentCoordinator(policy: policy)
        #expect(coordinator.workspaceStore.maxWorkspaces == 3)
    }

    @Test("maxWorkspaces zero clamps to 1")
    @MainActor
    func zeroClamps() {
        let store = WorkspaceStore(maxWorkspaces: 0)
        #expect(store.maxWorkspaces == 1)
        #expect(store.workspaces.count == 1)
    }

    @Test("maxWorkspaces negative clamps to 1")
    @MainActor
    func negativeClamps() {
        let store = WorkspaceStore(maxWorkspaces: -5)
        #expect(store.maxWorkspaces == 1)
        #expect(store.workspaces.count == 1)
    }
}

// MARK: - SmallPolicy

private struct SmallPolicy: AppPolicy {
    let maxWorkspaceTabs = 3
    let maxDomainFavorites = 5
    let maxActiveRulesPerTool = 10
    let maxEnabledScripts = 10
    let maxLiveHistoryEntries = 1_000
}
