import Foundation
@testable import Rockxy
import Testing

// MARK: - FavoriteTransactionContextMenuTests

@Suite(.serialized)
@MainActor
struct FavoriteTransactionContextMenuTests {
    @Test("Menu model exposes practical native submenus without unsupported export formats")
    func menuModelFeatureSet() {
        let transaction = TestFixtures.makeTransaction(
            method: "POST",
            url: "https://api.example.com/v1/users",
            statusCode: 201
        )
        transaction.request.body = Data("request-body".utf8)
        transaction.response = TestFixtures.makeResponse(
            statusCode: 201,
            body: Data("response-body".utf8)
        )

        let model = FavoriteTransactionContextMenuModel(
            transaction: transaction,
            section: .pinned,
            isSSLProxyingEnabled: false
        )

        #expect(model.tools.map(\.action) == FavoriteTransactionToolAction.allCases)
        #expect(model.exports.map(\.action) == FavoriteTransactionExportFormat.allCases)
        let allExportsEnabled = model.exports.allSatisfy { $0.isEnabled }
        #expect(allExportsEnabled)
        #expect(!model.exports.map(\.title).contains { $0.localizedCaseInsensitiveContains("CSV") })
        #expect(!model.exports.map(\.title).contains { $0.localizedCaseInsensitiveContains("Postman") })
        #expect(model.sslProxyingTitle == "Enable SSL Proxying")
    }

    @Test("Menu model disables unavailable actions clearly")
    func menuModelDisabledStates() {
        let transaction = TestFixtures.makeTransaction(
            method: "GET",
            url: "https://api.example.com/no-response",
            statusCode: nil
        )

        let model = FavoriteTransactionContextMenuModel(
            transaction: transaction,
            section: .saved,
            isSSLProxyingEnabled: true
        )

        let raw = model.exports.first { $0.action == .rawRequestAndResponse }
        let requestBody = model.exports.first { $0.action == .requestBody }
        let responseBody = model.exports.first { $0.action == .responseBody }

        #expect(model.deleteTitle == "Delete")
        #expect(model.sslProxyingTitle == "Disable SSL Proxying")
        #expect(raw?.isEnabled == false)
        #expect(raw?.disabledReason?.isEmpty == false)
        #expect(requestBody?.isEnabled == false)
        #expect(requestBody?.disabledReason?.isEmpty == false)
        #expect(responseBody?.isEnabled == false)
        #expect(responseBody?.disabledReason?.isEmpty == false)
    }

    @Test("Deleting from Pinned only clears pinned membership and keeps original request")
    func deleteFromPinnedDoesNotDeleteRequest() {
        let coordinator = MainContentCoordinator()
        let transaction = TestFixtures.makeTransaction(url: "https://api.example.com/keep")
        transaction.isPinned = true
        transaction.isSaved = true
        coordinator.transactions = [transaction]
        coordinator.selectSidebarItem(.pinnedTransaction(id: transaction.id))
        coordinator.recomputeFilteredTransactions()

        coordinator.removeFavoriteTransaction(transaction, from: .pinned)

        #expect(coordinator.transactions.map(\.id) == [transaction.id])
        #expect(transaction.isPinned == false)
        #expect(transaction.isSaved == true)
        #expect(coordinator.allPinnedTransactions.isEmpty)
        #expect(coordinator.allSavedTransactions.map(\.id) == [transaction.id])
        #expect(coordinator.sidebarSelection == .allPinned)
    }

    @Test("Deleting from Saved only clears saved membership and keeps pinned membership")
    func deleteFromSavedDoesNotDeletePinnedRequest() {
        let coordinator = MainContentCoordinator()
        let transaction = TestFixtures.makeTransaction(url: "https://api.example.com/keep-saved")
        transaction.isPinned = true
        transaction.isSaved = true
        coordinator.persistedFavorites = [transaction]

        coordinator.removeFavoriteTransaction(transaction, from: .saved)

        #expect(transaction.isSaved == false)
        #expect(transaction.isPinned == true)
        #expect(coordinator.persistedFavorites.map(\.id) == [transaction.id])
        #expect(coordinator.allPinnedTransactions.map(\.id) == [transaction.id])
        #expect(coordinator.allSavedTransactions.isEmpty)
    }

