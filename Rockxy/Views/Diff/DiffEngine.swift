import Foundation

// Renders the diff interface for the diff workflow.

// MARK: - DiffLineType

enum DiffLineType: Equatable {
    case unchanged
    case added
    case removed
}

// MARK: - DiffLine

struct DiffLine: Identifiable, Equatable {
    // MARK: Lifecycle

    init(lineNumber: Int, content: String, type: DiffLineType) {
        self.id = UUID()
        self.lineNumber = lineNumber
        self.content = content
        self.type = type
    }

    // MARK: Internal

    let id: UUID
    let lineNumber: Int
    let content: String
    let type: DiffLineType

    static func == (lhs: DiffLine, rhs: DiffLine) -> Bool {
        lhs.lineNumber == rhs.lineNumber && lhs.content == rhs.content && lhs.type == rhs.type
    }
}

// MARK: - DiffSection

/// A named section within a structured diff result (e.g., "Request Line", "Headers", "Body").
struct DiffSection: Identifiable {
    let id = UUID()
    let title: String
    let lines: [DiffLine]
}

// MARK: - SideBySideRow

/// A paired row for side-by-side rendering. Both panes render from the same sequence,
/// so lines always align vertically. nil means a spacer at that position.
struct SideBySideRow: Identifiable {
    let id = UUID()
    let left: DiffLine?
    let right: DiffLine?
}

// MARK: - DiffResult

/// Structured diff result containing named sections, each with their own diff lines.
struct DiffResult {
    static let empty = DiffResult(sections: [])

    let sections: [DiffSection]

    var allLines: [DiffLine] {
        sections.flatMap(\.lines)
    }

    var addedCount: Int {
        allLines.filter { $0.type == .added }.count
    }

    var removedCount: Int {
        allLines.filter { $0.type == .removed }.count
    }

    var differenceCount: Int {
        addedCount + removedCount
    }

    var leftLines: [DiffLine] {
        allLines.filter { $0.type != .added }
    }

    var rightLines: [DiffLine] {
        allLines.filter { $0.type != .removed }
    }

    /// Builds paired rows for side-by-side rendering from a section's diff lines.
    /// Unchanged lines appear on both sides. Removed lines appear left-only (right=nil).
    /// Added lines appear right-only (left=nil).
    static func sideBySideRows(from lines: [DiffLine]) -> [SideBySideRow] {
        var rows: [SideBySideRow] = []
        for line in lines {
            switch line.type {
            case .unchanged:
                rows.append(SideBySideRow(left: line, right: line))
            case .removed:
                rows.append(SideBySideRow(left: line, right: nil))
            case .added:
                rows.append(SideBySideRow(left: nil, right: line))
            }
        }
        return rows
    }
}

// MARK: - DiffEngine

/// Pure diff algorithm using Longest Common Subsequence. Extracted for testability.
enum DiffEngine {
    // MARK: Internal

    /// Computes a line-level diff between two string arrays.
    static func diff(old: [String], new: [String]) -> [DiffLine] {
        let lcs = longestCommonSubsequence(old, new)
        var result: [DiffLine] = []
        var oldIdx = 0
        var newIdx = 0
        var lineNumber = 1

        for commonLine in lcs {
            while oldIdx < old.count, old[oldIdx] != commonLine {
                result.append(DiffLine(lineNumber: lineNumber, content: old[oldIdx], type: .removed))
                oldIdx += 1
                lineNumber += 1
            }
            while newIdx < new.count, new[newIdx] != commonLine {
                result.append(DiffLine(lineNumber: lineNumber, content: new[newIdx], type: .added))
                newIdx += 1
                lineNumber += 1
            }
            result.append(DiffLine(lineNumber: lineNumber, content: commonLine, type: .unchanged))
            oldIdx += 1
            newIdx += 1
            lineNumber += 1
        }

        while oldIdx < old.count {
            result.append(DiffLine(lineNumber: lineNumber, content: old[oldIdx], type: .removed))
            oldIdx += 1
            lineNumber += 1
        }
        while newIdx < new.count {
            result.append(DiffLine(lineNumber: lineNumber, content: new[newIdx], type: .added))
            newIdx += 1
            lineNumber += 1
        }

        return result
    }

    /// Computes a structured diff with named sections, matching by title.
    /// Uses an ordered title list from both sides to keep section order stable.
    static func diffSections(leftSections: [(String, String)], rightSections: [(String, String)]) -> DiffResult {
        var sections: [DiffSection] = []

        // Build ordered title list preserving order from left side, then adding any right-only titles
        var orderedTitles: [String] = []
        for (title, _) in leftSections where !orderedTitles.contains(title) {
            orderedTitles.append(title)
        }
        for (title, _) in rightSections where !orderedTitles.contains(title) {
            orderedTitles.append(title)
        }

        let leftMap = Dictionary(leftSections.map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })
        let rightMap = Dictionary(rightSections.map { ($0.0, $0.1) }, uniquingKeysWith: { first, _ in first })

        for title in orderedTitles {
            let leftContent = leftMap[title] ?? ""
            let rightContent = rightMap[title] ?? ""

            let leftLines = leftContent.components(separatedBy: "\n")
            let rightLines = rightContent.components(separatedBy: "\n")
            let diffLines = diff(old: leftLines, new: rightLines)

            sections.append(DiffSection(title: title, lines: diffLines))
        }

        return DiffResult(sections: sections)
    }

    // MARK: Private

    private static func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
        let m = a.count
        let n = b.count
        guard m > 0, n > 0 else {
            return []
        }

        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1 ... m {
            for j in 1 ... n {
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        var result: [String] = []
        var i = m
        var j = n
        while i > 0, j > 0 {
            if a[i - 1] == b[j - 1] {
                result.append(a[i - 1])
                i -= 1
                j -= 1
            } else if dp[i - 1][j] > dp[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }

        return result.reversed()
    }
}
