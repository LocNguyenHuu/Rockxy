import SwiftUI

/// Displays the Authorization header from a captured HTTP transaction,
/// identifying the auth scheme (Bearer, Basic, Digest) and showing the full header value.
struct AuthInspectorView: View {
    // MARK: Internal

    let transaction: HTTPTransaction

    var body: some View {
        if let authHeader = findAuthHeader() {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    labelRow(String(localized: "Type"), authType(from: authHeader))
                    Divider()
                    labelRow(String(localized: "Full Value"), authHeader)
                }
                .padding()
            }
        } else {
            InspectorEmptyStateView(
                String(localized: "No Authorization"),
                systemImage: "lock.open",
                description: String(localized: "No Authorization header found")
            )
        }
    }

    // MARK: Private

    private func labelRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    private func findAuthHeader() -> String? {
        transaction.request.headers
            .first { $0.name.lowercased() == "authorization" }?
            .value
    }

    private func authType(from value: String) -> String {
        if value.lowercased().hasPrefix("bearer") {
            return "Bearer Token"
        } else if value.lowercased().hasPrefix("basic") {
            return "Basic Auth"
        } else if value.lowercased().hasPrefix("digest") {
            return "Digest Auth"
        }
        return String(localized: "Unknown")
    }
}
