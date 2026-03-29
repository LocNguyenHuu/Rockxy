import SwiftUI

// Renders the hex dump interface for the request and response inspector.

struct HexDumpView: View {
    let hexText: String

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(hexText)
                .font(.system(size: 11, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
    }
}
