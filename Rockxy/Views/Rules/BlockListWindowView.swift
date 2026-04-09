import os
import SwiftUI

// Presents the block list window for rule editing and management.

// MARK: - BlockListViewModel

@MainActor @Observable
final class BlockListViewModel {
    var selectedRuleID: UUID?
    var showAddSheet = false
    private(set) var allRules: [ProxyRule] = []

    var blockRules: [ProxyRule] {
        allRules.filter { rule in
            if case .block = rule.action {
                return true
            }
            return false
        }
    }

    var ruleCount: Int {
        blockRules.count
    }

    func refreshFromEngine() async {
        allRules = await RuleEngine.shared.allRules
    }

    func handleRulesDidChange(_ notification: Notification) {
        if let rules = notification.object as? [ProxyRule] {
            allRules = rules
        }
    }

    func addBlockRule(
        ruleName: String,
        urlPattern: String,
        httpMethod: HTTPMethodFilter,
        matchType: BlockMatchType,
        blockAction: BlockActionType,
        includeSubpaths: Bool,
        graphQLQueryName: String?,
        blockAppBundleID: String?
    ) {
        let escapedPattern: String
        switch matchType {
        case .wildcard:
            var pattern = NSRegularExpression.escapedPattern(for: urlPattern)
                .replacingOccurrences(of: "\\*", with: ".*")
                .replacingOccurrences(of: "\\?", with: ".")
            if includeSubpaths, !pattern.hasSuffix(".*") {
                pattern += ".*"
            }
            escapedPattern = pattern
        case .regex:
            escapedPattern = urlPattern
        case .graphQLQueryName:
            escapedPattern = NSRegularExpression.escapedPattern(for: urlPattern)
                .replacingOccurrences(of: "\\*", with: ".*")
        }

        let displayName = ruleName.isEmpty ? urlPattern : ruleName

        let rule = ProxyRule(
            name: displayName,
            matchCondition: RuleMatchCondition(
                urlPattern: escapedPattern,
                method: httpMethod.methodValue
            ),
            action: .block(statusCode: blockAction.statusCode)
        )
        allRules.append(rule)
        Task { await RuleSyncService.addRule(rule) }
    }

    func removeSelected() {
        guard let id = selectedRuleID else {
            return
        }
        allRules.removeAll { $0.id == id }
        selectedRuleID = nil
        Task { await RuleSyncService.removeRule(id: id) }
    }

    func toggleRule(id: UUID) {
        guard let index = allRules.firstIndex(where: { $0.id == id }) else {
            return
        }
        allRules[index].isEnabled.toggle()
        Task { await RuleSyncService.toggleRule(id: id) }
    }
}

// MARK: - HTTPMethodFilter

enum HTTPMethodFilter: String, CaseIterable {
    case any = "ANY"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"

    // MARK: Internal

    /// Returns the method string for rule matching, or `nil` for `.any`.
    var methodValue: String? {
        self == .any ? nil : rawValue
    }
}

// MARK: - BlockMatchType

enum BlockMatchType: String, CaseIterable {
    case wildcard = "Use Wildcard"
    case regex = "Use Regex"
    case graphQLQueryName = "GraphQL QueryName"

    // MARK: Internal

    /// Whether the "Include all subpaths" checkbox should be shown.
    var showsSubpathsToggle: Bool {
        self == .wildcard || self == .regex
    }

    /// Whether the GraphQL query name text field should be shown.
    var showsGraphQLField: Bool {
        self == .graphQLQueryName
    }
}

// MARK: - BlockActionType

enum BlockActionType: String, CaseIterable {
    case blockAndHide = "Block & Hide Request"
    case blockAndDisplay = "Block & Display Requests"
    case hideOnly = "Hide, but not Block"

    // MARK: Internal

    /// The HTTP status code for the block action.
    var statusCode: Int {
        switch self {
        case .blockAndHide: 403
        case .blockAndDisplay: 403
        case .hideOnly: 0
        }
    }

    /// Whether the blocked request should be hidden from the request list.
    var hidesFromList: Bool {
        self == .blockAndHide || self == .hideOnly
    }
}

// MARK: - BlockListWindowView

