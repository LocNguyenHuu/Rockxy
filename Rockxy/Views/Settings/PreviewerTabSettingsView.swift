import SwiftUI

// Renders the previewer tab interface for the settings experience.

struct PreviewerTabSettingsView: View {
    // MARK: Internal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Body Previewer Tabs"))
                .font(.system(size: 13, weight: .semibold))
            Text(String(localized: "Select tabs to render body content as a specific format"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                panelColumn(title: String(localized: "Request Panel"), panel: .request)
                panelColumn(title: String(localized: "Response Panel"), panel: .response)
            }

            Divider()

            Toggle(isOn: $store.autoBeautify) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(localized: "Auto beautify minified content"))
                        .font(.system(size: 12))
                    Text(String(localized: "Only applies to HTML, CSS, and JavaScript"))
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .toggleStyle(.checkbox)
        }
        .padding(12)
        .frame(width: 480)
    }

    // MARK: Private

    @State private var store = PreviewTabStore()

    private func panelColumn(title: String, panel: PreviewPanel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                ForEach(PreviewRenderMode.allCases) { mode in
                    Toggle(mode.displayName, isOn: Binding(
                        get: { store.isEnabled(renderMode: mode, panel: panel) },
                        set: { enabled in
                            if enabled {
                                store.enableTab(renderMode: mode, panel: panel)
                            } else {
                                store.disableTab(renderMode: mode, panel: panel)
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
        }
        .frame(maxWidth: .infinity)
    }
}
