import SwiftUI

// Renders the breakpoint sidebar interface for breakpoint review and editing.

// MARK: - BreakpointSidebarView

/// Left panel of the Breakpoints window showing breakpoint rules and paused items.
/// Two sections: Rules (breakpoint-type rules) and Paused (items awaiting user decision).
struct BreakpointSidebarView: View {
    let windowModel: BreakpointWindowModel
    let manager: BreakpointManager

    var body: some View {
        VStack(spacing: 0) {
            if windowModel.breakpointRules.isEmpty, manager.pausedItems.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "pause.circle")
                        .font(.title2).foregroundStyle(.secondary)
                    Text(String(localized: "No breakpoint rules or paused items."))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(String(localized: "Create breakpoint from context menu or Tools menu."))
                        .font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if !windowModel.breakpointRules.isEmpty {
                        Section(header: Text("Rules (\(windowModel.breakpointRules.count))")) {
                            ForEach(windowModel.breakpointRules) { rule in
                                BreakpointRuleRow(
                                    rule: rule,
                                    isSelected: windowModel.selectedBreakpointRuleId == rule.id,
                                    onToggle: { ruleId in
                                        Task { await RuleSyncService.toggleRule(id: ruleId) }
                                    }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture { windowModel.selectRule(rule.id) }
                            }
                        }
                    }

                    if !manager.pausedItems.isEmpty {
                        Section(header: Text("Paused (\(manager.pausedItems.count))")) {
                            ForEach(manager.pausedItems) { item in
                                BreakpointQueueRow(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture { windowModel.selectPausedItem(item.id) }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
