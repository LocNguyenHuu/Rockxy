import Foundation
import NIOCore
import NIOHTTP1
import NIOSSL
import NIOWebSocket

/// Factory methods for assembling NIO channel pipelines used throughout the proxy.
/// Centralizes pipeline construction so that handler ordering (TLS -> HTTP codecs ->
/// application handler) stays consistent across plain HTTP, HTTPS intercept, and
/// WebSocket upgrade paths.
nonisolated enum ProxyPipeline {
    // MARK: - HTTP

    nonisolated static func configureHTTPPipeline(
        channel: Channel,
        handler: some ChannelHandler & Sendable
    )
        -> EventLoopFuture<Void>
    {
        channel.pipeline.configureHTTPServerPipeline().flatMap {
            channel.pipeline.addHandler(handler)
        }
    }

    // MARK: - TLS

    /// Installs NIOSSLServerHandler first so that all subsequent HTTP codec
    /// operations happen on the decrypted byte stream.
    nonisolated static func configureTLSPipeline(
        channel: Channel,
        sslContext: NIOSSLContext,
        handler: some ChannelHandler & Sendable
    )
        -> EventLoopFuture<Void>
    {
        let sslHandler = NIOSSLServerHandler(context: sslContext)
        return channel.pipeline.addHandler(sslHandler).flatMap {
            channel.pipeline.configureHTTPServerPipeline()
        }.flatMap {
            channel.pipeline.addHandler(handler)
        }
    }

    // MARK: - Pipeline Teardown

    /// Removes all handlers added by `configureHTTPServerPipeline()`.
    /// Must be called before transitioning a channel from HTTP mode to raw
    /// byte mode (e.g., for CONNECT tunnels and TLS interception).
    nonisolated static func removeHTTPServerPipeline(
        from pipeline: ChannelPipeline,
        on eventLoop: EventLoop
    )
        -> EventLoopFuture<Void>
    {
        func removeIfPresent(_ type: (some RemovableChannelHandler).Type) -> EventLoopFuture<Void> {
            pipeline.context(handlerType: type).flatMap {
                pipeline.removeHandler(context: $0)
            }.flatMapError { _ in
                eventLoop.makeSucceededVoidFuture()
            }
        }

        return removeIfPresent(HTTPServerProtocolErrorHandler.self)
            .flatMap { removeIfPresent(NIOHTTPResponseHeadersValidator.self) }
            .flatMap { removeIfPresent(HTTPServerPipelineHandler.self) }
            .flatMap { removeIfPresent(ByteToMessageHandler<HTTPRequestDecoder>.self) }
            .flatMap { removeIfPresent(HTTPResponseEncoder.self) }
    }

    // MARK: - WebSocket

    /// Replaces HTTP codecs with WebSocket frame decoder/encoder for upgraded connections.
    nonisolated static func configureWebSocketPipeline(
        channel: Channel,
        handler: some ChannelHandler & Sendable
    )
        -> EventLoopFuture<Void>
    {
        let decoder = ByteToMessageHandler(WebSocketFrameDecoder())
        let encoder = WebSocketFrameEncoder()
        return channel.pipeline.addHandler(decoder).flatMap {
            channel.pipeline.addHandler(encoder)
        }.flatMap {
            channel.pipeline.addHandler(handler)
        }
    }
}
