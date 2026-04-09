import Foundation
@testable import Rockxy
import Testing

// Comprehensive tests for Block List feature models: HTTPMethodFilter,
// BlockMatchType, BlockActionType, and BlockListViewModel rule creation.

// MARK: - HTTPMethodFilterTests

struct HTTPMethodFilterTests {
    @Test("All cases are defined")
    func allCases() {
        #expect(HTTPMethodFilter.allCases.count == 9)
    }

    @Test("ANY method returns nil for rule matching")
    func anyMethodValue() {
        #expect(HTTPMethodFilter.any.methodValue == nil)
    }

    @Test("Non-ANY methods return their raw value")
    func nonAnyMethodValues() {
        #expect(HTTPMethodFilter.get.methodValue == "GET")
        #expect(HTTPMethodFilter.post.methodValue == "POST")
        #expect(HTTPMethodFilter.put.methodValue == "PUT")
        #expect(HTTPMethodFilter.delete.methodValue == "DELETE")
        #expect(HTTPMethodFilter.patch.methodValue == "PATCH")
        #expect(HTTPMethodFilter.head.methodValue == "HEAD")
        #expect(HTTPMethodFilter.options.methodValue == "OPTIONS")
        #expect(HTTPMethodFilter.trace.methodValue == "TRACE")
    }

    @Test("Raw values match HTTP method strings")
    func rawValues() {
        for method in HTTPMethodFilter.allCases {
            #expect(method.rawValue == method.rawValue.uppercased() || method == .any)
        }
    }
}

// MARK: - BlockMatchTypeTests

struct BlockMatchTypeTests {
    @Test("All cases are defined")
    func allCases() {
        #expect(BlockMatchType.allCases.count == 3)
    }

    @Test("Wildcard shows subpaths toggle")
    func wildcardShowsSubpaths() {
        #expect(BlockMatchType.wildcard.showsSubpathsToggle == true)
        #expect(BlockMatchType.wildcard.showsGraphQLField == false)
    }

    @Test("Regex shows subpaths toggle")
    func regexShowsSubpaths() {
        #expect(BlockMatchType.regex.showsSubpathsToggle == true)
        #expect(BlockMatchType.regex.showsGraphQLField == false)
    }

    @Test("GraphQL QueryName shows GraphQL field")
    func graphQLShowsField() {
        #expect(BlockMatchType.graphQLQueryName.showsSubpathsToggle == false)
        #expect(BlockMatchType.graphQLQueryName.showsGraphQLField == true)
    }

    @Test("Display names match design spec")
    func displayNames() {
        #expect(BlockMatchType.wildcard.rawValue == "Use Wildcard")
        #expect(BlockMatchType.regex.rawValue == "Use Regex")
        #expect(BlockMatchType.graphQLQueryName.rawValue == "GraphQL QueryName")
    }

    @Test("Subpath and GraphQL toggles are mutually exclusive across all cases")
    func mutuallyExclusiveFlags() {
        for matchType in BlockMatchType.allCases {
            let subpath = matchType.showsSubpathsToggle
            let graphql = matchType.showsGraphQLField
            #expect(!(subpath && graphql), "Both flags should never be true simultaneously for \(matchType)")
        }
    }
}

// MARK: - BlockActionTypeTests

struct BlockActionTypeTests {
    @Test("All cases are defined")
    func allCases() {
        #expect(BlockActionType.allCases.count == 3)
    }

    @Test("blockAndHide returns 403 and hides")
    func blockAndHideProperties() {
        let action = BlockActionType.blockAndHide
        #expect(action.statusCode == 403)
        #expect(action.hidesFromList == true)
    }

    @Test("blockAndDisplay returns 403 and shows")
    func blockAndDisplayProperties() {
        let action = BlockActionType.blockAndDisplay
        #expect(action.statusCode == 403)
        #expect(action.hidesFromList == false)
    }

    @Test("hideOnly returns 0 status and hides")
    func hideOnlyProperties() {
        let action = BlockActionType.hideOnly
        #expect(action.statusCode == 0)
        #expect(action.hidesFromList == true)
    }

    @Test("Display names match design spec")
    func displayNames() {
        #expect(BlockActionType.blockAndHide.rawValue == "Block & Hide Request")
        #expect(BlockActionType.blockAndDisplay.rawValue == "Block & Display Requests")
        #expect(BlockActionType.hideOnly.rawValue == "Hide, but not Block")
    }

