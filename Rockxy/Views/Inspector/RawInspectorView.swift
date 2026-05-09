import SwiftUI

/// Displays the full HTTP transaction as raw text, reconstructing the wire format
/// with request line, headers, body, and (if available) the response in the same format.
struct RawInspectorView: View {
    // MARK: Internal

    let transaction: HTTPTransaction

    var body: some View {
        InspectorBodyTextEditor(text: buildRawText(), fontSize: 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Private

    private func buildRawText() -> String {
        var text = ""
        text += RequestCopyFormatter.rawRequest(for: transaction)

        if let rawResponse = RequestCopyFormatter.rawResponse(for: transaction) {
            text += "\r\n\r\n--- Response ---\r\n"
            text += rawResponse
        }
        return text
    }
}