    @Test("Deleting last persisted favorite removes it from favorite cache without deleting live rows")
    func deleteLastPersistedFavoritePrunesCache() {
        let coordinator = MainContentCoordinator()
        let transaction = TestFixtures.makeTransaction(url: "https://api.example.com/old")
        transaction.isSaved = true
        coordinator.persistedFavorites = [transaction]

        coordinator.removeFavoriteTransaction(transaction, from: .saved)

        #expect(transaction.isSaved == false)
        #expect(coordinator.persistedFavorites.isEmpty)
        #expect(coordinator.transactions.isEmpty)
    }

    @Test("Open in new tab scopes the workspace to the exact request URL")
    func openInNewTabUsesExactURLFilter() {
        let coordinator = MainContentCoordinator()
        let transaction = TestFixtures.makeTransaction(url: "https://api.example.com/v1/users?page=1")
        transaction.isPinned = true
        coordinator.transactions = [transaction]

        coordinator.openFavoriteTransactionInNewTab(transaction, from: .pinned)

        #expect(coordinator.workspaceStore.workspaces.count == 2)
        let workspace = coordinator.workspaceStore.workspaces[1]
        #expect(workspace.filterCriteria.sidebarScope == .pinned)
        #expect(workspace.filterCriteria.searchField == .url)
        #expect(workspace.filterCriteria.searchText == transaction.request.url.absoluteString)
        #expect(workspace.filteredTransactions.map(\.id) == [transaction.id])
        #expect(workspace.filteredRows.map(\.id) == [transaction.id])
    }

    @Test("Open in new tab displays persisted-only Saved rows")
    func openInNewTabDisplaysPersistedOnlySavedRows() {
        let coordinator = MainContentCoordinator()
        let transaction = TestFixtures.makeTransaction(url: "https://api.example.com/persisted")
        transaction.isSaved = true
        coordinator.persistedFavorites = [transaction]

        coordinator.openFavoriteTransactionInNewTab(transaction, from: .saved)

        let workspace = coordinator.workspaceStore.workspaces[1]
        #expect(workspace.filterCriteria.sidebarScope == .saved)
        #expect(workspace.filteredTransactions.map(\.id) == [transaction.id])
        #expect(workspace.filteredRows.map(\.id) == [transaction.id])
    }

    @Test("Export payloads serialize supported formats and reject missing bodies")
    func exportPayloads() throws {
        let coordinator = MainContentCoordinator()
        let transaction = TestFixtures.makeTransaction(
            method: "POST",
            url: "https://api.example.com/export",
            statusCode: 200
        )
        transaction.request.body = Data("hello".utf8)
        transaction.response = TestFixtures.makeResponse(statusCode: 200, body: Data("world".utf8))

        let harData = try coordinator.favoriteTransactionExportData(transaction, as: .har)
        let rawData = try coordinator.favoriteTransactionExportData(transaction, as: .rawRequestAndResponse)
        let sessionData = try coordinator.favoriteTransactionExportData(transaction, as: .rockxySession)
        let requestBody = try coordinator.favoriteTransactionExportData(transaction, as: .requestBody)
        let responseBody = try coordinator.favoriteTransactionExportData(transaction, as: .responseBody)

        #expect(String(data: harData, encoding: .utf8)?.contains("\"log\"") == true)
        #expect(String(data: rawData, encoding: .utf8)?.contains("HTTP/1.1 200 OK") == true)
        #expect(try SessionSerializer.deserialize(from: sessionData).transactions.count == 1)
        #expect(requestBody == Data("hello".utf8))
        #expect(responseBody == Data("world".utf8))

        transaction.request.body = nil
        #expect(throws: Error.self) {
            try coordinator.favoriteTransactionExportData(transaction, as: .requestBody)
        }
    }

    @Test("Tool action routing prepares the expected rule draft")
    func toolRoutingPreparesDraft() {
        let coordinator = MainContentCoordinator()
        let transaction = TestFixtures.makeTransaction(
            method: "PUT",
            url: "https://api.example.com/v2/profile",
            statusCode: 200
        )
        let store = MapRemoteDraftStore.shared
        _ = store.consumePending()
        let draftVersion = store.draftVersion

        coordinator.createMapRemoteRule(for: transaction)

        #expect(store.draftVersion == draftVersion &+ 1)
        if let draft = store.pendingDraft {
            #expect(draft.sourceHost == "api.example.com")
            #expect(draft.sourcePath == "/v2/profile")
            #expect(draft.sourceMethod == "PUT")
        }

        _ = store.consumePending()
    }
}
