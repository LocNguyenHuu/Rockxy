import Foundation

/// Singleton cross-window store for Map Local draft handoff.
/// Follows the same pattern as DiffTransactionStore and ComposeStore.
@MainActor @Observable
final class MapLocalDraftStore {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = MapLocalDraftStore()

    private(set) var pendingDraft: MapLocalDraft?
    var draftVersion: UInt64 = 0

    func setPending(_ draft: MapLocalDraft) {
        pendingDraft = draft
        draftVersion &+= 1
    }

    func consumePending() -> MapLocalDraft? {
        guard let draft = pendingDraft else {
            return nil
        }
        pendingDraft = nil
        return draft
    }
}
