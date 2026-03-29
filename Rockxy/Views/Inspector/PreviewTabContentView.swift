import SwiftUI
import WebKit

// Renders the preview tab content interface for the request and response inspector.

struct PreviewTabContentView: View {
    let tab: PreviewTab
    let transaction: HTTPTransaction
    var beautify: Bool = false

    var body: some View {
        let bodyData = tab.panel == .request ? transaction.request.body : transaction.response?.body
        let result = PreviewRenderer.render(body: bodyData, mode: tab.renderMode, beautify: beautify)

        switch result {
        case let .text(text):
            if tab.renderMode == .htmlPreview {
                HTMLPreviewView(html: text, baseURL: transaction.request.url)
            } else {
                ScrollView {
                    Text(text)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
        case let .hex(text):
            HexDumpView(hexText: text)
        case .json:
            if let data = tab.panel == .request ? transaction.request.body : transaction.response?.body {
                JSONTreeView(data: data)
            } else {
                ContentUnavailableView {
                    Label(String(localized: "No Preview"), systemImage: "doc.text")
                } description: {
                    Text(String(localized: "No body data"))
                }
            }
        case let .imageData(data, _, _):
            ImagePreviewView(data: data)
        case let .empty(reason):
            ContentUnavailableView {
                Label(String(localized: "No Preview"), systemImage: "doc.text")
            } description: {
                Text(reason)
            }
        }
    }
}
