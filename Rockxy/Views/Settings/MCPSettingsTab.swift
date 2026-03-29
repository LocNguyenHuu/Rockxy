import SwiftUI

/// Model Context Protocol (MCP) settings tab. Shows a Labs Preview informational surface
/// since the MCP server backend is under active development and not yet functional.
struct MCPSettingsTab: View {
    var body: some View {
        Form {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flask")
                        .foregroundStyle(.orange)
                    Text(String(localized: "Labs Preview"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))

                Image(systemName: "cpu")
                    .font(.system(size: 36))
                    .foregroundStyle(.tertiary)

                Text(String(localized: "Model Context Protocol"))
                    .font(.system(size: 15, weight: .semibold))

                Text(
                    String(
                        localized: "Expose captured traffic to AI assistants via the Model Context Protocol. This feature is under active development and not yet functional."
                    )
                )
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

                Text(
                    String(
                        localized: "When available, you'll be able to configure server endpoint, privacy redaction, and access control from this tab."
                    )
                )
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
        .formStyle(.grouped)
    }
}
