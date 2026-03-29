import SwiftUI

// Renders the compose request editor interface for the compose workflow.

// MARK: - ComposeRequestEditor

/// Left panel of the Compose window. Segmented tabs for Headers, Query, Body, and Raw.
struct ComposeRequestEditor: View {
    // MARK: Internal

    @Bindable var viewModel: ComposeViewModel

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(ComposeRequestTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Divider()

            Group {
                switch selectedTab {
                case .headers:
                    headersEditor
                case .query:
                    queryEditor
                case .body:
                    bodyEditor
                case .raw:
                    rawView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Private

    @State private var selectedTab: ComposeRequestTab = .headers

    // MARK: - Headers Tab

    private var headersEditor: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                columnHeaders(name: "Name", value: "Value")

                ForEach(viewModel.headers) { header in
                    HStack(spacing: 8) {
                        TextField(
                            String(localized: "Header name"),
                            text: headerNameBinding(for: header.id)
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))

                        TextField(
                            String(localized: "Header value"),
                            text: headerValueBinding(for: header.id)
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))

                        removeButton {
                            viewModel.removeHeader(id: header.id)
                        }
                    }
                }

                addButton(String(localized: "Add Header")) {
                    viewModel.addHeader()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(12)
        }
    }

    // MARK: - Query Tab

    private var queryEditor: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                columnHeaders(name: "Name", value: "Value")

                ForEach(viewModel.queryItems) { item in
                    HStack(spacing: 8) {
                        TextField(
                            String(localized: "Parameter name"),
                            text: queryNameBinding(for: item.id)
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))

                        TextField(
                            String(localized: "Parameter value"),
                            text: queryValueBinding(for: item.id)
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))

                        removeButton {
                            viewModel.removeQueryItem(id: item.id)
                        }
                    }
                }

                addButton(String(localized: "Add Parameter")) {
                    viewModel.addQueryItem()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(12)
        }
    }

    // MARK: - Body Tab

    private var bodyEditor: some View {
        TextEditor(text: $viewModel.body)
            .font(.system(.body, design: .monospaced))
            .padding(8)
    }

    // MARK: - Raw Tab

    private var rawView: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(viewModel.rawRequestText)
                .font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
    }

    // MARK: - Shared Helpers

    private func columnHeaders(name: String, value: String) -> some View {
        HStack {
            Text(String(localized: String.LocalizationValue(name)))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(localized: String.LocalizationValue(value)))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 24)
        }
        .padding(.bottom, 4)
    }

    private func removeButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
    }

    private func addButton(_ title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Button(action: action) {
                Label(title, systemImage: "plus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.top, 2)
    }

    // MARK: - Bindings

    private func headerNameBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { viewModel.headers.first(where: { $0.id == id })?.name ?? "" },
            set: { newValue in
                if let idx = viewModel.headers.firstIndex(where: { $0.id == id }) {
                    viewModel.headers[idx].name = newValue
                }
            }
        )
    }

    private func headerValueBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { viewModel.headers.first(where: { $0.id == id })?.value ?? "" },
            set: { newValue in
                if let idx = viewModel.headers.firstIndex(where: { $0.id == id }) {
                    viewModel.headers[idx].value = newValue
                }
            }
        )
    }

    private func queryNameBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { viewModel.queryItems.first(where: { $0.id == id })?.name ?? "" },
            set: { newValue in
                if let idx = viewModel.queryItems.firstIndex(where: { $0.id == id }) {
                    viewModel.queryItems[idx].name = newValue
                    viewModel.syncQueryToURL()
                }
            }
        )
    }

    private func queryValueBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { viewModel.queryItems.first(where: { $0.id == id })?.value ?? "" },
            set: { newValue in
                if let idx = viewModel.queryItems.firstIndex(where: { $0.id == id }) {
                    viewModel.queryItems[idx].value = newValue
                    viewModel.syncQueryToURL()
                }
            }
        )
    }
}

// MARK: - ComposeRequestTab

private enum ComposeRequestTab: String, CaseIterable, Identifiable {
    case headers
    case query
    case body
    case raw

    // MARK: Internal

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .headers: String(localized: "Headers")
        case .query: String(localized: "Query")
        case .body: String(localized: "Body")
        case .raw: String(localized: "Raw")
        }
    }
}
