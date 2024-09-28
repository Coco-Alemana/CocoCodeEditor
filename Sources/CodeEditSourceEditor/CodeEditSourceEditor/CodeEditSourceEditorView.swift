//
//  Untitled.swift
//  CodeEditSourceEditor
//
//  Created by Daniel Caminos on 9/27/24.
//

import AppKit
import SwiftUI
import CodeEditSourceEditor
import CodeEditTextView
import CodeEditLanguages

public class CodeEditSourceEditorView: NSView {
    var string: Binding<String>
    var cursorPositions: Binding<[CursorPosition]>
    private var textViewController: TextViewController!

    public init(
        string: Binding<String>,
        language: CodeLanguage,
        theme: EditorTheme,
        font: NSFont,
        tabWidth: Int,
        indentOption: IndentOption = .spaces(count: 4),
        lineHeight: Double,
        wrapLines: Bool,
        editorOverscroll: CGFloat = 0,
        cursorPositions: Binding<[CursorPosition]>,
        useThemeBackground: Bool = true,
        highlightProvider: HighlightProviding? = nil,
        contentInsets: NSEdgeInsets? = nil,
        isEditable: Bool = true,
        isSelectable: Bool = true,
        letterSpacing: Double = 1.0,
        bracketPairHighlight: BracketPairHighlight? = nil,
        useSystemCursor: Bool = true,
        undoManager: CEUndoManager? = nil,
        coordinators: [any TextViewCoordinator] = []
    ) {
        self.string = string
        self.cursorPositions = cursorPositions
        super.init(frame: .zero)
        // Initialize the TextViewController
        textViewController = TextViewController(
            string: string.wrappedValue,
            language: language,
            font: font,
            theme: theme,
            tabWidth: tabWidth,
            indentOption: indentOption,
            lineHeight: lineHeight,
            wrapLines: wrapLines,
            cursorPositions: cursorPositions.wrappedValue,
            editorOverscroll: editorOverscroll,
            useThemeBackground: useThemeBackground,
            highlightProvider: highlightProvider,
            contentInsets: contentInsets,
            isEditable: isEditable,
            isSelectable: isSelectable,
            letterSpacing: letterSpacing,
            useSystemCursor: useSystemCursor,
            bracketPairHighlight: bracketPairHighlight
        )
        // Add the TextViewController's view to this NSView
        self.addSubview(textViewController.view)
        // Ensure the TextViewController's view takes up the entire parent NSView
        textViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textViewController.view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            textViewController.view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            textViewController.view.topAnchor.constraint(equalTo: self.topAnchor),
            textViewController.view.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChangeText(_:)),
            name: TextView.textDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textControllerCursorsDidUpdate(_:)),
            name: TextViewController.cursorPositionUpdatedNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func mouseDown(with event: NSEvent) {
        makeFirstResponder()
    }

    public override func mouseUp(with event: NSEvent) {
        makeFirstResponder()
    }

    public func focus() {
        self.textViewController.updateCursorPosition()
        self.textViewController.setCursorPositions([CursorPosition(line: 1, column: 1)])
        makeFirstResponder()
    }

    public func makeFirstResponder() {
        if let window = textViewController.view.window {
            if window.makeFirstResponder(textViewController.textView) {
                _ = textViewController.textView.becomeFirstResponder()
            }
        }
    }

    @objc func textViewDidChangeText(_ notification: Notification) {
        guard let textView = notification.object as? TextView,
              let textViewController,
              textViewController.textView === textView else {
            return
        }

        string.wrappedValue = textView.string
        self.textViewController.highlighter?.invalidate()
    }

    @objc func textControllerCursorsDidUpdate(_ notification: Notification) {
        guard let notificationController = notification.object as? TextViewController,
              notificationController === textViewController else {
            return
        }
        cursorPositions.wrappedValue = notificationController.cursorPositions
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