struct BlockListWindowView: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            infoBanner
            Divider()
            content
            Divider()
            bottomBar
        }
        .frame(width: 800, height: 560)
        .task { await viewModel.refreshFromEngine() }
        .onReceive(NotificationCenter.default.publisher(for: .rulesDidChange)) { notification in
            viewModel.handleRulesDidChange(notification)
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddBlockRuleSheet { ruleName, pattern, method, matchType, action, includeSubpaths, graphQLQueryName, appBundleID in
                viewModel.addBlockRule(
                    ruleName: ruleName,
                    urlPattern: pattern,
                    httpMethod: method,
                    matchType: matchType,
                    blockAction: action,
                    includeSubpaths: includeSubpaths,
                    graphQLQueryName: graphQLQueryName,
                    blockAppBundleID: appBundleID
                )
            }
        }
    }

    // MARK: Private

    private static let logger = Logger(subsystem: RockxyIdentity.current.logSubsystem, category: "BlockListWindowView")

    @State private var viewModel = BlockListViewModel()

    private var toolbar: some View {
        HStack {
            Text(String(localized: "Block List"))
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var infoBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(
                String(
                    localized:
                    "Blocked requests return 403 Forbidden or are silently dropped. Use wildcards (*) or regex for pattern matching."
                )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5))
    }

    @ViewBuilder private var content: some View {
        if viewModel.blockRules.isEmpty {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "nosign")
                    .font(.system(size: 20))
                    .foregroundStyle(.tertiary)
                Text(String(localized: "No Block Rules"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(String(localized: "Add URL patterns to block matching requests."))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                HStack(alignment: .top, spacing: 0) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red.opacity(0.4))
                        .frame(width: 2, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Example"))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                        HStack(spacing: 5) {
                            Text("*.example.com/ads/*")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 8))
                                .foregroundStyle(.tertiary)
                            Text("403 Forbidden")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.leading, 6)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        } else {
            List(selection: $viewModel.selectedRuleID) {
                ForEach(viewModel.blockRules) { rule in
                    BlockRuleRow(rule: rule) {
                        viewModel.toggleRule(id: rule.id)
                    }
                    .tag(rule.id)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)

            Button {
                viewModel.removeSelected()
            } label: {
                Image(systemName: "minus")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.selectedRuleID == nil)

            Divider()
                .frame(height: 16)

            Text(
                "\(viewModel.ruleCount) \(viewModel.ruleCount == 1 ? String(localized: "rule") : String(localized: "rules"))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - BlockRuleRow

private struct BlockRuleRow: View {
    // MARK: Internal

    let rule: ProxyRule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)

            Text(rule.name)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)

            matchTypeBadge

            Spacer()

            actionLabel
        }
        .padding(.vertical, 2)
        .opacity(rule.isEnabled ? 1.0 : 0.5)
    }

    // MARK: Private

    @ViewBuilder private var matchTypeBadge: some View {
        let detected = detectMatchType(rule.matchCondition.urlPattern ?? "")
        HStack(spacing: 4) {
            Text(detected.symbol)
                .font(.caption2.bold())
                .frame(width: 18, height: 18)
                .background(detected.color.opacity(0.15))
                .foregroundStyle(detected.color)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            if detected.isAutoDetected {
                Text(String(localized: "auto"))
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.yellow.opacity(0.2))
                    .foregroundStyle(.yellow)
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder private var actionLabel: some View {
        if case let .block(statusCode) = rule.action {
            let text = statusCode == 0
                ? String(localized: "Hide, but not Block")
                : String(localized: "403 Forbidden")
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func detectMatchType(_ pattern: String) -> (symbol: String, color: Color, isAutoDetected: Bool) {
        let isAnchored = pattern.hasPrefix("^") && pattern.hasSuffix("$")
        let regexSpecial = CharacterSet(charactersIn: "[](){}+?|^$\\")
        let hasRegexChars = pattern.unicodeScalars.contains { regexSpecial.contains($0) }

        if isAnchored, !hasRegexInner(pattern) {
            return ("=", .green, true)
        } else if hasRegexChars {
            return ("R", .purple, true)
        } else {
            return ("*", .blue, true)
        }
    }

    private func hasRegexInner(_ pattern: String) -> Bool {
        let inner = String(pattern.dropFirst().dropLast())
        let unescaped = inner.replacingOccurrences(of: "\\.", with: "")
        let regexSpecial = CharacterSet(charactersIn: "[](){}+?|^$\\.*")
        return unescaped.unicodeScalars.contains { regexSpecial.contains($0) }
    }
}

// MARK: - AddBlockRuleSheet

private struct AddBlockRuleSheet: View {
    // MARK: Internal

    let onSave: (String, String, HTTPMethodFilter, BlockMatchType, BlockActionType, Bool, String?, String?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                formRow(String(localized: "Name:")) {
                    TextField("", text: $ruleName, prompt: Text(String(localized: "Untitled")))
                        .textFieldStyle(.roundedBorder)
                }

                formRow(String(localized: "Matching Rule:")) {
                    TextField("", text: $urlPattern, prompt: Text("https://example.com"))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                methodAndMatchRow

                conditionalFields

                formRow(String(localized: "Block App:")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Button(String(localized: "Select App...")) {
                            showAppPicker = true
                        }
                        .popover(isPresented: $showAppPicker) {
                            AppPickerPopover(selectedBundleID: $blockAppBundleID)
                        }

                        if let bundleID = blockAppBundleID {
                            HStack(spacing: 4) {
                                Image(systemName: "app.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(bundleID)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button {
                                    blockAppBundleID = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Text(String(localized: "Allow blocking all traffic from a specific app (optional)."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                formRow(String(localized: "Action:")) {
                    Picker("", selection: $blockAction) {
                        ForEach(BlockActionType.allCases, id: \.self) { action in
                            Text(action.rawValue).tag(action)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, Theme.Layout.sectionSpacing)

            Divider()

            HStack {
                Spacer()
                Button(String(localized: "Cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button(String(localized: "Done")) {
                    onSave(
                        ruleName,
                        urlPattern,
                        httpMethod,
                        matchType,
                        blockAction,
                        includeSubpaths,
                        matchType.showsGraphQLField ? graphQLQueryName : nil,
                        blockAppBundleID
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(urlPattern.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: 560, height: 420)
    }

    // MARK: Private

    private static let labelWidth: CGFloat = 110

    @Environment(\.dismiss) private var dismiss
    @State private var ruleName = ""
    @State private var urlPattern = ""
    @State private var httpMethod: HTTPMethodFilter = .any
    @State private var matchType: BlockMatchType = .wildcard
    @State private var blockAction: BlockActionType = .blockAndHide
    @State private var includeSubpaths = true
    @State private var graphQLQueryName = ""
    @State private var blockAppBundleID: String?
    @State private var showAppPicker = false

    private var methodAndMatchRow: some View {
        HStack(spacing: 8) {
            Spacer()
                .frame(width: Self.labelWidth + Theme.Layout.sectionSpacing)
            Picker("", selection: $httpMethod) {
                ForEach(HTTPMethodFilter.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .labelsHidden()
            .frame(width: 90)

            Picker("", selection: $matchType) {
                ForEach(BlockMatchType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .labelsHidden()
            .frame(width: 175)

            if matchType == .wildcard {
                Text(String(localized: "Support wildcard * and ?."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var conditionalFields: some View {
        if matchType.showsSubpathsToggle {
            HStack(spacing: 8) {
                Spacer()
                    .frame(width: Self.labelWidth + Theme.Layout.sectionSpacing)
                Toggle(String(localized: "Include all subpaths of this URL"), isOn: $includeSubpaths)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 13))
            }
        }

        if matchType.showsGraphQLField {
            formRow(String(localized: "Query Name:")) {
                TextField("", text: $graphQLQueryName, prompt: Text("e.g. createUser"))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    private func formRow(
        _ label: String,
        @ViewBuilder content: () -> some View
    )
        -> some View
    {
        HStack(alignment: .top, spacing: Theme.Layout.sectionSpacing) {
            Text(label)
                .font(.system(size: 13))
                .frame(width: Self.labelWidth, alignment: .trailing)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 4) {
                content()
            }
        }
    }
}

// MARK: - AppPickerPopover

private struct AppPickerPopover: View {
    // MARK: Internal

    @Binding var selectedBundleID: String?

    var body: some View {
        VStack(spacing: 0) {
            TextField(String(localized: "Search apps..."), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(8)

            Divider()

            List(filteredApps, id: \.bundleID) { app in
                Button {
                    selectedBundleID = app.bundleID
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "app.fill")
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.secondary)
                        }
                        Text(app.name)
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        .frame(width: 280, height: 320)
        .task {
            installedApps = Self.loadInstalledApps()
        }
    }

    // MARK: Private

    @State private var searchText = ""
    @State private var installedApps: [(name: String, bundleID: String, icon: NSImage?)] = []
    @Environment(\.dismiss) private var dismiss

    private var filteredApps: [(name: String, bundleID: String, icon: NSImage?)] {
        if searchText.isEmpty {
            return installedApps
        }
        let query = searchText.lowercased()
        return installedApps.filter {
            $0.name.lowercased().contains(query) || $0.bundleID.lowercased().contains(query)
        }
    }

    private static func loadInstalledApps() -> [(name: String, bundleID: String, icon: NSImage?)] {
        let appDirs = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications",
        ]
        var apps: [(name: String, bundleID: String, icon: NSImage?)] = []
        let fileManager = FileManager.default

        for dir in appDirs {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else {
                continue
            }
            for item in contents where item.hasSuffix(".app") {
                let path = (dir as NSString).appendingPathComponent(item)
                guard let bundle = Bundle(path: path),
                      let bundleID = bundle.bundleIdentifier else
                {
                    continue
                }
                let name = (item as NSString).deletingPathExtension
                let icon = NSWorkspace.shared.icon(forFile: path)
                icon.size = NSSize(width: 20, height: 20)
                apps.append((name: name, bundleID: bundleID, icon: icon))
            }
        }
        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
