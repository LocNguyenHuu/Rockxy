import SwiftUI
import UniformTypeIdentifiers

// Renders the allow list for the settings experience.

// MARK: - AllowListView

/// Window for managing the Allow List — a capture-level filter that restricts
/// which domains are recorded. Non-matching traffic is still forwarded but not captured.
struct AllowListView: View {
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
        .frame(width: 560, height: 520)
        .onAppear {
            manager = AllowListManager.shared
        }
    }

    // MARK: Private

    @State private var manager: AllowListManager?
    @State private var newDomain: String = ""
    @State private var selectedEntryIDs: Set<UUID> = []
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportData: Data?
    @State private var validationError: String?

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Allow List"))
                    .font(.headline)
                Text(
                    String(
                        localized: "When active, only traffic from matching domains is captured. Unmatched requests are forwarded but not recorded."
                    )
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if let manager {
                Toggle(isOn: Binding(
                    get: { manager.isActive },
                    set: { manager.isActive = $0 }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Allow List Active"))
                            .font(.body.weight(.medium))
                        Text(String(localized: "Only matching domains are captured"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))

                if manager.isActive {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text(String(localized: "Traffic from non-matching domains will be forwarded but not recorded"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tableSection: some View {
        Group {
            if let manager {
                if manager.entries.isEmpty {
                    ContentUnavailableView {
                        Label(
                            String(localized: "No Allow List Rules"),
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    } description: {
                        Text(
                            String(
                                localized: "Add domains to capture only specific traffic.\nWhen active, unmatched requests are forwarded but not recorded."
                            )
                        )
                    }
                } else {
                    Table(manager.entries, selection: $selectedEntryIDs) {
                        TableColumn(String(localized: "On")) { entry in
                            Toggle(isOn: Binding(
                                get: { entry.isEnabled },
                                set: { _ in manager.toggleEntry(id: entry.id) }
                            )) {
                                EmptyView()
                            }
                            .toggleStyle(.switch)
                            .controlSize(.small)
                        }
                        .width(40)
                        TableColumn(String(localized: "Domain")) { entry in
                            Text(entry.domain)
                                .font(.body.monospaced())
                                .foregroundStyle(entry.isEnabled ? .primary : .secondary)
                        }
                        .width(min: 200)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                TextField(
                    String(localized: "Add domain (e.g. *.example.com)"),
                    text: $newDomain
                )
                .textFieldStyle(.roundedBorder)
                .onSubmit { addEntry() }
                .onChange(of: newDomain) {
                    validationError = nil
                }

                Button(String(localized: "Add")) {
                    addEntry()
                }
                .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()

                Button(role: .destructive) {
                    manager?.removeEntries(ids: selectedEntryIDs)
                    selectedEntryIDs.removeAll()
                } label: {
                    Label(String(localized: "Remove"), systemImage: "minus")
                }
                .disabled(selectedEntryIDs.isEmpty)
            }

            if let validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var footerSection: some View {
        HStack(spacing: 8) {
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
                exportData = manager?.exportEntries()
                showingExporter = true
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: AllowListJSONFileDocument(data: exportData ?? Data()),
                contentType: .json,
                defaultFilename: "allow-list.json"
            ) { _ in }

            Spacer()

            if let manager {
                let activeCount = manager.entries.filter(\.isEnabled).count
                if activeCount > 0 {
                    Text(String(localized: "\(activeCount) domain(s) active"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button(String(localized: "Done")) {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding()
    }

    private func addEntry() {
        let trimmed = newDomain.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return
        }

        if let manager, manager.entries.contains(where: { $0.domain.lowercased() == trimmed.lowercased() }) {
            validationError = String(localized: "This domain is already in the allow list.")
            return
        }

        manager?.addEntry(trimmed)
        newDomain = ""
        validationError = nil
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
        try? manager?.importEntries(from: data)
    }
}

// MARK: - AllowListJSONFileDocument

/// Minimal FileDocument for JSON export via fileExporter.
private struct AllowListJSONFileDocument: FileDocument {
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
