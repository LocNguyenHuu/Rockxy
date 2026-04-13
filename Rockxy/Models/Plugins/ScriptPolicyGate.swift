import Foundation
import os

// MARK: - ScriptQuotaError

enum ScriptQuotaError: LocalizedError {
    case limitReached(max: Int)

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case let .limitReached(max):
            String(localized: "Script plugin limit reached (maximum \(max))")
        }
    }
}

// MARK: - ScriptPolicyGate

/// App-layer quota gate for script plugin enablement.
/// Uses ``ScriptPluginManager.enablePluginIfAllowed(id:maxEnabled:)`` for
/// atomic check-and-enable within the actor's serialized context.
@MainActor
final class ScriptPolicyGate {
    // MARK: Lifecycle

    init(policy: any AppPolicy = DefaultAppPolicy()) {
        self.policy = policy
    }

    // MARK: Internal

    private(set) static var shared = ScriptPolicyGate()

    let policy: any AppPolicy

    static func configure(policy: any AppPolicy) {
        guard !isConfigured else {
            return
        }
        isConfigured = true
        shared = ScriptPolicyGate(policy: policy)
    }

    /// Reset shared state for testing. Not for production use.
    static func resetForTesting(policy: any AppPolicy = DefaultAppPolicy()) {
        isConfigured = false
        configure(policy: policy)
    }

    func enablePlugin(id: String, using manager: ScriptPluginManager) async throws {
        let accepted = try await manager.enablePluginIfAllowed(
            id: id,
            maxEnabled: policy.maxEnabledScripts
        )
        if !accepted {
            throw ScriptQuotaError.limitReached(max: policy.maxEnabledScripts)
        }
    }

    // MARK: Private

    private static var isConfigured = false

    private static let logger = Logger(
        subsystem: RockxyIdentity.current.logSubsystem,
        category: "ScriptPolicyGate"
    )
}
