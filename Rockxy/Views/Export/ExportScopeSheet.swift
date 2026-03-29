import SwiftUI

// Renders the export scope sheet interface for session export.

// MARK: - ExportScopeSheet

/// Scope picker sheet for HAR export. Shows radio-style selection for All/Filtered/Selected
/// transaction scopes with counts, plus a privacy note. Matches the Figma design at file
/// BmxrbvKOU3Q2wZUe2NT87Y node 8:4.
struct ExportScopeSheet: View {
    // MARK: Internal

    let context: ExportScopeContext
    var onExport: (ExportScope) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            title

            sectionLabel(String(localized: "SCOPE"))

            scopePicker

            privacyNote

            bottomBar
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(width: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: Private

    @State private var selectedScope: ExportScope = .all

    private var title: some View {
        Text(String(localized: "Export as HAR"))
            .font(.system(size: 15, weight: .semibold))
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var scopePicker: some View {
        VStack(spacing: 0) {
            scopeRow(
                scope: .all,
                label: String(localized: "All Transactions"),
                count: context.allCount,
                isDisabled: false
            )

            dividerLine

            scopeRow(
                scope: .filtered,
                label: String(localized: "Visible / Filtered"),
                count: context.filteredCount,
                isDisabled: !context.hasActiveFilter
            )

            dividerLine

            scopeRow(
                scope: .selected,
                label: String(localized: "Selected"),
                count: context.selectedCount,
                isDisabled: !context.hasSelection
            )
        }
    }

    private var privacyNote: some View {
        Text(String(localized: "Exported files may contain request bodies, cookies, and authorization headers."))
            .font(.system(size: 12))
            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 1)
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            dividerLine

            HStack(spacing: 8) {
                Spacer()

                Button(String(localized: "Cancel")) {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                .controlSize(.small)
                .frame(width: 68, height: 25)

                Button {
                    onExport(selectedScope)
                } label: {
                    Text(String(localized: "Export\u{2026}"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 25)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
            .tracking(0.3)
            .textCase(.uppercase)
    }

    private func scopeRow(
        scope: ExportScope,
        label: String,
        count: Int,
        isDisabled: Bool
    )
        -> some View
    {
        let isSelected = selectedScope == scope

        return Button {
            if !isDisabled {
                selectedScope = scope
            }
        } label: {
            HStack(spacing: 0) {
                radioIndicator(isSelected: isSelected, isDisabled: isDisabled)

                Spacer()
                    .frame(width: 8)

                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(
                        isSelected
                            ? .white
                            : isDisabled
                            ? Color(nsColor: .tertiaryLabelColor)
                            : Color(nsColor: .labelColor)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(count)")
                    .font(.system(size: 12))
                    .foregroundStyle(
                        isSelected
                            ? .white
                            : Color(nsColor: .secondaryLabelColor)
                    )
            }
            .padding(.horizontal, 12)
            .frame(height: 29)
            .background(
                isSelected
                    ? Color.accentColor
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func radioIndicator(isSelected: Bool, isDisabled: Bool) -> some View {
        Circle()
            .strokeBorder(
                isSelected
                    ? Color.white
                    : isDisabled
                    ? Color(nsColor: .tertiaryLabelColor)
                    : Color(nsColor: .secondaryLabelColor),
                lineWidth: isSelected ? 4 : 1.5
            )
            .background(
                Circle()
                    .fill(isSelected ? Color.white : Color.clear)
                    .padding(isSelected ? 3 : 0)
            )
            .frame(width: 14, height: 14)
    }
}
