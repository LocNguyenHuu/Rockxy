import Foundation
import JavaScriptCore

// Implements script response context behavior for the plugin and scripting subsystem.

// MARK: - ScriptResponseContext

struct ScriptResponseContext {
    // MARK: Lifecycle

    init(request: HTTPRequestData, response: HTTPResponseData) {
        self.method = request.method
        self.url = request.url.absoluteString
        self.requestHeaders = Dictionary(
            request.headers.map { ($0.name, $0.value) },
            uniquingKeysWith: { _, last in last }
        )
        self.statusCode = response.statusCode
        self.responseHeaders = Dictionary(
            response.headers.map { ($0.name, $0.value) },
            uniquingKeysWith: { _, last in last }
        )
        self.body = response.body?.base64EncodedString()
    }

    // MARK: Internal

    let method: String
    let url: String
    let requestHeaders: [String: String]
    let statusCode: Int
    let responseHeaders: [String: String]
    let body: String?

    func toJSValue(in context: JSContext) -> JSValue {
        let obj = JSValue(newObjectIn: context)

        obj?.setObject(method, forKeyedSubscript: "method" as NSString)
        obj?.setObject(url, forKeyedSubscript: "url" as NSString)
        obj?.setObject(requestHeaders, forKeyedSubscript: "requestHeaders" as NSString)
        obj?.setObject(statusCode, forKeyedSubscript: "statusCode" as NSString)
        obj?.setObject(responseHeaders, forKeyedSubscript: "responseHeaders" as NSString)
        obj?.setObject(body as Any, forKeyedSubscript: "body" as NSString)

        return obj ?? JSValue(undefinedIn: context)
    }
}
