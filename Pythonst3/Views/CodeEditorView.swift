import SwiftUI
import UIKit

struct CodeEditorView: UIViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var onCursorChange: (Int, Int) -> Void = { _, _ in }
    var onRun: () -> Void = {}
    var onMessage: (String) -> Void = { _ in }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> CodeEditorContainerView {
        let view = CodeEditorContainerView()
        view.textView.delegate = context.coordinator
        view.configure(fontSize: fontSize)
        view.onRun = onRun
        view.onMessage = onMessage
        view.setText(text)
        context.coordinator.container = view
        return view
    }

    func updateUIView(_ uiView: CodeEditorContainerView, context: Context) {
        context.coordinator.parent = self
        uiView.onRun = onRun
        uiView.onMessage = onMessage
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
            container?.refreshChrome()
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
    private let placeholderLabel = UILabel()
    private let accessoryBar = EditorAccessoryBar(
        frame: CGRect(x: 0, y: 0, width: 320, height: 44)
    )
    private var font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    var onRun: (() -> Void)?
    var onMessage: ((String) -> Void)?

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

        accessoryBar.onPaste = { [weak self] in self?.pasteFromClipboard() }
        accessoryBar.onTab = { [weak self] in self?.insertTab() }
        accessoryBar.onUndo = { [weak self] in self?.textView.undoManager?.undo() }
        accessoryBar.onRedo = { [weak self] in self?.textView.undoManager?.redo() }
        accessoryBar.onDismiss = { [weak self] in self?.textView.resignFirstResponder() }
        accessoryBar.onRun = { [weak self] in
            self?.textView.resignFirstResponder()
            self?.onRun?()
        }
        textView.inputAccessoryView = accessoryBar

        placeholderLabel.text = "اكتب أو الصق كود Python هنا"
        placeholderLabel.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        placeholderLabel.textColor = UIColor(CyberTheme.textMuted)
        placeholderLabel.numberOfLines = 0
        placeholderLabel.semanticContentAttribute = .forceRightToLeft
        placeholderLabel.textAlignment = .right
        placeholderLabel.isUserInteractionEnabled = false
        placeholderLabel.isAccessibilityElement = false

        addSubview(lineNumbers)
        addSubview(textView)
        addSubview(placeholderLabel)
        lineNumbers.attach(to: textView)
        refreshChrome()
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
        refreshChrome()
    }

    func refreshChrome() {
        placeholderLabel.isHidden = !(textView.text ?? "").isEmpty
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
        refreshChrome()
    }

    // MARK: - Actions

    @objc private func pasteFromClipboard() {
        guard let clipboard = UIPasteboard.general.string,
              !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onMessage?("الحافظة فارغة — انسخ كود Python أولاً.")
            return
        }
        if !textView.isFirstResponder {
            textView.becomeFirstResponder()
        }
        let target = textView.selectedTextRange
            ?? textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        guard let target else { return }
        textView.replace(target, withText: clipboard)
        textView.delegate?.textViewDidChange?(textView)
    }

    @objc private func insertTab() {
        guard textView.isEditable else { return }
        textView.insertText("    ")
        textView.delegate?.textViewDidChange?(textView)
    }

    // MARK: - Layout

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
        let placeholderWidth = max(0, bounds.width - gutterWidth - 20)
        placeholderLabel.frame = CGRect(
            x: gutterWidth + 8,
            y: 10,
            width: placeholderWidth,
            height: 44
        )
    }
}

/// Keyboard accessory that makes the two core actions impossible to miss:
/// paste the clipboard, then run. The rest are conveniences.
final class EditorAccessoryBar: UIToolbar {
    var onPaste: (() -> Void)?
    var onRun: (() -> Void)?
    var onTab: (() -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onDismiss: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(CyberTheme.surface)
        standardAppearance = appearance
        compactAppearance = appearance
        tintColor = UIColor(CyberTheme.neonGreen)
        semanticContentAttribute = .forceRightToLeft
        autoresizingMask = .flexibleWidth

        let paste = item(title: "لصق", action: #selector(pasteTapped))
        paste.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 13, weight: .semibold)],
            for: .normal
        )
        let tab = item(title: "Tab", action: #selector(tabTapped))
        let undo = item(image: "arrow.uturn.backward", action: #selector(undoTapped))
        let redo = item(image: "arrow.uturn.forward", action: #selector(redoTapped))
        let run = item(title: "▶ تشغيل", action: #selector(runTapped))
        run.style = .done
        run.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 13, weight: .bold)],
            for: .normal
        )
        let hide = item(image: "keyboard.chevron.compact.down", action: #selector(dismissTapped))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        items = [paste, tab, undo, redo, spacer, run, hide]
        sizeToFit()
    }

    private func item(title: String, action: Selector) -> UIBarButtonItem {
        let item = UIBarButtonItem(title: title, style: .plain, target: self, action: action)
        item.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 13, weight: .medium)],
            for: .normal
        )
        return item
    }

    private func item(image: String, action: Selector) -> UIBarButtonItem {
        UIBarButtonItem(
            image: UIImage(systemName: image),
            style: .plain,
            target: self,
            action: action
        )
    }

    @objc private func pasteTapped() { onPaste?() }
    @objc private func tabTapped() { onTab?() }
    @objc private func undoTapped() { onUndo?() }
    @objc private func redoTapped() { onRedo?() }
    @objc private func runTapped() { onRun?() }
    @objc private func dismissTapped() { onDismiss?() }
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
