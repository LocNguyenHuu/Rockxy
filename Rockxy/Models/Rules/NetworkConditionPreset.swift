import Foundation

/// Named latency presets for Network Conditions, modeled after Apple's Network Link Conditioner.
enum NetworkConditionPreset: String, CaseIterable, Codable {
    case threeG
    case edge
    case lte
    case veryBadNetwork
    case wifi
    case custom

    // MARK: Internal

    var displayName: String {
        switch self {
        case .threeG: "3G"
        case .edge: "EDGE"
        case .lte: "LTE"
        case .veryBadNetwork: "Very Bad Network"
        case .wifi: "WiFi"
        case .custom: "Custom"
        }
    }

    var defaultLatencyMs: Int {
        switch self {
        case .threeG: 400
        case .edge: 850
        case .lte: 50
        case .veryBadNetwork: 2000
        case .wifi: 2
        case .custom: 0
        }
    }

    var systemImage: String {
        switch self {
        case .threeG: "antenna.radiowaves.left.and.right"
        case .edge: "antenna.radiowaves.left.and.right"
        case .lte: "cellularbars"
        case .veryBadNetwork: "wifi.slash"
        case .wifi: "wifi"
        case .custom: "slider.horizontal.3"
        }
    }

    static func from(delayMs: Int) -> NetworkConditionPreset {
        for preset in allCases where preset != .custom {
            if preset.defaultLatencyMs == delayMs {
                return preset
            }
        }
        return .custom
    }

    static func makeRule(
        preset: NetworkConditionPreset,
        latencyMs: Int,
        name: String,
        matchCondition: RuleMatchCondition
    )
        -> ProxyRule
    {
        ProxyRule(
            name: name,
            matchCondition: matchCondition,
            action: .networkCondition(preset: preset, delayMs: latencyMs)
        )
    }
}
