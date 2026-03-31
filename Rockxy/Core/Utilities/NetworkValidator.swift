import Foundation

enum NetworkValidator {
    static func sanitizeHeaderValue(_ value: String) -> String {
        String(value.unicodeScalars.filter { scalar in
            if scalar.value < 0x20 {
                return scalar.value == 0x09
            }
            return scalar.value != 0x7F
        })
    }
}
