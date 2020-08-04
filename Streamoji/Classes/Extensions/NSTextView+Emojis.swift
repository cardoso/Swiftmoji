//
//  UITextView+Emojis.swift
//  Streamoji
//
//  Created by Matheus Cardoso on 30/06/20.
//

#if os(macOS)

import AppKit

fileprivate var renderViews: [EmojiSource: NSImageView] = [:]


// MARK: Public
extension NSTextView {
    /// Configures this UITextView to display custom emojis.
    ///
    /// - Parameter emojis: A dictionary of emoji keyed by its shortcode.
    /// - Parameter rendering: The rendering options. Defaults to `.highQuality`.
    public func configureEmojis(_ emojis: [String: EmojiSource], rendering: EmojiRendering = .highQuality) {
        self.applyEmojis(emojis, rendering: rendering)

        NotificationCenter.default.addObserver(
            forName: NSText.didChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            self?.applyEmojis(emojis, rendering: rendering)
        }
    }
}

// MARK: Private
extension NSTextView {
    private var textContainerView: NSView { self }
    
    private var customEmojiViews: [EmojiView] {
        textContainerView.subviews.compactMap { $0 as? EmojiView }
    }
    
    private func applyEmojis(_ emojis: [String: EmojiSource], rendering: EmojiRendering) {
        let range = selectedRange
        let count = attributedString().string.count
        textStorage?.setAttributedString(attributedString().insertingEmojis(emojis, rendering: rendering))
        let newCount = attributedString().string.count
        customEmojiViews.forEach { $0.removeFromSuperview() }
        addEmojiImagesIfNeeded(rendering: rendering)
        selectedRange = NSRange(location: range.location - (count - newCount), length: range.length)
    }
    
    private func addEmojiImagesIfNeeded(rendering: EmojiRendering) {
        attributedString().enumerateAttributes(in: NSRange(location: 0, length: attributedString().length), options: [], using: { attributes, crange, _ in
            DispatchQueue.main.async {
                guard
                    let emojiAttachment = attributes[NSAttributedString.Key.attachment] as? EmojiTextAttachment,
                    let emojiData = emojiAttachment.emojiData,
                    let emoji = try? JSONDecoder().decode(EmojiSource.self, from: emojiData),
                    let layoutManager = self.layoutManager, let textContainer = self.textContainer
                else {
                    return
                }
                
                let glyphRange = layoutManager.glyphRange(forCharacterRange: crange, actualCharacterRange: nil)
                var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                
                rect.origin.x -= emojiAttachment.bounds.origin.x
                rect.origin.y -= emojiAttachment.bounds.origin.y
                rect.size = emojiAttachment.bounds.size
                
                let emojiView = EmojiView(frame: rect)
                emojiView.layer?.backgroundColor = self.backgroundColor.cgColor
                
                switch emoji {
                case let .character(character):
                    emojiView.label.stringValue = character
                case let .imageUrl(imageUrl):
                    guard renderViews[emoji] == nil else {
                        break
                    }
                    
                    if let url = URL(string: imageUrl) {
                        let renderView = NSImageView(frame: rect)
                        renderView.setFromURL(url, rendering: rendering)
                        renderViews[emoji] = renderView
                        self.textContainerView.addSubview(renderView)
                        renderView.alphaValue = 0
                    }
                case let .imageAsset(imageAsset):
                    guard renderViews[emoji] == nil else {
                        break
                    }
                    
                    let renderView = NSImageView(frame: rect)
                    renderView.setFromAsset(imageAsset, rendering: rendering)
                    renderViews[emoji] = renderView
                    self.textContainerView.addSubview(renderView)
                    renderView.alphaValue = 0
                case .alias:
                    break
                }
                
                if let view = renderViews[emoji] {
                    emojiView.setFromRenderView(view)
                }
                
                self.textContainerView.addSubview(emojiView)
            }
        })
    }
}

#endif
