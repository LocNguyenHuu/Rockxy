import SwiftUI

// Renders the status interface for shared app surfaces.

// MARK: - StatusBadge

/// Color-coded pill badge for HTTP methods (GET blue, POST green, PUT orange, DELETE red, etc.).
/// Fixed-width at 44pt so badges align in the request list column.
struct StatusBadge: View {
    // MARK: Internal

    let method: String

    var body: some View {
        Text(method)
            .font(.system(.caption2, design: .monospaced))
            .fontWeight(.bold)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(methodColor.opacity(0.15))
            .foregroundStyle(methodColor)
            .cornerRadius(3)
            .frame(width: 44)
    }

    // MARK: Private

    private var methodColor: Color {
        switch method.uppercased() {
        case "GET": .blue
        case "POST": .green
        case "PUT": .orange
        case "PATCH": .yellow
        case "DELETE": .red
        case "HEAD": .purple
        case "OPTIONS": .gray
        default: .secondary
        }
    }
}

// MARK: - StatusCodeBadge

/// Color-coded badge for HTTP status codes: 2xx green, 3xx blue, 4xx orange, 5xx red.
struct StatusCodeBadge: View {
    // MARK: Internal

    let statusCode: Int

    var body: some View {
        Text("\(statusCode)")
            .font(.system(.caption, design: .monospaced))
            .fontWeight(.medium)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
            .cornerRadius(3)
    }

    // MARK: Private

    private var statusColor: Color {
        switch statusCode {
        case 200 ..< 300: .green
        case 300 ..< 400: .blue
        case 400 ..< 500: .orange
        case 500 ..< 600: .red
        default: .secondary
        }
    }
}
