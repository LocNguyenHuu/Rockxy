import SwiftUI
import UniformTypeIdentifiers

// Renders the ssl proxying list for the settings experience.

// MARK: - SSLProxyingListView

/// Sheet for managing the SSL proxying domain list.
/// Domains in this list will have their HTTPS traffic intercepted and decrypted;
/// all other HTTPS connections pass through as raw tunnels.
struct SSLProxyingListView: View {
    // MARK: Internal

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            tableSection
            Divider()
            inputSection
            Divider()
            footerSection
        }
        .frame(width: 520, height: 480)
        .onAppear {
            manager = SSLProxyingManager.shared
        }
    }

    // MARK: Private

    @State private var manager: SSLProxyingManager?
    @State private var newDomain: String = ""
    @State private var selectedRuleIDs: Set<UUID> = []
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportData: Data?

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "SSL Proxying List"))
                .font(.headline)
            Text(String(localized: "Only domains in this list will have HTTPS traffic decrypted for inspection."))
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tableSection: some View {
        Group {
            if let manager {
                if manager.rules.isEmpty {
                    ContentUnavailableView {
                        Label(
                            String(localized: "No Domains"),
                            systemImage: "lock.shield"
                        )
                    } description: {
                        Text(String(localized: "Add domains below or use presets to get started."))
                    }
                } else {
                    Table(manager.rules, selection: $selectedRuleIDs) {
                        TableColumn(String(localized: "Domain")) { rule in
                            Text(rule.domain)
                                .font(.body.monospaced())
                        }
                        .width(min: 200)
                        TableColumn(String(localized: "Enabled")) { rule in
                            Toggle(isOn: Binding(
                                get: { rule.isEnabled },
                                set: { _ in manager.toggleRule(id: rule.id) }
                            )) {
                                EmptyView()
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                        .width(60)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var inputSection: some View {
        HStack(spacing: 8) {
            TextField(
                String(localized: "Domain (e.g. *.example.com)"),
                text: $newDomain
            )
            .textFieldStyle(.roundedBorder)
            .onSubmit { addDomain() }

            Button(String(localized: "Add")) {
                addDomain()
            }
            .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()

            Button(role: .destructive) {
                manager?.removeRules(ids: selectedRuleIDs)
                selectedRuleIDs.removeAll()
            } label: {
                Label(String(localized: "Remove"), systemImage: "minus")
            }
            .disabled(selectedRuleIDs.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var footerSection: some View {
        HStack(spacing: 8) {
            Menu(String(localized: "Presets")) {
                Button(String(localized: "Add Common API Domains")) {
                    manager?.addPresets()
                }
            }

            Button(String(localized: "Import…")) {
                showingImporter = true
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }

            Button(String(localized: "Export…")) {
                exportData = manager?.exportRules()
                showingExporter = true
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: JSONFileDocument(data: exportData ?? Data()),
                contentType: .json,
                defaultFilename: "ssl-proxying-rules.json"
            ) { _ in }

            Spacer()

            Button(String(localized: "Done")) {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    private func addDomain() {
        let trimmed = newDomain.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return
        }
        manager?.addRule(SSLProxyingRule(domain: trimmed))
        newDomain = ""
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else {
            return
        }
        guard url.startAccessingSecurityScopedResource() else {
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url) else {
            return
        }
        try? manager?.importRules(from: data)
    }
}

// MARK: - JSONFileDocument

/// Minimal FileDocument for JSON export via fileExporter.
private struct JSONFileDocument: FileDocument {
    // MARK: Lifecycle

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    // MARK: Internal

    static var readableContentTypes: [UTType] {
        [.json]
    }

    let data: Data

    func fileWrapper(configuration _: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
