import SwiftUI

/// Renders the response body of an HTTP transaction as UTF-8 text, or shows
/// the byte count for binary payloads that cannot be decoded as text.
struct BodyInspectorView: View {
    let transaction: HTTPTransaction

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let body = transaction.response?.body {
                    if let text = String(data: body, encoding: .utf8) {
                        Text(text)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                    } else {
                        Text("\(body.count) bytes (binary)")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                } else {
                    Text("No body")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        }
    }
}
