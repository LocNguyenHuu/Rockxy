import SwiftUI

// Bottom toolbar for the sidebar, providing a filter text field and an add-favorite button.
// Mirrors the compact bottom-bar pattern used in Finder and Proxyman sidebars.

// MARK: - SidebarBottomBar

struct SidebarBottomBar: View {
    @Binding var filterText: String
    @Binding var isAddFavoritePresented: Bool

    var body: some View {
        HStack(spacing: 6) {
            Button {
                isAddFavoritePresented = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13))
            }
            .buttonStyle(.borderless)
            .help(String(localized: "Add favorite app or domain"))

            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField(
                    String(localized: "Filter (\u{2318}\u{21E7}F)"),
                    text: $filterText
                )
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                if !filterText.isEmpty {
                    Button {
                        filterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(nsColor: .quaternaryLabelColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) { Divider() }
    }
}
