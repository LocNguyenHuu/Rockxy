import SwiftUI

// Renders the custom header columns interface for the settings experience.

struct CustomHeaderColumnsView: View {
    // MARK: Internal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Custom Header Columns"))
                .font(.system(size: 13, weight: .semibold))
            Text(
                String(localized: "Get Value of Request/Response Headers and display it as a Column on the Flow Table.")
            )
            .font(.system(size: 11))
            .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                headerPanel(
                    title: String(localized: "Request Headers"),
                    source: .request,
                    selectedID: $selectedRequestID,
                    showAdd: $showAddRequest
                )
                headerPanel(
                    title: String(localized: "Response Headers"),
                    source: .response,
                    selectedID: $selectedResponseID,
                    showAdd: $showAddResponse
                )
            }

            Text(String(localized: "To manage the default columns, please Right-click on the Header Column."))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(width: 560)
        .onAppear {
            store.reload()
        }
    }

    // MARK: Private

    @State private var store = HeaderColumnStore()
    @State private var selectedRequestID: UUID?
    @State private var selectedResponseID: UUID?
    @State private var showAddRequest = false
    @State private var showAddResponse = false
    @State private var newHeaderName = ""

    @ViewBuilder
    private func headerPanel(
        title: String,
        source: HeaderColumnSource,
        selectedID: Binding<UUID?>,
        showAdd: Binding<Bool>
    )
        -> some View
    {
        let allHeaders = mergedHeaderNames(for: source)

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(allHeaders, id: \.self) { name in
                            let storedCol = store.columns.first {
                                $0.headerName == name && $0.source == source
                            }
                            let isChecked = storedCol?.isEnabled ?? false

                            HStack(spacing: 6) {
                                Button {
                                    if let col = storedCol {
                                        store.toggleColumn(id: col.id)
                                    } else {
                                        store.addColumn(headerName: name, source: source)
                                    }
                                } label: {
                                    Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 13))
                                        .foregroundStyle(
                                            isChecked
                                                ? Color.accentColor
                                                : Color(nsColor: .tertiaryLabelColor)
                                        )
                                }
                                .buttonStyle(.plain)

                                Text(name)
                                    .font(.system(size: 12))
                                    .foregroundStyle(isChecked ? .primary : .secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                selectedID.wrappedValue == storedCol?.id
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 3)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedID.wrappedValue = storedCol?.id
                            }
                        }
                    }
                    .padding(6)
                }
                .frame(minHeight: 220)
                .background(
                    Color(nsColor: .controlBackgroundColor),
                    in: RoundedRectangle(cornerRadius: 6)
                )

                HStack(spacing: 0) {
                    Button {
                        showAdd.wrappedValue = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11))
                            .frame(width: 24, height: 20)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: showAdd) {
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                TextField(
                                    String(localized: "Header name"),
                                    text: $newHeaderName
                                )
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                                .frame(width: 150)
                                Button(String(localized: "Add")) {
                                    let name = newHeaderName
                                        .trimmingCharacters(in: .whitespaces)
                                    guard !name.isEmpty else {
                                        return
                                    }
                                    store.addColumn(
                                        headerName: name,
                                        source: source
                                    )
                                    newHeaderName = ""
                                    showAdd.wrappedValue = false
                                }
                                .disabled(
                                    newHeaderName
                                        .trimmingCharacters(in: .whitespaces)
                                        .isEmpty
                                )
                            }
                        }
                        .padding(12)
                        .frame(width: 220)
                    }

                    Button {
                        if let id = selectedID.wrappedValue {
                            store.removeColumn(id: id)
                            selectedID.wrappedValue = nil
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 11))
                            .frame(width: 24, height: 20)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedID.wrappedValue == nil)

                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(alignment: .top) { Divider() }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func mergedHeaderNames(for source: HeaderColumnSource) -> [String] {
        let storedNames = store.columns
            .filter { $0.source == source }
            .map(\.headerName)
        let discoveredNames = source == .request
            ? store.discoveredRequestHeaders
            : store.discoveredResponseHeaders

        var allNames = Set(storedNames)
        allNames.formUnion(discoveredNames)
        return allNames.sorted()
    }
}
