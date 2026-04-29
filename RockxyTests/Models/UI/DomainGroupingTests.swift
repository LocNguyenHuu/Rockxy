import Foundation
@testable import Rockxy
import Testing

// Regression tests for sidebar domain grouping.

// MARK: - DomainGroupingTests

@MainActor
struct DomainGroupingTests {
    @Test("Groups root domains, subdomains, and paths into a recursive tree")
    func recursiveDomainTree() throws {
        let coordinator = MainContentCoordinator()
        let version = transaction("https://proxyman.com/osx/version.xml", sequence: 0)
        let events = transaction("https://proxyman.com/v1/events", sequence: 1)
        let apiEvents = transaction("https://api.proxyman.com/v1/events", sequence: 2, statusCode: 500)
        coordinator.transactions = [version, events, apiEvents]

        coordinator.rebuildSidebarIndexes()

        let root = try #require(coordinator.domainTree.first { $0.domain == "proxyman.com" })
        #expect(root.requestCount == 3)
        #expect(root.errorCount == 1)
        #expect(root.children.contains { $0.domain == "/osx" })
        #expect(root.children.contains { $0.domain == "/v1" })

        let api = try #require(root.children.first { $0.domain == "api.proxyman.com" })
        #expect(api.kind == .host)
        #expect(api.requestCount == 1)
        #expect(api.errorCount == 1)
        #expect(api.children.first?.domain == "/v1")
    }

    @Test("Uses common multi-part public suffixes for registrable domain grouping")
    func multiPartPublicSuffix() throws {
        let coordinator = MainContentCoordinator()
        coordinator.transactions = [
            transaction("https://api.example.co.uk/orders", sequence: 0),
            transaction("https://cdn.example.co.uk/assets/app.js", sequence: 1),
        ]

        coordinator.rebuildSidebarIndexes()

        let root = try #require(coordinator.domainTree.first)
        #expect(root.domain == "example.co.uk")
        #expect(root.children.map(\.domain).contains("api.example.co.uk"))
        #expect(root.children.map(\.domain).contains("cdn.example.co.uk"))
    }

    @Test("Collapses dynamic path segments under an id group")
    func dynamicPathSegments() throws {
        let coordinator = MainContentCoordinator()
        coordinator.transactions = [
            transaction("https://api.example.com/users/100", sequence: 0),
            transaction("https://api.example.com/users/200", sequence: 1),
        ]

        coordinator.rebuildSidebarIndexes()

        let root = try #require(coordinator.domainTree.first { $0.domain == "example.com" })
        let host = try #require(root.children.first { $0.domain == "api.example.com" })
        let users = try #require(host.children.first { $0.domain == "/users" })
        let idGroup = try #require(users.children.first)
        #expect(idGroup.domain == "/{id}")
        #expect(idGroup.pathPrefix == "/users/")
        #expect(idGroup.requestCount == 2)
    }

    // MARK: Private

    private func transaction(_ url: String, sequence: Int, statusCode: Int = 200) -> HTTPTransaction {
        let transaction = TestFixtures.makeTransaction(url: url, statusCode: statusCode)
        transaction.sequenceNumber = sequence
        return transaction
    }
}
