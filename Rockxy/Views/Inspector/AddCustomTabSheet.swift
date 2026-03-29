import SwiftUI

// Renders the add custom tab sheet interface for the request and response inspector.

struct AddCustomTabSheet: View {
    // MARK: Internal

    let store: PreviewTabStore
    let defaultPanel: PreviewPanel
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Create New Custom Tab"))
                .font(.system(size: 13, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                Picker(String(localized: "Tab Location:"), selection: $panel) {
                    Text(String(localized: "Request Panel")).tag(PreviewPanel.request)
                    Text(String(localized: "Response Panel")).tag(PreviewPanel.response)
                }
                .pickerStyle(.radioGroup)
                .font(.system(size: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Custom Tab Name:"))
                        .font(.system(size: 12))
                    TextField(String(localized: "Tab name"), text: $tabName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    Text(String(localized: "Use short name (< 10 chars) to look best"))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))

            HStack {
                Button(String(localized: "Cancel"), role: .cancel) {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button(String(localized: "Add")) {
                    let trimmed = tabName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else {
                        return
                    }
                    store.addCustomTab(name: trimmed, panel: panel)
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(tabName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 320)
        .onAppear {
            panel = defaultPanel
        }
    }

    // MARK: Private

    @State private var tabName = ""
    @State private var panel: PreviewPanel = .request
}
