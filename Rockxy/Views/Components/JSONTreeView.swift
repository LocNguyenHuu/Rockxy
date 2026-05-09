import SwiftUI

// Renders the json tree interface for shared app surfaces.

// MARK: - JSONTreeView

/// Collapsible JSON tree with syntax highlighting. Parses raw `Data` via `JSONSerialization`,
/// converts it to a recursive `JSONTreeValue` enum, and renders each node with
/// theme-aware colors for keys, strings, numbers, booleans, nulls, and brackets.
struct JSONTreeView: View {
    // MARK: Internal

    let data: Data

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical]) {
                content
                    .padding(Self.contentPadding)
                    .frame(
                        minWidth: max(0, proxy.size.width - Self.contentPadding * 2),
                        minHeight: max(0, proxy.size.height - Self.contentPadding * 2),
                        alignment: .topLeading
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: data) {
            await parseCurrentData()
        }
    }

    // MARK: Private

    private static let contentPadding: CGFloat = 12

    @State private var state: JSONTreeLoadState = .loading

    @ViewBuilder private var content: some View {
        switch state {
        case .loading:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text(String(localized: "Parsing JSON..."))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case let .parsed(parsed):
            JSONTreeNodeView(value: parsed, key: nil, depth: 0, isLast: true)

        case let .text(text):
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)

        case .unavailable:
            Text(String(localized: "Unable to display content"))
                .foregroundStyle(.secondary)
        }
    }

    @MainActor
    private func parseCurrentData() async {
        state = .loading

        let result = try? await Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            let result = Self.parse(data)
            try Task.checkCancellation()
            return result
        }.value

        guard let result, !Task.isCancelled else {
            return
        }
        state = result
    }

    nonisolated private static func parse(_ data: Data) -> JSONTreeLoadState {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            if let text = String(data: data, encoding: .utf8) {
                return .text(text)
            }
            return .unavailable
        }
        guard let parsed = JSONTreeValue(from: object) else {
            return .unavailable
        }
        return .parsed(parsed)
    }
}

// MARK: - JSONTreeLoadState

private enum JSONTreeLoadState: Sendable {
    case loading
    case parsed(JSONTreeValue)
    case text(String)
    case unavailable
}

// MARK: - JSONTreeValue

/// Recursive enum representing a parsed JSON value. Object keys are sorted alphabetically
/// for stable display order. Uses `CFBooleanGetTypeID` to distinguish booleans from numbers,
/// since `NSJSONSerialization` represents both as `NSNumber`.
private enum JSONTreeValue: Sendable {
    case string(String)
    case number(String)
    case bool(Bool)
    case null
    case array([JSONTreeValue])
    case object([(key: String, value: JSONTreeValue)])

    // MARK: Lifecycle

    init?(from object: Any) {
        switch object {
        case let dict as [String: Any]:
            let pairs = dict.keys.sorted().compactMap { key -> (key: String, value: JSONTreeValue)? in
                guard let val = JSONTreeValue(from: dict[key] as Any) else {
                    return nil
                }
                return (key: key, value: val)
            }
            self = .object(pairs)
        case let array as [Any]:
            self = .array(array.compactMap { JSONTreeValue(from: $0) })
        case let string as String:
            self = .string(string)
        case let number as NSNumber:
            if CFBooleanGetTypeID() == CFGetTypeID(number) {
                self = .bool(number.boolValue)
            } else {
                self = .number(number.stringValue)
            }
        case is NSNull:
            self = .null
        default:
            return nil
        }
    }

    // MARK: Internal

    var isContainer: Bool {
        switch self {
        case .object,
             .array: true
        default: false
        }
    }

    var childCount: Int {
        switch self {
        case let .object(pairs): pairs.count
        case let .array(items): items.count
        default: 0
        }
    }
}

// MARK: - JSONTreeNodeView

/// Recursive view that renders a single JSON node. Container nodes (objects/arrays) show a
/// disclosure triangle and can be collapsed; leaf nodes render inline with the key label.
private struct JSONTreeNodeView: View {
    // MARK: Internal

    let value: JSONTreeValue
    let key: String?
    let depth: Int
    let isLast: Bool

    var body: some View {
        switch value {
        case let .object(pairs):
            containerView(
                openBracket: "{",
                closeBracket: "}",
                count: pairs.count
            ) {
                ForEach(Array(pairs.enumerated()), id: \.offset) { index, pair in
                    JSONTreeNodeView(
                        value: pair.value,
                        key: pair.key,
                        depth: depth + 1,
                        isLast: index == pairs.count - 1
                    )
                }
            }

        case let .array(items):
            containerView(
                openBracket: "[",
                closeBracket: "]",
                count: items.count
            ) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    JSONTreeNodeView(
                        value: item,
                        key: nil,
                        depth: depth + 1,
                        isLast: index == items.count - 1
                    )
                }
            }

        case let .string(str):
            leafView {
                Text("\"\(str)\"")
                    .foregroundStyle(Theme.JSON.string)
            }

        case let .number(num):
            leafView {
                Text(num)
                    .foregroundStyle(Theme.JSON.number)
            }

        case let .bool(val):
            leafView {
                Text(val ? "true" : "false")
                    .foregroundStyle(Theme.JSON.bool)
            }

        case .null:
            leafView {
                Text("null")
                    .foregroundStyle(Theme.JSON.null)
            }
        }
    }

    // MARK: Private

    private static let indentWidth: CGFloat = 16

    @State private var isExpanded = true

    private var comma: String {
        isLast ? "" : ","
    }

    @ViewBuilder private var keyLabel: some View {
        if let key {
            Text("\"\(key)\"")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.JSON.key)
            Text(": ")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private var disclosureButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.borderless)
    }

    private func containerView(
        openBracket: String,
        closeBracket: String,
        count: Int,
        @ViewBuilder children: () -> some View
    )
        -> some View
    {
        VStack(alignment: .leading, spacing: 0) {
            // Header: key: { or [
            HStack(spacing: 0) {
                disclosureButton
                keyLabel
                Text(isExpanded ? openBracket : "\(openBracket)...\(closeBracket)\(comma)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Theme.JSON.bracket)
                if !isExpanded {
                    Text(" // \(count) items")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.leading, CGFloat(depth) * Self.indentWidth)

            // Children
            if isExpanded {
                children()

                // Closing bracket
                HStack(spacing: 0) {
                    Text("\(closeBracket)\(comma)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Theme.JSON.bracket)
                }
                .padding(.leading, CGFloat(depth) * Self.indentWidth)
            }
        }
    }

    private func leafView(
        @ViewBuilder valueContent: () -> some View
    )
        -> some View
    {
        HStack(spacing: 0) {
            Spacer()
                .frame(width: 16) // alignment with disclosure triangle
            keyLabel
            valueContent()
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
            Text(comma)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Theme.JSON.bracket)
        }
        .padding(.leading, CGFloat(depth) * Self.indentWidth)
    }
}
