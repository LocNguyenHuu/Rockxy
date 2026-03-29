import Foundation

// Builds inspector preview content for text, structured, image, and binary bodies.

// MARK: - PreviewResult

enum PreviewResult {
    case text(String)
    case hex(String)
    case json(Any)
    case imageData(Data, width: Int?, height: Int?)
    case empty(reason: String)
}

// MARK: - PreviewRenderer

enum PreviewRenderer {
    // MARK: Internal

    static func render(body: Data?, mode: PreviewRenderMode, beautify: Bool = false) -> PreviewResult {
        guard let body, !body.isEmpty else {
            return .empty(reason: String(localized: "No body data"))
        }

        switch mode {
        case .json:
            return renderJSON(body)
        case .jsonTree:
            return renderJSONTree(body)
        case .formURLEncoded:
            return renderFormURLEncoded(body)
        case .html:
            return renderText(body, beautify: beautify, language: "html")
        case .htmlPreview:
            return renderHTMLPreview(body)
        case .css:
            return renderText(body, beautify: beautify, language: "css")
        case .javascript:
            return renderText(body, beautify: beautify, language: "js")
        case .xml:
            return renderXML(body)
        case .images:
            return renderImage(body)
        case .hex:
            return renderHex(body)
        case .raw:
            return renderRaw(body)
        }
    }

    static func formatHexDump(_ data: Data) -> String {
        var lines: [String] = []
        let bytesPerRow = 16
        for offset in stride(from: 0, to: data.count, by: bytesPerRow) {
            let end = min(offset + bytesPerRow, data.count)
            let rowBytes = data[offset ..< end]

            let offsetStr = String(format: "%08X", offset)

            var hexParts: [String] = []
            for (i, byte) in rowBytes.enumerated() {
                hexParts.append(String(format: "%02X", byte))
                if i == 7 {
                    hexParts.append("")
                }
            }
            let hexStr = hexParts.joined(separator: " ")
            let padding = String(repeating: " ", count: max(0, 49 - hexStr.count))

            let asciiStr = rowBytes.map { byte -> Character in
                (0x20 ... 0x7E).contains(byte) ? Character(UnicodeScalar(byte)) : "."
            }

            lines.append("\(offsetStr)  \(hexStr)\(padding)  \(String(asciiStr))")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: Private

    // MARK: - JSON

    private static func renderJSON(_ data: Data) -> PreviewResult {
        guard let text = String(data: data, encoding: .utf8) else {
            return .empty(reason: String(localized: "Body is not valid text"))
        }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                  withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]
              ),
              let prettyText = String(data: prettyData, encoding: .utf8) else
        {
            return .text(text)
        }
        return .text(prettyText)
    }

    private static func renderJSONTree(_ data: Data) -> PreviewResult {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            return .empty(reason: String(localized: "Body is not valid JSON"))
        }
        return .json(jsonObject)
    }

    // MARK: - Form URL-Encoded

    private static func renderFormURLEncoded(_ data: Data) -> PreviewResult {
        guard let text = String(data: data, encoding: .utf8) else {
            return .empty(reason: String(localized: "Body is not valid text"))
        }
        let pairs = text.split(separator: "&").map { pair -> String in
            let parts = pair.split(separator: "=", maxSplits: 1)
            let key = parts.first.map {
                String($0).replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String($0)
            } ?? ""
            let value = parts.count > 1
                ? (String(parts[1]).replacingOccurrences(of: "+", with: " ").removingPercentEncoding
                    ?? String(parts[1]))
                : ""
            return "\(key) = \(value)"
        }
        return .text(pairs.joined(separator: "\n"))
    }

    // MARK: - Text (HTML, CSS, JS)

    private static func renderText(_ data: Data, beautify: Bool, language: String) -> PreviewResult {
        guard let text = String(data: data, encoding: .utf8) else {
            return .empty(reason: String(localized: "Body is not valid text"))
        }
        if beautify {
            return .text(basicBeautify(text, language: language))
        }
        return .text(text)
    }

    private static func renderHTMLPreview(_ data: Data) -> PreviewResult {
        guard let text = String(data: data, encoding: .utf8) else {
            return .empty(reason: String(localized: "Body is not valid HTML"))
        }
        return .text(text)
    }

    // MARK: - XML

    private static func renderXML(_ data: Data) -> PreviewResult {
        guard let text = String(data: data, encoding: .utf8) else {
            return .empty(reason: String(localized: "Body is not valid text"))
        }
        return .text(text)
    }

    // MARK: - Image

    private static func renderImage(_ data: Data) -> PreviewResult {
        .imageData(data, width: nil, height: nil)
    }

    // MARK: - Hex

    private static func renderHex(_ data: Data) -> PreviewResult {
        .hex(formatHexDump(data))
    }

    // MARK: - Raw

    private static func renderRaw(_ data: Data) -> PreviewResult {
        if let text = String(data: data, encoding: .utf8) {
            return .text(text)
        }
        return .empty(
            reason: String(localized: "Binary data (\(SizeFormatter.format(bytes: data.count)))")
        )
    }

    // MARK: - Basic Beautify

    private static func basicBeautify(_ text: String, language: String) -> String {
        switch language {
        case "html",
             "xml":
            beautifyMarkup(text)
        case "css":
            beautifyCSS(text)
        case "js":
            beautifyJS(text)
        default:
            text
        }
    }

    private static func beautifyCSS(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "{", with: " {\n  ")
        result = result.replacingOccurrences(of: "}", with: "\n}\n")
        result = result.replacingOccurrences(of: ";", with: ";\n  ")
        result = result.replacingOccurrences(of: "\n  \n", with: "\n")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func beautifyJS(_ text: String) -> String {
        var result = ""
        var indent = 0
        let indentStr = "  "
        var inString = false
        var stringChar: Character = "\""
        var prev: Character = "\0"

        for char in text {
            if inString {
                result.append(char)
                if char == stringChar, prev != "\\" {
                    inString = false
                }
                prev = char
                continue
            }

            switch char {
            case "\"",
                 "'",
                 "`":
                inString = true
                stringChar = char
                result.append(char)
            case "{":
                indent += 1
                result.append(" {\n")
                result.append(String(repeating: indentStr, count: indent))
            case "}":
                indent = max(0, indent - 1)
                result.append("\n")
                result.append(String(repeating: indentStr, count: indent))
                result.append("}")
            case ";":
                result.append(";\n")
                result.append(String(repeating: indentStr, count: indent))
            default:
                result.append(char)
            }
            prev = char
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func beautifyMarkup(_ text: String) -> String {
        var result = ""
        var indent = 0
        let indentStr = "  "
        var i = text.startIndex

        while i < text.endIndex {
            if text[i] == "<" {
                if let closeIdx = text[i...].firstIndex(of: ">") {
                    let tag = String(text[i ... closeIdx])
                    let isClosing = tag.hasPrefix("</")
                    let isSelfClosing = tag.hasSuffix("/>")

                    if isClosing {
                        indent = max(0, indent - 1)
                    }

                    if !result.isEmpty, result.last != "\n" {
                        result += "\n"
                    }
                    result += String(repeating: indentStr, count: indent)
                    result += tag

                    if !isClosing, !isSelfClosing {
                        indent += 1
                    }

                    i = text.index(after: closeIdx)
                    continue
                }
            }
            result.append(text[i])
            i = text.index(after: i)
        }
        return result
    }
}
