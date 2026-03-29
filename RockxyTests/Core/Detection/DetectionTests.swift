import Foundation
@testable import Rockxy
import Testing

// Tests for content detection: `GraphQLDetector` (operation type parsing, operationName/variables
// extraction, negative cases) and `ContentTypeDetector` (JSON, XML, HTML, image, form, unknown).

// MARK: - DetectionTests

struct DetectionTests {
    // MARK: - GraphQLDetector Tests

    @Test("GraphQLDetector detects query operation")
    func detectGraphQLQuery() throws {
        let body = try JSONSerialization.data(
            withJSONObject: ["query": "{ users { id } }"]
        )
        let request = try HTTPRequestData(
            method: "POST",
            url: #require(URL(string: "https://api.example.com/graphql")),
            httpVersion: "HTTP/1.1",
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: body
        )

        let info = try #require(GraphQLDetector.detect(request: request))

        #expect(info.operationType == .query)
        #expect(info.query == "{ users { id } }")
    }

    @Test("GraphQLDetector detects mutation operation")
    func detectGraphQLMutation() throws {
        let body = try JSONSerialization.data(
            withJSONObject: ["query": "mutation { createUser(name: \"test\") { id } }"]
        )
        let request = try HTTPRequestData(
            method: "POST",
            url: #require(URL(string: "https://api.example.com/graphql")),
            httpVersion: "HTTP/1.1",
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: body
        )

        let info = try #require(GraphQLDetector.detect(request: request))

        #expect(info.operationType == .mutation)
    }

    @Test("GraphQLDetector returns nil for non-POST requests")
    func detectGraphQLNonPost() throws {
        let request = try HTTPRequestData(
            method: "GET",
            url: #require(URL(string: "https://api.example.com/graphql")),
            httpVersion: "HTTP/1.1",
            headers: []
        )

        let info = GraphQLDetector.detect(request: request)

        #expect(info == nil)
    }

    @Test("GraphQLDetector returns nil for non-graphql path")
    func detectGraphQLWrongPath() throws {
        let body = try JSONSerialization.data(
            withJSONObject: ["query": "{ users { id } }"]
        )
        let request = try HTTPRequestData(
            method: "POST",
            url: #require(URL(string: "https://api.example.com/api/v1/data")),
            httpVersion: "HTTP/1.1",
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: body
        )

        let info = GraphQLDetector.detect(request: request)

        #expect(info == nil)
    }

    @Test("GraphQLDetector returns nil for missing query in body")
    func detectGraphQLMissingQuery() throws {
        let body = try JSONSerialization.data(
            withJSONObject: ["variables": ["id": 1]]
        )
        let request = try HTTPRequestData(
            method: "POST",
            url: #require(URL(string: "https://api.example.com/graphql")),
            httpVersion: "HTTP/1.1",
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: body
        )

        let info = GraphQLDetector.detect(request: request)

        #expect(info == nil)
    }

    @Test("GraphQLDetector extracts operationName and variables")
    func detectGraphQLOperationNameAndVariables() throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "query": "query GetUser($id: ID!) { user(id: $id) { name } }",
            "operationName": "GetUser",
            "variables": ["id": "123"]
        ])
        let request = try HTTPRequestData(
            method: "POST",
            url: #require(URL(string: "https://api.example.com/graphql")),
            httpVersion: "HTTP/1.1",
            headers: [HTTPHeader(name: "Content-Type", value: "application/json")],
            body: body
        )

        let info = try #require(GraphQLDetector.detect(request: request))

        #expect(info.operationName == "GetUser")
        #expect(info.variables != nil)
        #expect(try #require(info.variables?.contains("123")))
    }

    // MARK: - ContentTypeDetector Tests

    @Test("ContentTypeDetector detects JSON")
    func detectJSON() {
        let headers = [HTTPHeader(name: "Content-Type", value: "application/json")]
        let result = ContentTypeDetector.detect(headers: headers, body: nil)
        #expect(result == .json)
    }

    @Test("ContentTypeDetector detects XML")
    func detectXML() {
        let headers = [HTTPHeader(name: "Content-Type", value: "application/xml")]
        let result = ContentTypeDetector.detect(headers: headers, body: nil)
        #expect(result == .xml)
    }

    @Test("ContentTypeDetector detects HTML")
    func detectHTML() {
        let headers = [HTTPHeader(name: "Content-Type", value: "text/html; charset=utf-8")]
        let result = ContentTypeDetector.detect(headers: headers, body: nil)
        #expect(result == .html)
    }

    @Test("ContentTypeDetector detects image")
    func detectImage() {
        let headers = [HTTPHeader(name: "Content-Type", value: "image/png")]
        let result = ContentTypeDetector.detect(headers: headers, body: nil)
        #expect(result == .image)
    }

    @Test("ContentTypeDetector detects form data")
    func detectForm() {
        let headers = [
            HTTPHeader(name: "Content-Type", value: "application/x-www-form-urlencoded")
        ]
        let result = ContentTypeDetector.detect(headers: headers, body: nil)
        #expect(result == .form)
    }

    @Test("ContentTypeDetector returns unknown for unrecognized type")
    func detectUnknown() {
        let headers = [HTTPHeader(name: "Content-Type", value: "application/octet-stream")]
        let result = ContentTypeDetector.detect(headers: headers, body: nil)
        #expect(result == .unknown)
    }
}
