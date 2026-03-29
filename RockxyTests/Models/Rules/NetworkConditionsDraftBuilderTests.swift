import Foundation
@testable import Rockxy
import Testing

// Regression tests for `NetworkConditionsDraftBuilder` in the models rules layer.

struct NetworkConditionsDraftBuilderTests {
    @Test("fromTransaction extracts host, path, method")
    @MainActor
    func transactionDraftFields() {
        let transaction = TestFixtures.makeTransaction(
            method: "POST",
            url: "https://api.prod.example.com/v2/users?page=1",
            statusCode: 200
        )
        let draft = NetworkConditionsDraftBuilder.fromTransaction(transaction)

        #expect(draft.sourceHost == "api.prod.example.com")
        #expect(draft.sourcePath == "/v2/users")
        #expect(draft.sourceMethod == "POST")
        #expect(draft.sourceURL?.absoluteString == "https://api.prod.example.com/v2/users?page=1")
        #expect(draft.suggestedName.contains("api.prod.example.com"))
    }

    @Test("fromTransaction sets origin to selectedTransaction")
    @MainActor
    func transactionDraftOrigin() {
        let transaction = TestFixtures.makeTransaction(
            method: "GET",
            url: "https://example.com/path",
            statusCode: 200
        )
        let draft = NetworkConditionsDraftBuilder.fromTransaction(transaction)

        #expect(draft.origin == .selectedTransaction)
    }

    @Test("fromDomain sets origin to domainQuickCreate")
    @MainActor
    func domainDraftOrigin() {
        let draft = NetworkConditionsDraftBuilder.fromDomain("cdn.example.com")

        #expect(draft.origin == .domainQuickCreate)
        #expect(draft.sourceHost == "cdn.example.com")
        #expect(draft.suggestedName.contains("cdn.example.com"))
    }

    @Test("fromDomain sets sourceURL to nil")
    @MainActor
    func domainDraftNilFields() {
        let draft = NetworkConditionsDraftBuilder.fromDomain("api.example.com")

        #expect(draft.sourceURL == nil)
        #expect(draft.sourcePath == nil)
        #expect(draft.sourceMethod == nil)
    }
}