    @Test("Only blockAndDisplay does not hide from list")
    func onlyBlockAndDisplayIsVisible() {
        let visibleActions = BlockActionType.allCases.filter { !$0.hidesFromList }
        #expect(visibleActions.count == 1)
        #expect(visibleActions.first == .blockAndDisplay)
    }

    @Test("All blocking actions have non-negative status codes")
    func statusCodesAreNonNegative() {
        for action in BlockActionType.allCases {
            #expect(action.statusCode >= 0)
        }
    }
}

// MARK: - BlockListViewModelTests

struct BlockListViewModelTests {
    @Test("addBlockRule with wildcard creates correct pattern")
    @MainActor
    func addWildcardRule() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Block ChatGPT",
            urlPattern: "*chatgpt.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.count == 1)
        let rule = vm.blockRules.first
        #expect(rule?.name == "Block ChatGPT")
        #expect(rule?.matchCondition.method == nil)
        #expect(rule?.matchCondition.urlPattern?.contains(".*") == true)
    }

    @Test("addBlockRule with regex passes pattern through unchanged")
    @MainActor
    func addRegexRule() {
        let vm = BlockListViewModel()
        let rawRegex = "^https://tracker\\.analytics\\.io/.*$"

        vm.addBlockRule(
            ruleName: "Block Tracker",
            urlPattern: rawRegex,
            httpMethod: .get,
            matchType: .regex,
            blockAction: .blockAndDisplay,
            includeSubpaths: false,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.count == 1)
        let rule = vm.blockRules.first
        #expect(rule?.name == "Block Tracker")
        #expect(rule?.matchCondition.urlPattern == rawRegex)
        #expect(rule?.matchCondition.method == "GET")
    }

    @Test("addBlockRule with GraphQL QueryName match type")
    @MainActor
    func addGraphQLRule() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Block createUser",
            urlPattern: "https://api.example.com/graphql",
            httpMethod: .post,
            matchType: .graphQLQueryName,
            blockAction: .blockAndHide,
            includeSubpaths: false,
            graphQLQueryName: "createUser",
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.count == 1)
        let rule = vm.blockRules.first
        #expect(rule?.name == "Block createUser")
        #expect(rule?.matchCondition.method == "POST")
    }

    @Test("addBlockRule with empty name uses URL pattern as name")
    @MainActor
    func emptyNameUsesPattern() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "",
            urlPattern: "*.ads.example.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.first?.name == "*.ads.example.com/*")
    }

    @Test("addBlockRule with specific HTTP method sets method on condition")
    @MainActor
    func specificMethodSetsCondition() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Block POST",
            urlPattern: "*.example.com/*",
            httpMethod: .post,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.first?.matchCondition.method == "POST")
    }

    @Test("addBlockRule with ANY method leaves method nil")
    @MainActor
    func anyMethodLeavesNil() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Block All",
            urlPattern: "*.example.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.first?.matchCondition.method == nil)
    }

    @Test("addBlockRule with hideOnly action uses status code 0")
    @MainActor
    func hideOnlyUsesZeroStatusCode() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Hide Only",
            urlPattern: "*.example.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .hideOnly,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        if case let .block(statusCode) = vm.blockRules.first?.action {
            #expect(statusCode == 0)
        } else {
            Issue.record("Expected .block action")
        }
    }

    @Test("addBlockRule with blockAndHide uses status code 403")
    @MainActor
    func blockAndHideUses403() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Block",
            urlPattern: "*.example.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        if case let .block(statusCode) = vm.blockRules.first?.action {
            #expect(statusCode == 403)
        } else {
            Issue.record("Expected .block action")
        }
    }

    @Test("addBlockRule with blockAndDisplay uses status code 403")
    @MainActor
    func blockAndDisplayUses403() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Block visible",
            urlPattern: "*.example.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndDisplay,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        if case let .block(statusCode) = vm.blockRules.first?.action {
            #expect(statusCode == 403)
        } else {
            Issue.record("Expected .block action")
        }
    }

    @Test("Wildcard includeSubpaths appends .* suffix to pattern")
    @MainActor
    func includeSubpathsAppendsSuffix() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "With subpaths",
            urlPattern: "https://example.com",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        let pattern = vm.blockRules.first?.matchCondition.urlPattern ?? ""
        #expect(pattern.hasSuffix(".*"))
    }

    @Test("Wildcard without includeSubpaths does not append suffix")
    @MainActor
    func noSubpathsNoSuffix() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "No subpaths",
            urlPattern: "https://example.com",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: false,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        let pattern = vm.blockRules.first?.matchCondition.urlPattern ?? ""
        #expect(!pattern.hasSuffix(".*"))
    }

    @Test("blockRules filters only block-type rules")
    @MainActor
    func blockRulesFiltering() {
        let vm = BlockListViewModel()
        vm.addBlockRule(
            ruleName: "Test",
            urlPattern: "*.test.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.count == 1)
        #expect(vm.ruleCount == 1)
    }

    @Test("removeSelected removes the correct rule")
    @MainActor
    func removeSelected() {
        let vm = BlockListViewModel()
        vm.addBlockRule(
            ruleName: "Rule A",
            urlPattern: "*.a.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )
        vm.addBlockRule(
            ruleName: "Rule B",
            urlPattern: "*.b.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        #expect(vm.blockRules.count == 2)
        vm.selectedRuleID = vm.blockRules.first?.id
        vm.removeSelected()
        #expect(vm.blockRules.count == 1)
        #expect(vm.blockRules.first?.name == "Rule B")
        #expect(vm.selectedRuleID == nil)
    }

    @Test("toggleRule toggles enabled state")
    @MainActor
    func toggleRule() throws {
        let vm = BlockListViewModel()
        vm.addBlockRule(
            ruleName: "Toggle Test",
            urlPattern: "*.toggle.com/*",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: true,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        let ruleID = try #require(vm.blockRules.first?.id)
        #expect(vm.blockRules.first?.isEnabled == true)
        vm.toggleRule(id: ruleID)
        #expect(vm.blockRules.first?.isEnabled == false)
        vm.toggleRule(id: ruleID)
        #expect(vm.blockRules.first?.isEnabled == true)
    }

    @Test("All HTTP method filters can be used to create rules")
    @MainActor
    func allMethodFilters() {
        let vm = BlockListViewModel()

        for method in HTTPMethodFilter.allCases {
            vm.addBlockRule(
                ruleName: "Rule \(method.rawValue)",
                urlPattern: "*.example.com/*",
                httpMethod: method,
                matchType: .wildcard,
                blockAction: .blockAndHide,
                includeSubpaths: true,
                graphQLQueryName: nil,
                blockAppBundleID: nil
            )
        }

        #expect(vm.blockRules.count == HTTPMethodFilter.allCases.count)
    }

    @Test("All action types can be used to create rules")
    @MainActor
    func allActionTypes() {
        let vm = BlockListViewModel()

        for action in BlockActionType.allCases {
            vm.addBlockRule(
                ruleName: "Rule \(action.rawValue)",
                urlPattern: "*.example.com/*",
                httpMethod: .any,
                matchType: .wildcard,
                blockAction: action,
                includeSubpaths: true,
                graphQLQueryName: nil,
                blockAppBundleID: nil
            )
        }

        #expect(vm.blockRules.count == BlockActionType.allCases.count)
    }

    @Test("All match types can be used to create rules")
    @MainActor
    func allMatchTypes() {
        let vm = BlockListViewModel()

        for matchType in BlockMatchType.allCases {
            vm.addBlockRule(
                ruleName: "Rule \(matchType.rawValue)",
                urlPattern: "*.example.com/*",
                httpMethod: .any,
                matchType: matchType,
                blockAction: .blockAndHide,
                includeSubpaths: true,
                graphQLQueryName: matchType == .graphQLQueryName ? "testQuery" : nil,
                blockAppBundleID: nil
            )
        }

        #expect(vm.blockRules.count == BlockMatchType.allCases.count)
    }

    @Test("Wildcard escapes special regex characters in pattern")
    @MainActor
    func wildcardEscapesSpecialChars() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Escape test",
            urlPattern: "https://example.com/path?q=1",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: false,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        let pattern = vm.blockRules.first?.matchCondition.urlPattern ?? ""
        // The ? should be escaped by NSRegularExpression then converted to .
        #expect(!pattern.contains("?"))
    }

    @Test("Wildcard converts * to .* and ? to .")
    @MainActor
    func wildcardConversion() {
        let vm = BlockListViewModel()

        vm.addBlockRule(
            ruleName: "Wildcard convert",
            urlPattern: "*.example.com/?page",
            httpMethod: .any,
            matchType: .wildcard,
            blockAction: .blockAndHide,
            includeSubpaths: false,
            graphQLQueryName: nil,
            blockAppBundleID: nil
        )

        let pattern = vm.blockRules.first?.matchCondition.urlPattern ?? ""
        #expect(pattern.contains(".*"))
        #expect(pattern.contains(".page"))
    }
}
