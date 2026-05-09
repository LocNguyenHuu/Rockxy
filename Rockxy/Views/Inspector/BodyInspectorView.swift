import SwiftUI

/// Renders the response body of an HTTP transaction as UTF-8 text, or shows
/// the byte count for binary payloads that cannot be decoded as text.
struct BodyInspectorView: View {
    let transaction: HTTPTransaction

    var body: some View {
        if let body = transaction.response?.body {
            AsyncInspectorTextEditor(
                renderID: "\(transaction.id.uuidString)-legacy-body-\(body.count)",
                fontSize: 12
            ) {
                InspectorPayloadFormatter.requestBodyText(body)
            }
        } else {
            InspectorEmptyStateView(
                String(localized: "No Body"),
                systemImage: "doc",
                description: String(localized: "This response has no body")
            )
        }
    }
}
