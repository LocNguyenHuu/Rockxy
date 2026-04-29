import Foundation

enum RulePatternBuilder {
    static func regexSource(
        rawPattern: String,
        matchType: RuleMatchType,
        includeSubpaths: Bool
    ) -> String {
        switch matchType {
        case .wildcard:
            var pattern = NSRegularExpression.escapedPattern(for: rawPattern)
                .replacingOccurrences(of: "\\*", with: ".*")
                .replacingOccurrences(of: "\\?", with: ".")
            if includeSubpaths {
                if !pattern.hasSuffix(".*") {
                    pattern += ".*"
                }
            } else {
                pattern += "($|[?#])"
            }
            return pattern
        case .regex:
            return rawPattern
        }
    }
}
