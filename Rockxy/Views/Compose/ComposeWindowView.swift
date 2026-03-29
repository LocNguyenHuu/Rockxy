import SwiftUI

// Presents the compose window for the compose workflow.

// MARK: - ComposeWindowView

/// Standalone Compose window for editing and repeatedly sending HTTP requests.
/// Top compose bar (method + URL + Send) spans the full width. Below, an HSplitView
/// divides the request editor (left) from the response viewer (right).
struct ComposeWindowView: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            composeBar
            Divider()
            HSplitView {
                ComposeRequestEditor(viewModel: viewModel)
                    .frame(minWidth: 300)
                ComposeResponseViewer(viewModel: viewModel)
                    .frame(minWidth: 300)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            consumePendingTransaction()
        }
        .onChange(of: ComposeStore.shared.draftVersion) {
            consumePendingTransaction()
        }
    }

    // MARK: Private

    private static let httpMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"]

    @State private var viewModel = ComposeViewModel()

    private var composeBar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $viewModel.method) {
                ForEach(Self.httpMethods, id: \.self) { method in
                    Text(method).tag(method)
                }
            }
            .labelsHidden()
            .frame(width: 100)

            TextField(String(localized: "URL"), text: $viewModel.url)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onSubmit {
                    Task { await viewModel.send() }
                }
                .onChange(of: viewModel.url) {
                    viewModel.syncURLToQuery()
                }
                .onChange(of: viewModel.method) {
                    viewModel.syncUnsupportedState()
                }

            sendButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var sendButton: some View {
        if case .loading = viewModel.responseState {
            ProgressView()
                .controlSize(.small)
                .frame(width: 60)
        } else {
            Button(String(localized: "Send")) {
                Task { await viewModel.send() }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(viewModel.url.isEmpty || viewModel.isUnsupportedForReplay)
        }
    }

    private func consumePendingTransaction() {
        guard let transaction = ComposeStore.shared.pendingTransaction else {
            return
        }
        viewModel.prefill(from: transaction)
        ComposeStore.shared.pendingTransaction = nil
    }
}
