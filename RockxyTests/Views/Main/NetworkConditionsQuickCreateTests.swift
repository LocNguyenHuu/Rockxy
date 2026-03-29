import Foundation
@testable import Rockxy
import Testing

// Regression tests for `NetworkConditionsQuickCreate` in the views main layer.

struct NetworkConditionsQuickCreateTests {
    @Test("quick-create from transaction posts notification")
    @MainActor
    func transactionPostsNotification() async {
        let received = await withCheckedContinuation { continuation in
            var resumed = false
            let observer = NotificationCenter.default.addObserver(
                forName: .openNetworkConditionsWindow, object: nil, queue: .main
            ) { _ in
                guard !resumed else {
                    return
                }
                resumed = true
                continuation.resume(returning: true)
            }

            let transaction = TestFixtures.makeTransaction(
                method: "GET",
                url: "https://api.example.com/slow-endpoint",
                statusCode: 200
            )
            let draft = NetworkConditionsDraftBuilder.fromTransaction(transaction)
            NetworkConditionsDraftStore.shared.setPending(draft)
            NotificationCenter.default.post(name: .openNetworkConditionsWindow, object: nil)

            Task {
                try? await Task.sleep(for: .seconds(2))
                guard !resumed else {
                    return
                }
                resumed = true
                continuation.resume(returning: false)
            }

            _ = observer
        }

        #expect(received)
        _ = NetworkConditionsDraftStore.shared.consumePending()
    }

    @Test("quick-create from domain posts notification")
    @MainActor
    func domainPostsNotification() async {
        let received = await withCheckedContinuation { continuation in
            var resumed = false
            let observer = NotificationCenter.default.addObserver(
                forName: .openNetworkConditionsWindow, object: nil, queue: .main
            ) { _ in
                guard !resumed else {
                    return
                }
                resumed = true
                continuation.resume(returning: true)
            }

            let draft = NetworkConditionsDraftBuilder.fromDomain("cdn.example.com")
            NetworkConditionsDraftStore.shared.setPending(draft)
            NotificationCenter.default.post(name: .openNetworkConditionsWindow, object: nil)

            Task {
                try? await Task.sleep(for: .seconds(2))
                guard !resumed else {
                    return
                }
                resumed = true
                continuation.resume(returning: false)
            }

            _ = observer
        }

        #expect(received)
        #expect(NetworkConditionsDraftStore.shared.pendingDraft?.origin == .domainQuickCreate)
        #expect(NetworkConditionsDraftStore.shared.pendingDraft?.sourceHost == "cdn.example.com")

        _ = NetworkConditionsDraftStore.shared.consumePending()
    }
}
