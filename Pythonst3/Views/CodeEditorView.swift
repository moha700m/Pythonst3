import SwiftUI
import UIKit

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var onCursorChange: (Int, Int) -> Void = { _, _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> CodeEditorContainerView {
        let view = CodeEditorContainerView()
        view.textView.delegate = context.coordinator
        view.configure(fontSize: fontSize)
        view.setText(text)
        context.coordinator.container = view
        return view
    }

    func updateUIView(_ uiView: CodeEditorContainerView, context: Context) {
        context.coordinator.parent = self
        uiView.configure(fontSize: fontSize)
        if uiView.textView.text != text {
            uiView.setText(text)
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: CodeEditorView
        weak var container: CodeEditorContainerView?
        private var highlightWorkItem: DispatchWorkItem?

        init(_ parent: CodeEditorView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
            container?.lineNumbers.refresh()
            scheduleHighlight()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let content = textView.text ?? ""
            let location = min(textView.selectedRange.location, (content as NSString).length)
            let prefix = (content as NSString).substring(to: location)
            let lines = prefix.components(separatedBy: "\n")
            let column = ((lines.last ?? "") as NSString).length + 1
            parent.onCursorChange(max(1, lines.count), column)
        }

        private func scheduleHighlight() {
            highlightWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self] in
                self?.container?.applyHighlight()
            }
            highlightWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: item)
        }
    }
}

final class CodeEditorContainerView: UIView {
    let textView = UITextView()
    let lineNumbers = LineNumberGutterView()
    private var font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(CyberTheme.background)

        lineNumbers.backgroundColor = UIColor(CyberTheme.background)
        lineNumbers.isUserInteractionEnabled = false
        lineNumbers.textInsetTop = 8

        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.spellCheckingType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.smartInsertDeleteType = .no
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 18, right: 6)
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInsetAdjustmentBehavior = .never
        textView.textAlignment = .left
        textView.semanticContentAttribute = .forceLeftToRight
        textView.tintColor = UIColor(CyberTheme.neonGreen)
        textView.indicatorStyle = .white
        textView.font = font
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: UIColor(CyberTheme.textPrimary)
        ]
        textView.accessibilityLabel = "محرر الكود"

        addSubview(lineNumbers)
        addSubview(textView)
        lineNumbers.attach(to: textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(fontSize: CGFloat) {
        let newFont = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if newFont.pointSize != textView.font?.pointSize {
            font = newFont
            textView.font = newFont
            textView.typingAttributes = [
                .font: newFont,
                .foregroundColor: UIColor(CyberTheme.textPrimary)
            ]
            applyHighlight()
        }
        lineNumbers.font = UIFont.monospacedSystemFont(ofSize: max(9, fontSize - 2), weight: .regular)
        lineNumbers.refresh()
    }

    func setText(_ text: String) {
        textView.text = text
        applyHighlight()
        lineNumbers.refresh()
    }

    func applyHighlight() {
        let storage = textView.textStorage
        let selected = textView.selectedRange
        let content = textView.text ?? ""
        let highlighted = PythonHighlighter.highlight(
            content,
            font: font,
            baseColor: UIColor(CyberTheme.textPrimary)
        )

        storage.beginEditing()
        storage.setAttributedString(highlighted)
        storage.endEditing()

        let length = (content as NSString).length
        textView.selectedRange = NSRange(location: min(selected.location, length), length: 0)
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: UIColor(CyberTheme.textPrimary)
        ]
        lineNumbers.refresh()
    }

    private var gutterWidth: CGFloat {
        let lineCount = max(1, (textView.text ?? "").components(separatedBy: "\n").count)
        let digits = String(lineCount).count
        return min(52, max(34, 14 + CGFloat(digits) * 8))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let gutterWidth = self.gutterWidth
        lineNumbers.frame = CGRect(x: 0, y: 0, width: gutterWidth, height: bounds.height)
        textView.frame = CGRect(
            x: gutterWidth,
            y: 0,
            width: max(0, bounds.width - gutterWidth),
            height: bounds.height
        )
    }
}

final class LineNumberGutterView: UIView {
    weak var textView: UITextView?
    var textInsetTop: CGFloat = 10
    var font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular) {
        didSet { setNeedsDisplay() }
    }

    private var observation: NSKeyValueObservation?

    func attach(to textView: UITextView) {
        self.textView = textView
        observation = textView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            self?.setNeedsDisplay()
        }
        setNeedsDisplay()
    }

    func refresh() {
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        UIColor(CyberTheme.background).setFill()
        UIRectFill(rect)

        guard let textView = textView else { return }
        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        guard layoutManager.numberOfGlyphs > 0 else { return }

        let content = textView.text ?? ""
        let nsContent = content as NSString
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let offset = textView.contentOffset.y
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(CyberTheme.textMuted)
        ]

        var lineNumber = 1
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, usedRect, _, range, _ in
            let characterIndex = layoutManager.characterIndexForGlyph(at: range.location)
            let isLineStart = characterIndex == 0
                || (characterIndex > 0
                    && characterIndex <= nsContent.length
                    && nsContent.character(at: characterIndex - 1) == 10)

            if isLineStart {
                let y = usedRect.minY + self.textInsetTop - offset
                if y > -24 && y < self.bounds.height + 4 {
                    let label = "\(lineNumber)" as NSString
                    let size = label.size(withAttributes: attributes)
                    label.draw(
                        at: CGPoint(x: self.bounds.width - size.width - 8, y: y),
                        withAttributes: attributes
                    )
                }
                lineNumber += 1
            }
        }
    }
}
