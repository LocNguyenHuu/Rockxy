import AppKit
import SwiftUI

/// Dense two-column header table used by request and response inspectors.
/// Keeps the column names visible so header values read like a native key/value grid.
struct HeaderKeyValueTable: View {
    let headers: [HTTPHeader]

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            Divider()
            ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                row(header)
                if index < headers.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .textBackgroundColor))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text(String(localized: "Key"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 180, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
            Divider()
            Text(String(localized: "Value"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func row(_ header: HTTPHeader) -> some View {
        HStack(spacing: 0) {
            Text(header.name)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .textSelection(.enabled)
                .frame(width: 180, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            Divider()
            Text(header.value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
    }
}
