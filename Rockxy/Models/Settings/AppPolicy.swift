import Foundation

// MARK: - AppPolicy

/// Defines app-level capacity and feature limits.
///
/// The public baseline is ``DefaultAppPolicy``. All limit queries flow through
/// this protocol at the coordinator boundary — reusable state owners accept
/// numeric limits via init, never policy objects directly.
protocol AppPolicy: Sendable {
    var maxWorkspaceTabs: Int { get }
    var maxDomainFavorites: Int { get }
    var maxActiveRulesPerTool: Int { get }
    var maxEnabledScripts: Int { get }
    var maxLiveHistoryEntries: Int { get }
}

// MARK: - DefaultAppPolicy

/// The public open-source default policy. All values are hardcoded here
/// and represent the baseline experience.
struct DefaultAppPolicy: AppPolicy {
    let maxWorkspaceTabs = 8
    let maxDomainFavorites = 5
    let maxActiveRulesPerTool = 10
    let maxEnabledScripts = 10
    let maxLiveHistoryEntries = 1_000
}
