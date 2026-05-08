import Foundation
@testable import Rockxy
import Testing

struct FooterActionDescriptorTests {
    @Test("Footer tooling action order is stable")
    func toolingActionOrder() {
        let actions = FooterActionDescriptor.toolingActions(isAllowListActive: false)

        #expect(actions.map(\.id) == [
            .blockList,
            .allowList,
            .mapLocal,
            .scripting,
            .mapRemote,
            .breakpoint,
            .networkConditions,
        ])
    }

    @Test("Footer actions use SF Symbol names")
    func actionSymbolsArePresent() {
        let actions = FooterActionDescriptor.toolingActions(isAllowListActive: false)

        #expect(actions.allSatisfy { !$0.systemImage.isEmpty })
        #expect(actions.first { $0.id == .blockList }?.systemImage == "hand.raised.slash")
        #expect(actions.first { $0.id == .allowList }?.systemImage == "checkmark.shield")
        #expect(actions.first { $0.id == .mapLocal }?.systemImage == "folder.badge.gearshape")
        #expect(actions.first { $0.id == .scripting }?.systemImage == "curlybraces")
        #expect(actions.first { $0.id == .mapRemote }?.systemImage == "arrow.triangle.branch")
        #expect(actions.first { $0.id == .breakpoint }?.systemImage == "pause.circle")
        #expect(actions.first { $0.id == .networkConditions }?.systemImage == "speedometer")
    }

    @Test("Allow List active state reflects manager state")
    func activeStates() {
        let tooling = FooterActionDescriptor.toolingActions(isAllowListActive: true)

        #expect(tooling.first { $0.id == .allowList }?.isActive == true)
    }

    @Test("Footer tool actions render inline without overflow")
    func toolActionsRemainInline() {
        let actions = FooterActionDescriptor.toolingActions(isAllowListActive: false)

        #expect(FooterActionKind.allCases == actions.map(\.id))
    }
}
