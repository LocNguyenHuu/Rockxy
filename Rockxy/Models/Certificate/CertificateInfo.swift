import Foundation

/// Read-only snapshot of an X.509 certificate's metadata, displayed in the
/// certificate inspector tab. Includes the PEM-encoded certificate for export.
nonisolated struct CertificateInfo: Identifiable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        commonName: String,
        serialNumber: String,
        notValidBefore: Date,
        notValidAfter: Date,
        isCA: Bool,
        issuerCommonName: String,
        pemEncoded: String
    ) {
        self.id = id
        self.commonName = commonName
        self.serialNumber = serialNumber
        self.notValidBefore = notValidBefore
        self.notValidAfter = notValidAfter
        self.isCA = isCA
        self.issuerCommonName = issuerCommonName
        self.pemEncoded = pemEncoded
    }

    // MARK: Internal

    let id: UUID
    let commonName: String
    let serialNumber: String
    let notValidBefore: Date
    let notValidAfter: Date
    let isCA: Bool
    let issuerCommonName: String
    let pemEncoded: String
}
