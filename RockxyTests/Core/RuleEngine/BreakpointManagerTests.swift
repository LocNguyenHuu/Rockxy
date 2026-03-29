import Foundation
@testable import Rockxy
import Testing

// Regression tests for `BreakpointManager` in the core rule engine layer.

@Suite(.serialized)
@MainActor
struct BreakpointManagerTests {
    @Test("enqueue adds item to pausedItems")
    func enqueueAddsItem() async {
        let manager = BreakpointManager()
        let data = BreakpointRequestData(
            method: "GET", url: "https://example.com/test", headers: [], body: "", statusCode: 200, phase: .request
        )

        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            manager.resolve(id: manager.pausedItems.first!.id, decision: .cancel)
        }

        _ = await manager.enqueueAndWait(data)
        // After resolve, item is removed
        #expect(manager.pausedItems.isEmpty)
    }

    @Test("resolve one does not drop others")
    func resolveOneKeepsOthers() async {
        let manager = BreakpointManager()
        let data1 = BreakpointRequestData(
            method: "GET", url: "https://a.com", headers: [], body: "", statusCode: 200, phase: .request
        )
        let data2 = BreakpointRequestData(
            method: "POST", url: "https://b.com", headers: [], body: "", statusCode: 200, phase: .request
        )

        // Enqueue two items
        Task {
            _ = await manager.enqueueAndWait(data1)
        }
        try? await Task.sleep(nanoseconds: 50_000_000)

        Task {
            _ = await manager.enqueueAndWait(data2)
        }
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(manager.pausedItems.count == 2)

        // Resolve first, second remains
        let firstId = manager.pausedItems[0].id
        manager.resolve(id: firstId, decision: .execute)
        #expect(manager.pausedItems.count == 1)
    }

    @Test("resolveAll clears everything")
    func resolveAllClears() async {
        let manager = BreakpointManager()
        let data = BreakpointRequestData(
            method: "GET", url: "https://example.com", headers: [], body: "", statusCode: 200, phase: .request
        )

        Task { _ = await manager.enqueueAndWait(data) }
        Task { _ = await manager.enqueueAndWait(data) }
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(manager.pausedItems.count == 2)
        manager.resolveAll(decision: .cancel)
        #expect(manager.pausedItems.isEmpty)
    }

    @Test("selectedItemId auto-selects first item")
    func autoSelectsFirst() async {
        let manager = BreakpointManager()
        #expect(manager.selectedItemId == nil)

        let data = BreakpointRequestData(
            method: "GET", url: "https://example.com", headers: [], body: "", statusCode: 200, phase: .request
        )
        Task { _ = await manager.enqueueAndWait(data) }
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(manager.selectedItemId == manager.pausedItems.first?.id)
    }
}
