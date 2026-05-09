import SwiftUI
import WebKit

// Renders the preview tab content interface for the request and response inspector.

struct PreviewTabContentView: View {
    let tab: PreviewTab
    let transaction: HTTPTransaction
    var beautify: Bool = false

    var body: some View {
        let result = previewResult

        switch result {
        case let .text(text):
            if tab.renderMode == .htmlPreview {
                HTMLPreviewView(html: text, baseURL: transaction.request.url)
            } else {
                InspectorBodyTextEditor(text: text, fontSize: 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        case let .imageData(data, _, _):
            ImagePreviewView(data: data)
        case let .empty(reason):
            ContentUnavailableView {
                Label(String(localized: "No Preview"), systemImage: "doc.text")
            } description: {
                Text(reason)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var previewResult: PreviewResult {
        if tab.renderMode == .raw {
            return rawPreviewResult
        }

        let bodyData = tab.panel == .request ? transaction.request.body : transaction.response?.body
        return PreviewRenderer.render(body: bodyData, mode: tab.renderMode, beautify: beautify)
    }

    private var rawPreviewResult: PreviewResult {
        switch tab.panel {
        case .request:
            return .text(RequestCopyFormatter.rawRequest(for: transaction))
        case .response:
            if let rawResponse = RequestCopyFormatter.rawResponse(for: transaction) {
                return .text(rawResponse)
            } else {
                return .empty(reason: String(localized: "No response data"))
            }
        }
    }
}
