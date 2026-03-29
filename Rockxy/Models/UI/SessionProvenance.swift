import Foundation

/// Tracks the origin of imported session data, displayed in the status bar
/// so users know the current session came from an external file.
struct SessionProvenance {
    let fileName: String
    let transactionCount: Int
    let logEntryCount: Int
    let importedAt: Date

    var displayText: String {
        String(
            localized: "Imported from \(fileName) (\(transactionCount) requests)"
        )
    }
}
