import Foundation
@testable import Rockxy
import Testing

// MARK: - FavoritesCapacityTests

struct FavoritesCapacityTests {
    @Test("Domain favorites capped at policy limit")
    @MainActor
    func domainCapEnforced() {
        let coordinator = MainContentCoordinator(policy: TinyPolicy())

        coordinator.addFavorite(.domainNode(domain: "a.com"))
        coordinator.addFavorite(.domainNode(domain: "b.com"))
        #expect(coordinator.favorites.count == 2)
        #expect(coordinator.domainFavoriteCount == 2)

        // Third domain exceeds limit of 2
        coordinator.addFavorite(.domainNode(domain: "c.com"))
        #expect(coordinator.favorites.count == 2)
        #expect(coordinator.domainFavoriteCount == 2)
    }

    @Test("App favorites are not capped by domain limit")
    @MainActor
    func appFavoritesUncapped() {
        let coordinator = MainContentCoordinator(policy: TinyPolicy())

        coordinator.addFavorite(.domainNode(domain: "a.com"))
        coordinator.addFavorite(.domainNode(domain: "b.com"))
        // At domain limit

        // App favorites should still work
        coordinator.addFavorite(.app(name: "MyApp", bundleId: "com.test.app"))
        #expect(coordinator.favorites.count == 3)
        #expect(coordinator.domainFavoriteCount == 2)
    }

    @Test("Pinned/saved transaction items do not count toward domain quota")
    @MainActor
    func transactionItemsUnaffected() {
        let coordinator = MainContentCoordinator(policy: TinyPolicy())

        coordinator.addFavorite(.domainNode(domain: "a.com"))
        coordinator.addFavorite(.domainNode(domain: "b.com"))
        // At domain limit

        // Transaction-based items should not be affected
        coordinator.addFavorite(.pinnedTransaction(id: .init()))
        coordinator.addFavorite(.savedTransaction(id: .init()))
        #expect(coordinator.favorites.count == 4)
        #expect(coordinator.domainFavoriteCount == 2)
    }

    @Test("Duplicate domain favorite is rejected")
    @MainActor
    func duplicateRejected() {
        let coordinator = MainContentCoordinator(policy: TinyPolicy())

        coordinator.addFavorite(.domainNode(domain: "a.com"))
        coordinator.addFavorite(.domainNode(domain: "a.com"))
        #expect(coordinator.favorites.count == 1)
    }
}

// MARK: - TinyPolicy

private struct TinyPolicy: AppPolicy {
    let maxWorkspaceTabs = 8
    let maxDomainFavorites = 2
    let maxActiveRulesPerTool = 10
    let maxEnabledScripts = 10
    let maxLiveHistoryEntries = 1_000
}
