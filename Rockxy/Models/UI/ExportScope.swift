import Foundation

// Defines `ExportScope`, the model for export scope used by the SwiftUI interface.

// MARK: - ExportScope

/// Determines which transactions are included when exporting to HAR format.
enum ExportScope: String, CaseIterable {
    case all
    case filtered
    case selected
}

// MARK: - ExportScopeContext

/// Snapshot of transaction counts used by `ExportScopeSheet` to display
/// scope options and disable unavailable choices.
struct ExportScopeContext {
    let allCount: Int
    let filteredCount: Int
    let selectedCount: Int

    var hasActiveFilter: Bool {
        filteredCount != allCount
    }

    var hasSelection: Bool {
        selectedCount > 0
    }
}
