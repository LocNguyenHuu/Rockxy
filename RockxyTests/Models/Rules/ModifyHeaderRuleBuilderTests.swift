import Foundation
@testable import Rockxy
import Testing

struct ModifyHeaderRuleBuilderTests {
    @Test("Wildcard matching rule is converted with Block List semantics")
    func wildcardPatternConversion() {
        let rule = ModifyHeaderRuleBuilder.build(
            ruleName: "",
            rawPattern: " https://example.com/api/* ",
            httpMethod: .post,
            matchType: .wildcard,
            includeSubpaths: true,
            operations: [
                HeaderOperation(type: .add, headerName: "X-Debug", headerValue: "1"),
            ]
        )

        #expect(rule.name == "https://example.com/api/*")
        #expect(rule.matchCondition.method == "POST")
        #expect(rule.matchCondition.urlPattern == #"https:\/\/example\.com\/api\/.*"#)
    }

    @Test("Exact wildcard matching appends URL boundary")
    func exactWildcardPatternConversion() {
        let rule = ModifyHeaderRuleBuilder.build(
            ruleName: "Exact",
            rawPattern: "https://example.com/api",
            httpMethod: .any,
            matchType: .wildcard,
            includeSubpaths: false,
            operations: [
                HeaderOperation(type: .remove, headerName: "Server", headerValue: nil),
            ]
        )

        #expect(rule.name == "Exact")
        #expect(rule.matchCondition.method == nil)
        #expect(rule.matchCondition.urlPattern == #"https:\/\/example\.com\/api($|[?#])"#)
    }

    @Test("Regex matching preserves source and edited rule identity")
    func regexPatternPreservesIdentity() {
        let existing = ProxyRule(
            name: "Old",
            isEnabled: false,
            matchCondition: RuleMatchCondition(urlPattern: "old"),
            action: .modifyHeader(operations: []),
            priority: 7
        )

        let rule = ModifyHeaderRuleBuilder.build(
            existingRule: existing,
            ruleName: " Updated ",
            rawPattern: ".*api\\.example\\.com.*",
            httpMethod: .get,
            matchType: .regex,
            includeSubpaths: true,
            operations: [
                HeaderOperation(type: .replace, headerName: "Cache-Control", headerValue: "no-cache"),
            ]
        )

        #expect(rule.id == existing.id)
        #expect(rule.name == "Updated")
        #expect(rule.isEnabled == false)
        #expect(rule.priority == 7)
        #expect(rule.matchCondition.method == "GET")
        #expect(rule.matchCondition.urlPattern == ".*api\\.example\\.com.*")
    }
}
