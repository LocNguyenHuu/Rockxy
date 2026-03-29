import SwiftUI

/// Displays the full HTTP transaction as raw text, reconstructing the wire format
/// with request line, headers, body, and (if available) the response in the same format.
struct RawInspectorView: View {
    // MARK: Internal

    let transaction: HTTPTransaction

    var body: some View {
        ScrollView {
            Text(buildRawText())
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding()
        }
    }

    // MARK: Private

    private func buildRawText() -> String {
        var text = ""
        let request = transaction.request
        text += "\(request.method) \(request.path) \(request.httpVersion)\n"
        text += "Host: \(request.host)\n"
        for header in request.headers {
            text += "\(header.name): \(header.value)\n"
        }
        if let body = request.body, let bodyString = String(data: body, encoding: .utf8) {
            text += "\n\(bodyString)"
        }

        if let response = transaction.response {
            text += "\n\n--- Response ---\n"
            text += "HTTP \(response.statusCode) \(response.statusMessage)\n"
            for header in response.headers {
                text += "\(header.name): \(header.value)\n"
            }
            if let body = response.body, let bodyString = String(data: body, encoding: .utf8) {
                text += "\n\(bodyString)"
            }
        }
        return text
    }
}
