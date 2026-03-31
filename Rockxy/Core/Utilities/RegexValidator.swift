import Foundation

enum RegexValidator {
    enum ValidationError: Error, LocalizedError {
        case invalidPattern(reason: String)
        case patternTooLong(Int)

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case let .invalidPattern(reason):
                "Invalid regex pattern: \(reason)"
            case let .patternTooLong(length):
                "Pattern too long (\(length) characters, max \(maxPatternLength))"
            }
        }
    }

    static let maxPatternLength = 500

    static func compile(_ pattern: String) -> Result<NSRegularExpression, ValidationError> {
        if pattern.count > maxPatternLength {
            return .failure(.patternTooLong(pattern.count))
        }
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            return .success(regex)
        } catch {
            return .failure(.invalidPattern(reason: error.localizedDescription))
        }
    }
}
