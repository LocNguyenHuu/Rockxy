import SwiftUI

// Renders the advanced filter bar interface for toolbar controls and filtering.

// MARK: - AdvancedFilterBar

/// Multi-rule filter panel that lets users build compound filters with field/operator/value
/// rows. Each rule is independently toggleable. Rules are AND-combined — a transaction must
/// match all enabled rules to pass.
struct AdvancedFilterBar: View {
    // MARK: Internal

    @Binding var rules: [FilterRule]

    var onSave: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rules.enumerated()), id: \.element.id) { index, _ in
                filterRow(at: index, isFirst: index == 0)
            }
            shortcutsHint
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: Private

    private var shortcutsHint: some View {
        HStack(spacing: 12) {
            Text("Show: ⌘F")
            Text("New: ⌘N")
            Text("Remove: ⌥⌘N")
            Text("Up: ⌘↑")
            Text("Down: ⌘↓")
            Text("On/Off: ⌘B")
            Text("Hide: ESC")
        }
        .font(.system(size: 10.5))
        .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func filterRow(at index: Int, isFirst: Bool) -> some View {
        HStack(spacing: 8) {
            Toggle("", isOn: $rules[index].isEnabled)
                .toggleStyle(.checkbox)
                .labelsHidden()

            Picker("", selection: $rules[index].field) {
                ForEach(FilterField.allCases.filter { $0 != .contains }, id: \.self) { field in
                    Text(field.displayName).tag(field)
                }
            }
            .frame(width: 120)

            Picker("", selection: $rules[index].filterOperator) {
                ForEach(FilterOperator.allCases, id: \.self) { op in
                    Text(op.displayName).tag(op)
                }
            }
            .frame(width: 120)

            TextField(String(localized: "Text"), text: $rules[index].value)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12))

            Button {
                removeRule(at: index)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                addRule(after: index)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if isFirst {
                Button(String(localized: "Save"), action: onSave)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, index == 0 ? 8 : 4)
        .padding(.bottom, 0)
        .opacity(rules[index].isEnabled ? 1.0 : 0.5)
    }

    private func addRule(after index: Int) {
        let newRule = FilterRule()
        rules.insert(newRule, at: index + 1)
    }

    private func removeRule(at index: Int) {
        guard rules.count > 1 else {
            return
        }
        rules.remove(at: index)
    }
}
