//
//  EmojiView.swift
//  Streamoji
//
//  Created by Matheus Cardoso on 30/06/20.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import SwiftyGif
import Nuke

internal extension EmojiRendering {
    var gifLevelOfIntegrity: GifLevelOfIntegrity {
        switch quality {
        case .highest: return .highestNoFrameSkipping
        case .high: return .default
        case .medium: return .lowForManyGifs
        case .low: return .lowForTooManyGifs
        case .lowest: return .superLowForSlideShow
        }
    }
}

internal extension PlatformImageView {
    func setFromURL(_ url: URL, rendering: EmojiRendering) {
        Nuke.ImagePipeline.Configuration.isAnimatedImageDataEnabled = true
        Nuke.ImagePipeline.shared.loadImage(with: url) { result in
            switch result {
            case .success(let response):
                if let animation = response.image.animatedImageData,
                   let gifImage = try? PlatformImage(gifData: animation, levelOfIntegrity: rendering.gifLevelOfIntegrity) {
                    DispatchQueue.main.async {
                        self.setGifImage(gifImage)
                        self.startAnimatingGif()
                    }
                } else {
                    #if os(macOS)
                    let wrappedImage = response.image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                    #else
                    let wrappedImage = response.image.cgImage
                    #endif
                    
                    if let image = wrappedImage {
                        DispatchQueue.main.async {
                            #if os(macOS)
                            self.setImage(.init(cgImage: image, size: .zero))
                            #else
                            self.setImage(.init(cgImage: image))
                            #endif
                        }
                    }
                }
            case .failure:
                break
            }
        }
    }
    
    func setFromAsset(_ name: String, rendering: EmojiRendering) {
        DispatchQueue.main.async {
            if let asset = NSDataAsset(name: name),
               let gifImage = try? PlatformImage(gifData: asset.data, levelOfIntegrity: rendering.gifLevelOfIntegrity) {
                    self.setGifImage(gifImage)
                    self.startAnimatingGif()
            } else if let image = PlatformImage(named: name) {
                self.setImage(image)
            }
        }
    }
}


#if os(macOS)

internal final class EmojiView: NSView {
    private let imageView: NSImageView = NSImageView()
    internal let label: NSTextField = NSTextField()

    private var token: NSKeyValueObservation?
    internal func setFromRenderView(_ view: NSImageView) {
        imageView.image = view.image
        token = view.observe(\.image) { [weak self] value, _ in
            self?.imageView.image = view.image
        }
    }

    internal override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
//        imageView.contentMode = .scaleAspectFit
        label.isEditable = false
        label.isBezeled = false
        label.font = .systemFont(ofSize: frame.width/1.1)
        label.maximumNumberOfLines = 0
        addSubview(imageView)
        addSubview(label)
    }
    
    override func layout() {
        super.layout()
        label.frame = self.bounds
        imageView.frame = self.bounds
    }
}

#else

internal final class EmojiView: UIView {
    private let imageView: UIImageView = UIImageView()
    internal let label: UILabel = UILabel()

    private var token: NSKeyValueObservation?
    internal func setFromRenderView(_ view: UIImageView) {
        imageView.image = view.image
        token = view.observe(\.image) { [weak self] value, _ in
            self?.imageView.image = view.image
        }
    }

    internal override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    internal required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        imageView.contentMode = .scaleAspectFit
        label.font = .systemFont(ofSize: frame.width/1.1)
        label.numberOfLines = 0
        addSubview(imageView)
        addSubview(label)
    }

    internal override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = self.bounds
        imageView.frame = self.bounds
    }
}

#endif
