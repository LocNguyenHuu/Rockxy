import AppKit
import SwiftUI

/// NSTextView-backed body editor used by the inspector.
/// Shows JSON/text payloads with code-like selection, cursor placement, line numbers,
/// horizontal scrolling, and lightweight syntax coloring.
struct InspectorBodyTextEditor: NSViewRepresentable {
    let text: String
    var fontSize: CGFloat = 12

    func makeNSView(context _: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        configure(scrollView)
        apply(text, to: scrollView)
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context _: Context) {
        guard let textView = nsView.documentView as? NSTextView else {
            return
        }
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            apply(text, to: nsView)
            textView.setSelectedRange(clamped(range: selectedRange, length: (text as NSString).length))
        }
    }

    private func configure(_ scrollView: NSScrollView) {
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true

        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }

        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false

        let ruler = ScriptCodeEditorRulerView(textView: textView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
    }

    private func apply(_ text: String, to scrollView: NSScrollView) {
        guard let textView = scrollView.documentView as? NSTextView else {
            return
        }
        textView.textStorage?.setAttributedString(highlightedText(text))
    }

    private func highlightedText(_ text: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                .foregroundColor: NSColor.textColor,
                .backgroundColor: NSColor.textBackgroundColor,
            ]
        )
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        applyPattern(#""(?:\\.|[^"\\])*""#, color: Theme.JSON.stringNS, to: attributed, range: fullRange)
        applyPattern(#""(?:\\.|[^"\\])*"(?=\s*:)"#, color: Theme.JSON.keyNS, to: attributed, range: fullRange)
        applyPattern(
            #"(?<![\w.])-?\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b"#,
            color: Theme.JSON.numberNS,
            to: attributed,
            range: fullRange
        )
        applyPattern(#"\b(?:true|false)\b"#, color: Theme.JSON.boolNS, to: attributed, range: fullRange)
        applyPattern(#"\bnull\b"#, color: Theme.JSON.nullNS, to: attributed, range: fullRange)
        applyPattern(#"[\{\}\[\],:]"#, color: Theme.JSON.bracketNS, to: attributed, range: fullRange)
        applyPattern(#"(?m)^HTTP/\d(?:\.\d)?"#, color: Theme.JSON.statusNS, to: attributed, range: fullRange)
        applyPattern(
            #"(?m)^[A-Za-z0-9!#$%&'*+.^_`|~-]+:"#,
            color: Theme.JSON.headerNS,
            to: attributed,
            range: fullRange
        )
        return attributed
    }

    private func applyPattern(
        _ pattern: String,
        color: NSColor,
        to attributed: NSMutableAttributedString,
        range: NSRange
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return
        }
        regex.enumerateMatches(in: attributed.string, range: range) { match, _, _ in
            guard let match else {
                return
            }
            attributed.addAttribute(.foregroundColor, value: color, range: match.range)
        }
    }

    private func clamped(range: NSRange, length: Int) -> NSRange {
        guard range.location != NSNotFound else {
            return NSRange(location: 0, length: 0)
        }
        let location = min(range.location, length)
        let upperBound = min(range.location + range.length, length)
        return NSRange(location: location, length: max(0, upperBound - location))
    }
}
