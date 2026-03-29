import Foundation
@testable import Rockxy
import Testing

// Regression tests for `PluginManifest` in the core plugins layer.

struct PluginManifestTests {
    @Test("Parse valid full plugin.json with all fields")
    func parseFullManifest() throws {
        let json = """
        {
            "id": "com.example.test-plugin",
            "name": "Test Plugin",
            "version": "1.2.0",
            "author": { "name": "Jane Doe", "url": "https://example.com" },
            "description": "A test plugin for validation",
            "types": ["script", "inspector"],
            "entryPoints": { "script": "main.js", "inspector": "inspect.js" },
            "capabilities": ["modifyRequest", "modifyResponse"],
            "configuration": {
                "apiKey": {
                    "type": "string",
                    "title": "API Key",
                    "secret": true,
                    "defaultValue": "sk-test"
                },
                "enabled": {
                    "type": "boolean",
                    "title": "Enabled",
                    "defaultValue": true
                },
                "maxRetries": {
                    "type": "number",
                    "title": "Max Retries",
                    "defaultValue": 3
                },
                "timeout": {
                    "type": "number",
                    "title": "Timeout Seconds",
                    "defaultValue": 1.5
                }
            },
            "minRockxyVersion": "1.0.0",
            "homepage": "https://example.com/plugin",
            "license": "MIT"
        }
        """

        let data = Data(json.utf8)
        let manifest = try JSONDecoder().decode(PluginManifest.self, from: data)

        #expect(manifest.id == "com.example.test-plugin")
        #expect(manifest.name == "Test Plugin")
        #expect(manifest.version == "1.2.0")
        #expect(manifest.author.name == "Jane Doe")
        #expect(manifest.author.url == "https://example.com")
        #expect(manifest.description == "A test plugin for validation")
        #expect(manifest.types == [.script, .inspector])
        #expect(manifest.entryPoints["script"] == "main.js")
        #expect(manifest.entryPoints["inspector"] == "inspect.js")
        #expect(manifest.capabilities == ["modifyRequest", "modifyResponse"])
        #expect(manifest.minRockxyVersion == "1.0.0")
        #expect(manifest.homepage == "https://example.com/plugin")
        #expect(manifest.license == "MIT")

        let config = try #require(manifest.configuration)
        #expect(config.count == 4)

        let apiKeyField = try #require(config["apiKey"])
        #expect(apiKeyField.type == "string")
        #expect(apiKeyField.title == "API Key")
        #expect(apiKeyField.secret == true)
    }

    @Test("Parse minimal manifest with only required fields")
    func parseMinimalManifest() throws {
        let json = """
        {
            "id": "com.example.minimal",
            "name": "Minimal",
            "version": "0.1.0",
            "author": { "name": "Test Author" },
            "description": "Bare minimum plugin",
            "types": ["exporter"],
            "entryPoints": { "export": "export.js" },
            "capabilities": []
        }
        """

        let data = Data(json.utf8)
        let manifest = try JSONDecoder().decode(PluginManifest.self, from: data)

        #expect(manifest.id == "com.example.minimal")
        #expect(manifest.name == "Minimal")
        #expect(manifest.author.url == nil)
        #expect(manifest.configuration == nil)
        #expect(manifest.minRockxyVersion == nil)
        #expect(manifest.homepage == nil)
        #expect(manifest.license == nil)
    }

    @Test("PluginType enum cases decode correctly")
    func pluginTypeDecoding() throws {
        let cases: [(String, PluginType)] = [
            ("\"script\"", .script),
            ("\"inspector\"", .inspector),
            ("\"exporter\"", .exporter),
            ("\"detector\"", .detector),
        ]

        for (jsonString, expected) in cases {
            let data = Data(jsonString.utf8)
            let decoded = try JSONDecoder().decode(PluginType.self, from: data)
            #expect(decoded == expected)
        }
    }

    @Test("AnyCodableValue decodes string, bool, int, double correctly")
    func anyCodableValueDecoding() throws {
        let stringData = Data("\"hello\"".utf8)
        let stringVal = try JSONDecoder().decode(AnyCodableValue.self, from: stringData)
        if case let .string(s) = stringVal {
            #expect(s == "hello")
        } else {
            #expect(Bool(false), "Expected .string case")
        }

        let boolData = Data("true".utf8)
        let boolVal = try JSONDecoder().decode(AnyCodableValue.self, from: boolData)
        if case let .bool(b) = boolVal {
            #expect(b == true)
        } else {
            #expect(Bool(false), "Expected .bool case")
        }

        let intData = Data("42".utf8)
        let intVal = try JSONDecoder().decode(AnyCodableValue.self, from: intData)
        if case let .int(i) = intVal {
            #expect(i == 42)
        } else {
            #expect(Bool(false), "Expected .int case")
        }

        let doubleData = Data("3.14".utf8)
        let doubleVal = try JSONDecoder().decode(AnyCodableValue.self, from: doubleData)
        if case let .double(d) = doubleVal {
            #expect(abs(d - 3.14) < 0.001)
        } else {
            #expect(Bool(false), "Expected .double case")
        }
    }

    @Test("PluginConfigField decodes with secret flag and defaultValue")
    func configFieldDecoding() throws {
        let json = """
        {
            "type": "string",
            "title": "Secret Token",
            "secret": true,
            "defaultValue": "abc123"
        }
        """

        let data = Data(json.utf8)
        let field = try JSONDecoder().decode(PluginConfigField.self, from: data)

        #expect(field.type == "string")
        #expect(field.title == "Secret Token")
        #expect(field.secret == true)

        if case let .string(defaultStr) = field.defaultValue {
            #expect(defaultStr == "abc123")
        } else {
            #expect(Bool(false), "Expected .string defaultValue")
        }
    }
}
