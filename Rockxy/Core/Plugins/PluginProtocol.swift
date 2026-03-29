import Foundation
import SwiftUI

// Plugin protocols define the three extension points in Rockxy's architecture:
// inspectors (custom body viewers), exporters (session output formats),
// and protocol handlers (detection + inspection for non-HTTP protocols like GraphQL/gRPC).

// MARK: - InspectorPlugin

/// Provides a custom SwiftUI view for inspecting transaction bodies of specific content types.
protocol InspectorPlugin {
    var name: String { get }
    var supportedContentTypes: [ContentType] { get }
    func inspectorView(for transaction: HTTPTransaction) -> AnyView
}

// MARK: - ExporterPlugin

/// Serializes captured transactions into a specific file format (e.g., HAR, cURL, Postman).
protocol ExporterPlugin {
    var name: String { get }
    var fileExtension: String { get }
    func export(transactions: [HTTPTransaction]) throws -> Data
}

// MARK: - ProtocolHandler

/// Detects and provides inspection UI for application-layer protocols
/// tunneled over HTTP (e.g., GraphQL, gRPC-Web, WebSocket subprotocols).
protocol ProtocolHandler {
    var protocolName: String { get }
    func canHandle(request: HTTPRequestData) -> Bool
    func inspectorView(for transaction: HTTPTransaction) -> AnyView
}
