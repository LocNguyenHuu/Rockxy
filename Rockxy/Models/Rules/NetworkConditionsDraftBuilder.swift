import Foundation

/// Testable helper that builds NetworkConditionsDraft from transaction or domain data.
enum NetworkConditionsDraftBuilder {
    static func fromTransaction(_ transaction: HTTPTransaction) -> NetworkConditionsDraft {
        NetworkConditionsDraft(
            origin: .selectedTransaction,
            suggestedName: "Slow \u{2014} \(transaction.request.host)\(transaction.request.path)",
            sourceURL: transaction.request.url,
            sourceHost: transaction.request.host,
            sourcePath: transaction.request.path,
            sourceMethod: transaction.request.method
        )
    }

    static func fromDomain(_ domain: String) -> NetworkConditionsDraft {
        NetworkConditionsDraft(
            origin: .domainQuickCreate,
            suggestedName: "Slow \u{2014} \(domain)",
            sourceURL: nil,
            sourceHost: domain,
            sourcePath: nil,
            sourceMethod: nil
        )
    }
}
