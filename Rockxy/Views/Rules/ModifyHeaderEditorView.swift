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
        validationMessage == nil
    }

    var validationMessage: String? {
        guard !headerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return String(localized: "Header Name is required")
        }
        if type != .remove, headerValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return String(localized: "Header Value is required for \(type.rawValue.capitalized)")
        }
        return nil
    }

    func toHeaderOperation() -> HeaderOperation {
        HeaderOperation(
            type: type,
            headerName: headerName.trimmingCharacters(in: .whitespacesAndNewlines),
            headerValue: type == .remove ? nil : headerValue.trimmingCharacters(in: .whitespacesAndNewlines),
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
        !operations.isEmpty && operations.allSatisfy { $0.validationMessage == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
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

    private static let phaseWidth: CGFloat = 92
    private static let operationWidth: CGFloat = 104
    private static let minFieldWidth: CGFloat = 150
    private static let removeWidth: CGFloat = 24

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
        VStack(spacing: 6) {
            headerRow

            ForEach(operations) { operation in
                operationRow(operation)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            Text(String(localized: "Phase"))
                .frame(width: Self.phaseWidth, alignment: .leading)
            Text(String(localized: "Operation"))
                .frame(width: Self.operationWidth, alignment: .leading)
            Text(String(localized: "Header Name"))
                .frame(minWidth: Self.minFieldWidth, maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "Header Value"))
                .frame(minWidth: Self.minFieldWidth, maxWidth: .infinity, alignment: .leading)
            Spacer()
                .frame(width: Self.removeWidth)
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
        .padding(.horizontal, 2)
    }

    @ViewBuilder private var validationMessages: some View {
        let invalidOps = operations.enumerated().compactMap { index, op -> (Int, String)? in
            guard let message = op.validationMessage else {
                return nil
            }
            return (index, message)
        }
        if !invalidOps.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(invalidOps, id: \.0) { index, message in
                    Text(String(localized: "Row \(index + 1): \(message)"))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func operationRow(_ operation: EditableHeaderOperation) -> some View {
        HStack(spacing: 8) {
            Picker("", selection: Binding(
                get: { operation.phase },
                set: { operation.phase = $0 }
            )) {
                Text(String(localized: "Request")).tag(HeaderModifyPhase.request)
                Text(String(localized: "Response")).tag(HeaderModifyPhase.response)
                Text(String(localized: "Both")).tag(HeaderModifyPhase.both)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: Self.phaseWidth)
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
            .pickerStyle(.menu)
            .frame(width: Self.operationWidth)
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
            .frame(minWidth: Self.minFieldWidth)

            TextField(
                operation.type == .remove
                    ? String(localized: "Not used")
                    : String(localized: "Header value"),
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
            .frame(minWidth: Self.minFieldWidth)

            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    operations.removeAll { $0.id == operation.id }
                }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .frame(width: Self.removeWidth)
        }
        .padding(.horizontal, 2)
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
