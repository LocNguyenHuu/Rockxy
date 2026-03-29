import Foundation

/// A single row in the advanced filter builder. Combines a target field, comparison operator,
/// and match value into a toggleable predicate applied to the traffic list.
struct FilterRule: Identifiable {
    let id = UUID()
    var isEnabled: Bool = true
    var field: FilterField = .url
    var filterOperator: FilterOperator = .contains
    var value: String = ""
}
