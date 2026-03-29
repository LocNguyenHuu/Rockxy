import SwiftUI

// Renders the modify header editor interface for rule editing and management.

// MARK: - EditableHeaderOperation

/// Mutable model for editing a single header operation in the editor view.
@Observable
final class EditableHeaderOperation: Identifiable {
    // MARK: Lifecycle

    init(
        id: UUID = UUID(),
        phase: HeaderModifyPhase = .request,
        type: HeaderOperationType = .add,
        headerName: String = "",
        headerValue: String = ""
    ) {
        self.id = id
        self.phase = phase
        self.type = type
        self.headerName = headerName
        self.headerValue = headerValue
    }

    convenience init(from operation: HeaderOperation) {
        self.init(
            phase: operation.phase,
            type: operation.type,
            headerName: operation.headerName,
            headerValue: operation.headerValue ?? ""
        )
    }

    // MARK: Internal

    let id: UUID
    var phase: HeaderModifyPhase
    var type: HeaderOperationType
    var headerName: String
    var headerValue: String

    var isValid: Bool {
        guard !headerName.isEmpty else {
            return false
        }
        if type != .remove, headerValue.isEmpty {
            return false
        }
        return true
    }

    func toHeaderOperation() -> HeaderOperation {
        HeaderOperation(
            type: type,
            headerName: headerName,
            headerValue: type == .remove ? nil : headerValue,
            phase: phase
        )
    }
}

// MARK: - ModifyHeaderEditorView

/// Shared editor component for managing a list of header operations.
/// Used by both `RuleEditSheet` (inline quick-add) and `ModifyHeaderEditSheet`
/// (dedicated window editor). Supports add/remove rows, inline validation,
/// and phase selection per operation.
struct ModifyHeaderEditorView: View {
    // MARK: Internal

    @Binding var operations: [EditableHeaderOperation]

    var allValid: Bool {
        !operations.isEmpty && operations.allSatisfy(\.isValid)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            helperText

            if operations.isEmpty {
                emptyState
            } else {
                operationsTable
            }

            addButton

            validationMessages
        }
    }

    // MARK: Private

    private var helperText: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(String(localized: "Operations are applied in order. Later rows can overwrite earlier rows."))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            Text(String(localized: "No operations. Add at least one header operation."))
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.vertical, 8)
    }

    private var operationsTable: some View {
        VStack(spacing: 4) {
            headerRow

            ForEach(operations) { operation in
                operationRow(operation)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 4) {
            Text(String(localized: "Phase"))
                .frame(width: 70, alignment: .leading)
            Text(String(localized: "Operation"))
                .frame(width: 110, alignment: .leading)
            Text(String(localized: "Header Name"))
                .frame(minWidth: 100, alignment: .leading)
            Text(String(localized: "Header Value"))
                .frame(minWidth: 100, alignment: .leading)
            Spacer()
                .frame(width: 24)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private var addButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                operations.append(EditableHeaderOperation())
            }
        } label: {
            Label(String(localized: "Add Operation"), systemImage: "plus")
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .padding(.horizontal, 4)
    }

    @ViewBuilder private var validationMessages: some View {
        let invalidOps = operations.enumerated().filter { !$0.element.isValid }
        if !invalidOps.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(invalidOps, id: \.offset) { index, op in
                    if op.headerName.isEmpty {
                        Text(String(localized: "Row \(index + 1): Header Name is required"))
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if op.type != .remove, op.headerValue.isEmpty {
                        Text(
                            String(
                                localized: "Row \(index + 1): Header Value is required for \(op.type.rawValue.capitalized)"
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func operationRow(_ operation: EditableHeaderOperation) -> some View {
        HStack(spacing: 4) {
            Picker("", selection: Binding(
                get: { operation.phase },
                set: { operation.phase = $0 }
            )) {
                Text(String(localized: "Request")).tag(HeaderModifyPhase.request)
                Text(String(localized: "Response")).tag(HeaderModifyPhase.response)
                Text(String(localized: "Both")).tag(HeaderModifyPhase.both)
            }
            .labelsHidden()
            .frame(width: 70)
            .controlSize(.small)

            Picker("", selection: Binding(
                get: { operation.type },
                set: { operation.type = $0 }
            )) {
                Text(String(localized: "Add")).tag(HeaderOperationType.add)
                Text(String(localized: "Remove")).tag(HeaderOperationType.remove)
                Text(String(localized: "Replace")).tag(HeaderOperationType.replace)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 110)
            .controlSize(.small)

            TextField(
                String(localized: "Header name"),
                text: Binding(
                    get: { operation.headerName },
                    set: { operation.headerName = $0 }
                )
            )
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(.roundedBorder)
            .controlSize(.small)

            TextField(
                String(localized: "Header value"),
                text: Binding(
                    get: { operation.headerValue },
                    set: { operation.headerValue = $0 }
                )
            )
            .font(.system(.body, design: .monospaced))
            .textFieldStyle(.roundedBorder)
            .controlSize(.small)
            .disabled(operation.type == .remove)
            .opacity(operation.type == .remove ? 0.4 : 1.0)

            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    operations.removeAll { $0.id == operation.id }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .frame(width: 24)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

// MARK: - Helper: Build Operations from Editable Models

extension [EditableHeaderOperation] {
    func toHeaderOperations() -> [HeaderOperation] {
        map { $0.toHeaderOperation() }
    }

    static func from(_ operations: [HeaderOperation]) -> [EditableHeaderOperation] {
        if operations.isEmpty {
            return [EditableHeaderOperation()]
        }
        return operations.map { EditableHeaderOperation(from: $0) }
    }
}

// MARK: - Helper: Phase Summary

extension [HeaderOperation] {
    /// Computes the phase summary label for display in rule lists.
    var phaseSummaryLabel: String {
        guard !isEmpty else {
            return ""
        }
        let phases = Set(map(\.phase))
        if phases == [.request] {
            return "Req"
        }
        if phases == [.response] {
            return "Resp"
        }
        if phases == [.both] {
            return "Both"
        }
        return "Mixed"
    }

    /// Generates shorthand summary: +HeaderA, -HeaderB, ~HeaderC
    var operationSummary: String {
        map { op in
            let prefix = switch op.type {
            case .add: "+"
            case .remove: "-"
            case .replace: "~"
            }
            return "\(prefix)\(op.headerName)"
        }
        .joined(separator: ", ")
    }
}
