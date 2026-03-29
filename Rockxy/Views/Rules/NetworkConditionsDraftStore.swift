import Foundation

/// Singleton cross-window store for Network Conditions draft handoff.
@MainActor @Observable
final class NetworkConditionsDraftStore {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = NetworkConditionsDraftStore()

    private(set) var pendingDraft: NetworkConditionsDraft?
    var draftVersion: UInt64 = 0

    func setPending(_ draft: NetworkConditionsDraft) {
        pendingDraft = draft
        consumed = false
        draftVersion &+= 1
    }

    func consumePending() -> NetworkConditionsDraft? {
        guard !consumed, let draft = pendingDraft else {
            return nil
        }
        consumed = true
        return draft
    }

    // MARK: Private

    private var consumed = false
}
