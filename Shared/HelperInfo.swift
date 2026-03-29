import Foundation

/// Structured helper information returned by the `getHelperInfo` XPC method.
/// Replaces the single version string from the legacy `getHelperVersion`.
struct HelperInfo: Equatable {
    let binaryVersion: String
    let buildNumber: Int
    let protocolVersion: Int
}
