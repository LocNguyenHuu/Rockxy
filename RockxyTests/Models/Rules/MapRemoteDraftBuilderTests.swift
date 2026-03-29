import Foundation
@testable import Rockxy
import Testing

// Regression tests for `MapRemoteDraftBuilder` in the models rules layer.

struct MapRemoteDraftBuilderTests {
    @Test("Transaction draft has correct fields")
    @MainActor
    func transactionDraft() {
        let transaction = TestFixtures.makeTransaction(
            method: "GET",
            url: "https://api.prod.example.com/v2/users?page=1",
            statusCode: 200
        )
        let draft = MapRemoteDraftBuilder.fromTransaction(transaction)

        #expect(draft.origin == .selectedTransaction)
        #expect(draft.sourceHost == "api.prod.example.com")
        #expect(draft.sourcePath == "/v2/users")
        #expect(draft.sourceMethod == "GET")
        #expect(draft.sourceURL?.absoluteString == "https://api.prod.example.com/v2/users?page=1")
        #expect(draft.suggestedName.contains("api.prod.example.com"))
    }

    @Test("Domain draft has correct fields")
    @MainActor
    func domainDraft() {
        let draft = MapRemoteDraftBuilder.fromDomain("api.prod.example.com")

        #expect(draft.origin == .domainQuickCreate)
        #expect(draft.sourceHost == "api.prod.example.com")
        #expect(draft.sourceURL == nil)
        #expect(draft.sourcePath == nil)
        #expect(draft.sourceMethod == nil)
        #expect(draft.suggestedName.contains("api.prod.example.com"))
    }
}
