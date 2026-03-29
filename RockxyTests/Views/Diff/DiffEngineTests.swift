import Foundation
@testable import Rockxy
import Testing

// Regression tests for `DiffEngine` in the views diff layer.

struct DiffEngineTests {
    @Test("Identical inputs produce no differences")
    func identicalInputs() {
        let lines = ["line 1", "line 2", "line 3"]
        let result = DiffEngine.diff(old: lines, new: lines)
        #expect(result.allSatisfy { $0.type == .unchanged })
        #expect(result.count == 3)
    }

    @Test("Added lines detected correctly")
    func addedLines() {
        let old = ["line 1", "line 2"]
        let new = ["line 1", "line 2", "line 3"]
        let result = DiffEngine.diff(old: old, new: new)
        let added = result.filter { $0.type == .added }
        #expect(added.count == 1)
        #expect(added[0].content == "line 3")
    }

    @Test("Removed lines detected correctly")
    func removedLines() {
        let old = ["line 1", "line 2", "line 3"]
        let new = ["line 1", "line 3"]
        let result = DiffEngine.diff(old: old, new: new)
        let removed = result.filter { $0.type == .removed }
        #expect(removed.count == 1)
        #expect(removed[0].content == "line 2")
    }

    @Test("Changed lines show as remove + add")
    func changedLines() {
        let old = ["Host: prod.example.com"]
        let new = ["Host: staging.example.com"]
        let result = DiffEngine.diff(old: old, new: new)
        #expect(result.filter { $0.type == .removed }.count == 1)
        #expect(result.filter { $0.type == .added }.count == 1)
    }

    @Test("Empty inputs produce empty result")
    func emptyInputs() {
        let result = DiffEngine.diff(old: [], new: [])
        #expect(result.isEmpty)
    }

    @Test("Left empty, right has content")
    func leftEmpty() {
        let result = DiffEngine.diff(old: [], new: ["line 1", "line 2"])
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.type == .added })
    }

    @Test("Right empty, left has content")
    func rightEmpty() {
        let result = DiffEngine.diff(old: ["line 1", "line 2"], new: [])
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.type == .removed })
    }

    @Test("Line numbers are sequential")
    func lineNumbers() {
        let old = ["a", "b", "c"]
        let new = ["a", "x", "c"]
        let result = DiffEngine.diff(old: old, new: new)
        for (index, line) in result.enumerated() {
            #expect(line.lineNumber == index + 1)
        }
    }

    @Test("Structured sections diff independently")
    func structuredSections() {
        let left = [("Headers", "Content-Type: json"), ("Body", "{\"a\": 1}")]
        let right = [("Headers", "Content-Type: xml"), ("Body", "{\"a\": 1}")]
        let result = DiffEngine.diffSections(leftSections: left, rightSections: right)

        #expect(result.sections.count == 2)
        #expect(result.sections[0].title == "Headers")
        #expect(result.sections[0].lines.contains { $0.type == .removed })
        #expect(result.sections[1].title == "Body")
        #expect(result.sections[1].lines.allSatisfy { $0.type == .unchanged })
    }

    @Test("DiffResult leftLines excludes added lines")
    func leftLinesFilter() {
        let lines = [
            DiffLine(lineNumber: 1, content: "same", type: .unchanged),
            DiffLine(lineNumber: 2, content: "new", type: .added),
            DiffLine(lineNumber: 3, content: "old", type: .removed),
        ]
        let result = DiffResult(sections: [DiffSection(title: "Test", lines: lines)])
        #expect(result.leftLines.count == 2)
        #expect(!result.leftLines.contains { $0.type == .added })
    }

    @Test("DiffResult rightLines excludes removed lines")
    func rightLinesFilter() {
        let lines = [
            DiffLine(lineNumber: 1, content: "same", type: .unchanged),
            DiffLine(lineNumber: 2, content: "new", type: .added),
            DiffLine(lineNumber: 3, content: "old", type: .removed),
        ]
        let result = DiffResult(sections: [DiffSection(title: "Test", lines: lines)])
        #expect(result.rightLines.count == 2)
        #expect(!result.rightLines.contains { $0.type == .removed })
    }

    // MARK: - Regression: Side-by-side alignment

    @Test("Side-by-side paired rows have same count for both panes")
    func pairedRowAlignment() {
        let lines = [
            DiffLine(lineNumber: 1, content: "same", type: .unchanged),
            DiffLine(lineNumber: 2, content: "removed", type: .removed),
            DiffLine(lineNumber: 3, content: "added", type: .added),
            DiffLine(lineNumber: 4, content: "same2", type: .unchanged),
        ]
        let rows = DiffResult.sideBySideRows(from: lines)
        #expect(rows.count == 4)
        // Row 1: unchanged — both sides present
        #expect(rows[0].left != nil)
        #expect(rows[0].right != nil)
        // Row 2: removed — left only
        #expect(rows[1].left != nil)
        #expect(rows[1].right == nil)
        // Row 3: added — right only
        #expect(rows[2].left == nil)
        #expect(rows[2].right != nil)
        // Row 4: unchanged — both sides
        #expect(rows[3].left != nil)
        #expect(rows[3].right != nil)
    }

    @Test("Section matching by title handles mismatched section counts")
    func sectionMatchingByTitle() {
        let left = [("Status Line", "No response"), ("Headers", "(no headers)"), ("Body", "No response body")]
        let right = [("Status Line", "HTTP 200 OK"), ("Headers", "Content-Type: json"), ("Body", "{\"ok\":true}")]
        let result = DiffEngine.diffSections(leftSections: left, rightSections: right)
        #expect(result.sections.count == 3)
        #expect(result.sections[0].title == "Status Line")
        #expect(result.sections[1].title == "Headers")
        #expect(result.sections[2].title == "Body")
    }

    @Test("Section matching handles one side with fewer sections")
    func sectionMatchingFewerSections() {
        let left = [("A", "content A")]
        let right = [("A", "content A"), ("B", "content B")]
        let result = DiffEngine.diffSections(leftSections: left, rightSections: right)
        #expect(result.sections.count == 2)
        #expect(result.sections[0].title == "A")
        #expect(result.sections[1].title == "B")
        // Section B: left is empty, right has content → all added
        #expect(result.sections[1].lines.contains { $0.type == .added })
    }
}
