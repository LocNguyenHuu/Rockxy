import SwiftUI

/// Placeholder for the TLS certificate chain inspector.
/// Will display subject, issuer, validity, and chain details for intercepted HTTPS connections.
struct CertificateInspectorView: View {
    var body: some View {
        ContentUnavailableView(
            "Certificate Inspector",
            systemImage: "lock.shield",
            description: Text(String(localized: "Certificate chain inspection is planned for a future release."))
        )
    }
}
