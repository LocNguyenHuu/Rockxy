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
/// Wraps ``ScriptPluginManager.enablePlugin(id:)`` with a count check
/// against the policy limit. Disable calls bypass the gate.
@MainActor
final class ScriptPolicyGate {
    // MARK: Lifecycle

    init(policy: any AppPolicy = DefaultAppPolicy()) {
        self.policy = policy
    }

    // MARK: Internal

    static var shared = ScriptPolicyGate()

    let policy: any AppPolicy

    func enablePlugin(id: String, using manager: ScriptPluginManager) async throws {
        let plugins = await manager.plugins
        let enabledCount = plugins.filter(\.isEnabled).count
        guard enabledCount < policy.maxEnabledScripts else {
            Self.logger.info("Script quota reached (\(self.policy.maxEnabledScripts))")
            throw ScriptQuotaError.limitReached(max: policy.maxEnabledScripts)
        }
        try await manager.enablePlugin(id: id)
    }

    // MARK: Private

    private static let logger = Logger(
        subsystem: RockxyIdentity.current.logSubsystem,
        category: "ScriptPolicyGate"
    )
}
