import Foundation

/// Singleton cross-window store for Map Remote draft handoff.
@MainActor @Observable
final class MapRemoteDraftStore {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = MapRemoteDraftStore()

    private(set) var pendingDraft: MapRemoteDraft?
    var draftVersion: UInt64 = 0

    func setPending(_ draft: MapRemoteDraft) {
        pendingDraft = draft
        draftVersion &+= 1
    }

    func consumePending() -> MapRemoteDraft? {
        guard let draft = pendingDraft else {
            return nil
        }
        pendingDraft = nil
        return draft
    }
}
