import Foundation

/// Testable helper that builds MapLocalDraft from transaction or domain data.
/// Used by MainContentCoordinator context menu and sidebar menu actions.
enum MapLocalDraftBuilder {
    static func fromTransaction(_ transaction: HTTPTransaction) -> MapLocalDraft {
        MapLocalDraft(
            origin: .selectedTransaction,
            suggestedName: "Map Local — \(transaction.request.host)\(transaction.request.path)",
            sourceURL: transaction.request.url,
            sourceHost: transaction.request.host,
            sourcePath: transaction.request.path,
            sourceMethod: transaction.request.method,
            responseBody: transaction.response?.body,
            responseContentType: transaction.response?.headers.first {
                $0.name.lowercased() == "content-type"
            }?.value,
            inferredExtension: MimeTypeResolver.inferExtension(from: transaction)
        )
    }

    static func fromDomain(_ domain: String) -> MapLocalDraft {
        MapLocalDraft(
            origin: .domainQuickCreate,
            suggestedName: "Map Local — \(domain)",
            sourceHost: domain
        )
    }
}
