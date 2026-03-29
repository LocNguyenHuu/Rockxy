import Foundation
@testable import Rockxy
import Testing

// Regression tests for `BreakpointViewModel` in the view models layer.

@MainActor
struct BreakpointViewModelTests {
    // MARK: - Enum Existence

    @Test("BreakpointPhase.request exists")
    func breakpointPhaseRequestExists() {
        let phase = BreakpointPhase.request
        if case .request = phase {
            // pass
        } else {
            Issue.record("Expected .request")
        }
    }

    @Test("BreakpointPhase.response exists")
    func breakpointPhaseResponseExists() {
        let phase = BreakpointPhase.response
        if case .response = phase {
            // pass
        } else {
            Issue.record("Expected .response")
        }
    }

    @Test("Default phase is .request when not explicitly set")
    func defaultPhaseIsRequest() {
        let data = BreakpointRequestData(
            method: "GET", url: "", headers: [], body: "", statusCode: 200
        )
        if case .request = data.phase {
            // pass
        } else {
            Issue.record("Expected default phase to be .request")
        }
    }

    // MARK: - BreakpointDecision Existence

    @Test("BreakpointDecision cases exist")
    func breakpointDecisionCases() {
        let execute = BreakpointDecision.execute
        let abort = BreakpointDecision.abort
        let cancel = BreakpointDecision.cancel

        if case .execute = execute {} else {
            Issue.record("Expected .execute")
        }
        if case .abort = abort {} else {
            Issue.record("Expected .abort")
        }
        if case .cancel = cancel {} else {
            Issue.record("Expected .cancel")
        }
    }

    // MARK: - Mutability

    @Test("EditableHeader name and value are mutable")
    func editableHeaderIsMutable() {
        var header = EditableHeader(name: "Content-Type", value: "application/json")

        header.name = "Authorization"
        header.value = "Bearer token"

        #expect(header.name == "Authorization")
        #expect(header.value == "Bearer token")
    }

    @Test("BreakpointRequestData headers array is mutable")
    func breakpointRequestDataHeadersMutable() {
        var data = BreakpointRequestData(
            method: "GET",
            url: "https://test.com",
            headers: [
                EditableHeader(name: "Accept", value: "application/json")
            ],
            body: "",
            statusCode: 200
        )

        #expect(data.headers.count == 1)

        data.headers.append(EditableHeader(name: "Authorization", value: "Bearer xyz"))

        #expect(data.headers.count == 2)
    }

    @Test("BreakpointRequestData isHTTPS detects https scheme")
    func isHTTPSDetection() {
        let httpsData = BreakpointRequestData(
            method: "GET", url: "https://example.com", headers: [], body: "", statusCode: 200
        )
        #expect(httpsData.isHTTPS == true)

        let httpData = BreakpointRequestData(
            method: "GET", url: "http://example.com", headers: [], body: "", statusCode: 200
        )
        #expect(httpData.isHTTPS == false)
    }

    @Test("BreakpointRequestData body and method are mutable")
    func breakpointRequestDataFieldsMutable() {
        var data = BreakpointRequestData(
            method: "GET", url: "https://test.com", headers: [], body: "", statusCode: 200
        )

        data.method = "POST"
        data.body = "{\"key\": \"value\"}"
        data.url = "https://modified.com/api"
        data.statusCode = 201

        #expect(data.method == "POST")
        #expect(data.body == "{\"key\": \"value\"}")
        #expect(data.url == "https://modified.com/api")
        #expect(data.statusCode == 201)
    }
}
