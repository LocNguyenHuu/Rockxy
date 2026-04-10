import SwiftUI

// Renders the response inspector interface for the request and response inspector.

// MARK: - ResponseInspectorView

/// Right half of the inspector split view. Provides tabbed access to response-side data:
/// headers, body (with format picker), Set-Cookie headers, auth, and timing breakdown.
/// Also supports custom preview tabs from PreviewTabStore.
/// Conditionally shows protocol-specific tabs (WebSocket, GraphQL) when the selected
/// transaction has protocol-specific data.
struct ResponseInspectorView: View {
    // MARK: Internal

    let transaction: HTTPTransaction
    var previewTabStore: PreviewTabStore

    var body: some View {
        VStack(spacing: 0) {
            Text(String(localized: "Response"))
                .font(.system(size: 12, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 4)
            inspectorTabBar
            Divider()
            tabContent
        }
        .task(id: transaction.id) {
            autoSelectProtocolTab()
        }
    }

    // MARK: Private

    @State private var selectedTab: ResponseInspectorTab = .headers
    @State private var selectedPreviewTab: PreviewTab?
    @State private var protocolTab: ProtocolTabKind?

    @State private var showPreviewPopover = false

    private var hasProtocolTab: Bool {
        transaction.webSocketConnection != nil || transaction.graphQLInfo != nil
    }

    private var inspectorTabBar: some View {
        HStack(spacing: 0) {
            ForEach(ResponseInspectorTab.allCases, id: \.self) { tab in
                InspectorTabButton(
                    title: tab.displayName,
                    isActive: protocolTab == nil && selectedPreviewTab == nil && selectedTab == tab
                ) {
                    protocolTab = nil
                    selectedPreviewTab = nil
                    selectedTab = tab
                }
            }

            if hasProtocolTab {
                Divider()
                    .frame(height: 14)
                    .padding(.horizontal, 4)

                if transaction.webSocketConnection != nil {
                    InspectorTabButton(
                        title: String(localized: "WebSocket"),
                        isActive: protocolTab == .websocket
                    ) {
                        protocolTab = .websocket
                        selectedPreviewTab = nil
                    }
                }

                if transaction.graphQLInfo != nil {
                    InspectorTabButton(
                        title: String(localized: "GraphQL"),
                        isActive: protocolTab == .graphql
                    ) {
                        protocolTab = .graphql
                        selectedPreviewTab = nil
                    }
                }
            }

            if !previewTabStore.responseTabs.isEmpty {
                Divider()
                    .frame(height: 14)
                    .padding(.horizontal, 4)

                ForEach(previewTabStore.responseTabs) { tab in
                    InspectorTabButton(
                        title: tab.name,
                        isActive: selectedPreviewTab == tab
                    ) {
                        protocolTab = nil
                        selectedPreviewTab = tab
                    }
                }
            }

            previewTabMenuButton
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }

    private var previewTabMenuButton: some View {
        Button {
            showPreviewPopover.toggle()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .help(String(localized: "Preview Tabs"))
        .padding(.leading, 2)
        .popover(isPresented: $showPreviewPopover, arrowEdge: .bottom) {
            PreviewTabPopover(panel: .response, store: previewTabStore)
        }
    }

    @ViewBuilder private var tabContent: some View {
        if let proto = protocolTab {
            switch proto {
            case .websocket:
                WebSocketInspectorView(transaction: transaction)
            case .graphql:
                GraphQLInspectorView(transaction: transaction)
            }
        } else if let previewTab = selectedPreviewTab,
                  previewTabStore.responseTabs.contains(where: { $0.id == previewTab.id })
        {
            PreviewTabContentView(
                tab: previewTab,
                transaction: transaction,
                beautify: previewTabStore.autoBeautify
            )
        } else {
            nativeTabContent
        }
    }

    @ViewBuilder private var nativeTabContent: some View {
        if let response = transaction.response {
            switch selectedTab {
            case .headers:
                responseHeadersView(response: response)
            case .body:
                responseBodyView(response: response)
            case .setCookie:
                SetCookieInspectorView(transaction: transaction)
            case .auth:
                AuthInspectorView(transaction: transaction)
            case .timeline:
                TimingInspectorView(transaction: transaction)
            }
        } else {
            ContentUnavailableView(
                String(localized: "No Response"),
                systemImage: "arrow.down.circle",
                description: Text(String(localized: "Waiting for response..."))
            )
        }
    }

    private func responseHeadersView(response: HTTPResponseData) -> some View {
        ScrollView {
            if response.headers.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Headers"),
                    systemImage: "list.bullet"
                )
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 120, maximum: 200), alignment: .topLeading),
                    GridItem(.flexible(), alignment: .topLeading),
                ], spacing: 4) {
                    ForEach(Array(response.headers.enumerated()), id: \.offset) { _, header in
                        Text(header.name)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                        Text(header.value)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func responseBodyView(response: HTTPResponseData) -> some View {
        if response.contentType == .json, response.body != nil {
            JSONInspectorView(transaction: transaction)
        } else if let body = response.body {
            ScrollView {
                if let text = String(data: body, encoding: .utf8) {
                    Text(text)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                } else {
                    Text("\(body.count) bytes (binary)")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
        } else {
            ContentUnavailableView(
                String(localized: "No Body"),
                systemImage: "doc",
                description: Text(String(localized: "This response has no body"))
            )
        }
    }

    private func autoSelectProtocolTab() {
        protocolTab = ProtocolTabKind.defaultFor(transaction)
        if protocolTab != nil {
            selectedPreviewTab = nil
        }
    }
}

// MARK: - ProtocolTabKind

/// Protocol-specific tab selection for the response inspector.
/// Separate from ResponseInspectorTab to avoid showing protocol tabs for all transactions.
enum ProtocolTabKind {
    case websocket
    case graphql

    // MARK: Internal

    /// Returns the default protocol tab for a transaction, or nil for plain HTTP.
    static func defaultFor(_ transaction: HTTPTransaction) -> ProtocolTabKind? {
        if transaction.webSocketConnection != nil {
            return .websocket
        }
        if transaction.graphQLInfo != nil {
            return .graphql
        }
        return nil
    }
}
