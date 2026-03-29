import Foundation
import JavaScriptCore

// Implements script request context behavior for the plugin and scripting subsystem.

// MARK: - ScriptRequestContext

struct ScriptRequestContext {
    // MARK: Lifecycle

    init(from request: HTTPRequestData) {
        self.method = request.method
        self.url = request.url.absoluteString
        self.headers = Dictionary(
            request.headers.map { ($0.name, $0.value) },
            uniquingKeysWith: { _, last in last }
        )
        self.body = request.body?.base64EncodedString()
    }

    private init(method: String, url: String, headers: [String: String], body: String?) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }

    // MARK: Internal

    var method: String
    var url: String
    var headers: [String: String]
    var body: String?

    static func from(jsValue: JSValue, original: ScriptRequestContext) -> ScriptRequestContext {
        let request = jsValue.objectForKeyedSubscript("request")

        let method = request?.objectForKeyedSubscript("method")?.toString() ?? original.method
        let url = request?.objectForKeyedSubscript("url")?.toString() ?? original.url

        var headers = original.headers
        if let headersObj = request?.objectForKeyedSubscript("headers"),
           let headersDict = headersObj.toDictionary() as? [String: String]
        {
            headers = headersDict
        }

        let body: String? = if let bodyVal = request?.objectForKeyedSubscript("body"), !bodyVal.isUndefined,
                               !bodyVal.isNull
        {
            bodyVal.toString()
        } else {
            original.body
        }

        return ScriptRequestContext(method: method, url: url, headers: headers, body: body)
    }

    func toJSValue(in context: JSContext) -> JSValue {
        let wrapper = JSValue(newObjectIn: context)
        let request = JSValue(newObjectIn: context)

        request?.setObject(method, forKeyedSubscript: "method" as NSString)
        request?.setObject(url, forKeyedSubscript: "url" as NSString)
        request?.setObject(headers, forKeyedSubscript: "headers" as NSString)
        request?.setObject(body as Any, forKeyedSubscript: "body" as NSString)

        wrapper?.setObject(request, forKeyedSubscript: "request" as NSString)

        let setHeaderFn: @convention(block) (String, String) -> Void = { name, value in
            let headersObj = request?.objectForKeyedSubscript("headers")
            headersObj?.setObject(value, forKeyedSubscript: name as NSString)
        }
        let setBodyFn: @convention(block) (String) -> Void = { newBody in
            request?.setObject(newBody, forKeyedSubscript: "body" as NSString)
        }
        let setURLFn: @convention(block) (String) -> Void = { newURL in
            request?.setObject(newURL, forKeyedSubscript: "url" as NSString)
        }

        wrapper?.setObject(setHeaderFn, forKeyedSubscript: "setHeader" as NSString)
        wrapper?.setObject(setBodyFn, forKeyedSubscript: "setBody" as NSString)
        wrapper?.setObject(setURLFn, forKeyedSubscript: "setURL" as NSString)

        return wrapper ?? JSValue(undefinedIn: context)
    }

    func apply(to request: inout HTTPRequestData) {
        let newBody: Data? = if let body {
            Data(base64Encoded: body)
        } else {
            request.body
        }
        let newHeaders = headers.map { HTTPHeader(name: $0.key, value: $0.value) }
        let resolvedURL = URL(string: url) ?? request.url

        request = HTTPRequestData(
            method: method,
            url: resolvedURL,
            httpVersion: request.httpVersion,
            headers: newHeaders,
            body: newBody,
            contentType: request.contentType
        )
    }
}
