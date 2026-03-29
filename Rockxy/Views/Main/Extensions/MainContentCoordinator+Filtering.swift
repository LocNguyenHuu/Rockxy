import Foundation

// Extends `MainContentCoordinator` with filtering behavior for the main workspace.

// MARK: - MainContentCoordinator + Filtering

/// Coordinator extension for transaction filtering. Provides both a full recompute
/// and an incremental append path for batch delivery without user filters active.
extension MainContentCoordinator {
    // MARK: - Filtered Transactions

    func appendFilteredTransactions(_ batch: [HTTPTransaction]) {
        let hasActiveRules = isFilterBarVisible && filterRules.contains { $0.isEnabled && !$0.value.isEmpty }
        if filterCriteria.sidebarScope == .allTraffic, filterCriteria.isEmpty, !hasActiveRules {
            filteredTransactions.append(contentsOf: batch.filter { !$0.isTLSFailure })
        } else {
            recomputeFilteredTransactions()
        }
    }

    func recomputeFilteredTransactions() {
        let baseList: [HTTPTransaction] = switch filterCriteria.sidebarScope {
        case .saved:
            allSavedTransactions
        case .pinned:
            allPinnedTransactions
        case .allTraffic:
            transactions
        }

        let hasActiveRules = isFilterBarVisible && filterRules.contains { $0.isEnabled && !$0.value.isEmpty }
        guard !filterCriteria.isEmpty || hasActiveRules else {
            filteredTransactions = baseList.filter { !$0.isTLSFailure }
            return
        }
        filteredTransactions = baseList.filter { transaction in
            if transaction.isTLSFailure {
                return false
            }
            if let sidebarDomain = filterCriteria.sidebarDomain {
                guard transaction.request.host.hasSuffix(sidebarDomain)
                    || transaction.request.host == sidebarDomain else
                {
                    return false
                }
            }
            if let sidebarApp = filterCriteria.sidebarApp {
                guard transaction.clientApp == sidebarApp else {
                    return false
                }
            }
            if filterCriteria.isSearchEnabled, !filterCriteria.searchText.isEmpty {
                let searchText = filterCriteria.searchText.lowercased()
                let targetValue = fieldValue(for: filterCriteria.searchField, in: transaction)
                guard targetValue.lowercased().contains(searchText) else {
                    return false
                }
            }
            if !filterCriteria.methods.isEmpty {
                guard filterCriteria.methods.contains(transaction.request.method) else {
                    return false
                }
            }
            if !filterCriteria.statusCodes.isEmpty {
                guard let status = transaction.response?.statusCode,
                      filterCriteria.statusCodes.contains(status) else
                {
                    return false
                }
            }
            if !filterCriteria.activeProtocolFilters.isEmpty {
                let contentFilters = filterCriteria.activeProtocolFilters.filter { !$0.isStatusFilter }
                let statusFilters = filterCriteria.activeProtocolFilters.filter(\.isStatusFilter)

                if !contentFilters.isEmpty {
                    guard contentFilters.contains(where: { $0.matches(transaction) }) else {
                        return false
                    }
                }
                if !statusFilters.isEmpty {
                    guard statusFilters.contains(where: { $0.matches(transaction) }) else {
                        return false
                    }
                }
            }
            if hasActiveRules {
                for rule in filterRules where rule.isEnabled && !rule.value.isEmpty {
                    let fieldValue = fieldValue(for: rule.field, in: transaction)
                    guard rule.filterOperator.matches(fieldValue, against: rule.value) else {
                        return false
                    }
                }
            }
            return true
        }
    }

    func fieldValue(for field: FilterField, in transaction: HTTPTransaction) -> String {
        switch field {
        case .url,
             .contains: transaction.request.url.absoluteString
        case .host: transaction.request.host
        case .path: transaction.request.path
        case .method: transaction.request.method
        case .statusCode: transaction.response.map { String($0.statusCode) } ?? ""
        case .requestHeader: transaction.request.headers.map { "\($0.name): \($0.value)" }.joined(separator: "\n")
        case .responseHeader:
            (transaction.response?.headers ?? []).map { "\($0.name): \($0.value)" }.joined(separator: "\n")
        case .queryString: transaction.request.url.query ?? ""
        case .comment: transaction.comment ?? ""
        case .color: transaction.highlightColor?.rawValue ?? ""
        }
    }

    // MARK: - Per-Workspace Filtering

    func appendFilteredTransactions(_ batch: [HTTPTransaction], to workspace: WorkspaceState) {
        let hasActiveRules = workspace.isFilterBarVisible
            && workspace.filterRules.contains { $0.isEnabled && !$0.value.isEmpty }
        if workspace.filterCriteria.isEmpty, !hasActiveRules {
            workspace.filteredTransactions.append(contentsOf: batch.filter { !$0.isTLSFailure })
        } else {
            recomputeFilteredTransactions(for: workspace)
        }
    }

    func recomputeFilteredTransactions(for workspace: WorkspaceState) {
        let baseList: [HTTPTransaction] = switch workspace.filterCriteria.sidebarScope {
        case .saved:
            allSavedTransactions
        case .pinned:
            allPinnedTransactions
        case .allTraffic:
            transactions
        }

        let hasActiveRules = workspace.isFilterBarVisible
            && workspace.filterRules.contains { $0.isEnabled && !$0.value.isEmpty }
        guard !workspace.filterCriteria.isEmpty || hasActiveRules else {
            workspace.filteredTransactions = baseList.filter { !$0.isTLSFailure }
            return
        }
        workspace.filteredTransactions = baseList.filter { transaction in
            if transaction.isTLSFailure {
                return false
            }
            if let sidebarDomain = workspace.filterCriteria.sidebarDomain {
                guard transaction.request.host.hasSuffix(sidebarDomain)
                    || transaction.request.host == sidebarDomain else
                {
                    return false
                }
            }
            if let sidebarApp = workspace.filterCriteria.sidebarApp {
                guard transaction.clientApp == sidebarApp else {
                    return false
                }
            }
            if workspace.filterCriteria.isSearchEnabled, !workspace.filterCriteria.searchText.isEmpty {
                let searchText = workspace.filterCriteria.searchText.lowercased()
                let targetValue = fieldValue(for: workspace.filterCriteria.searchField, in: transaction)
                guard targetValue.lowercased().contains(searchText) else {
                    return false
                }
            }
            if !workspace.filterCriteria.methods.isEmpty {
                guard workspace.filterCriteria.methods.contains(transaction.request.method) else {
                    return false
                }
            }
            if !workspace.filterCriteria.statusCodes.isEmpty {
                guard let status = transaction.response?.statusCode,
                      workspace.filterCriteria.statusCodes.contains(status) else
                {
                    return false
                }
            }
            if !workspace.filterCriteria.activeProtocolFilters.isEmpty {
                let contentFilters = workspace.filterCriteria.activeProtocolFilters.filter { !$0.isStatusFilter }
                let statusFilters = workspace.filterCriteria.activeProtocolFilters.filter(\.isStatusFilter)

                if !contentFilters.isEmpty {
                    guard contentFilters.contains(where: { $0.matches(transaction) }) else {
                        return false
                    }
                }
                if !statusFilters.isEmpty {
                    guard statusFilters.contains(where: { $0.matches(transaction) }) else {
                        return false
                    }
                }
            }
            if hasActiveRules {
                for rule in workspace.filterRules where rule.isEnabled && !rule.value.isEmpty {
                    let fv = fieldValue(for: rule.field, in: transaction)
                    guard rule.filterOperator.matches(fv, against: rule.value) else {
                        return false
                    }
                }
            }
            return true
        }
    }
}
