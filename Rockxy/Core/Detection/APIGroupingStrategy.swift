import Foundation

/// Groups captured HTTP transactions for the sidebar source list.
/// Two strategies mirror how developers typically think about APIs:
/// by domain (which service?) and by path prefix (which resource?).
enum APIGroupingStrategy {
    // MARK: - By Domain

    static func groupByDomain(transactions: [HTTPTransaction]) -> [String: [HTTPTransaction]] {
        Dictionary(grouping: transactions) { $0.request.host }
    }

    // MARK: - By Path Prefix

    static func groupByPathPrefix(transactions: [HTTPTransaction], depth: Int = 2) -> [String: [HTTPTransaction]] {
        Dictionary(grouping: transactions) { transaction in
            let components = transaction.request.path.split(separator: "/").prefix(depth)
            return "/" + components.joined(separator: "/")
        }
    }
}
