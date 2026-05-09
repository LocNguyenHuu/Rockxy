import SwiftUI

/// SwiftUI-backed response body editor used by the inspector.
/// Keeps rendering predictable while still allowing cursor placement, selection, and local edits.
struct InspectorBodyTextEditor: View {
    let text: String
    var fontSize: CGFloat = 12

    @State private var editableText: String

    init(text: String, fontSize: CGFloat = 12) {
        self.text = text
        self.fontSize = fontSize
        _editableText = State(initialValue: text)
    }

    var body: some View {
        HStack(spacing: 0) {
            lineNumberColumn
            Divider()
            TextEditor(text: $editableText)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundStyle(.primary)
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))
                .disableAutocorrection(true)
                .textSelection(.enabled)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: text) { _, newValue in
            editableText = newValue
        }
    }

    private var lineNumberColumn: some View {
        ScrollView(.vertical) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1 ... max(1, editableText.lineCount), id: \.self) { line in
                    Text("\(line)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(height: lineHeight, alignment: .topTrailing)
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 6)
        }
        .scrollDisabled(true)
        .frame(width: 42)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var lineHeight: CGFloat {
        max(15, fontSize + 4)
    }
}

private extension String {
    var lineCount: Int {
        if isEmpty {
            return 1
        }
        return split(separator: "\n", omittingEmptySubsequences: false).count
    }
}
