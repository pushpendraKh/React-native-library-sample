//
//  HTActivitySummaryView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 23/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

final class HTActivitySummaryView: HTStackViewItem {
    fileprivate (set) var textLabel: HTLabel!
    fileprivate (set) var textContentView: UIView!
    fileprivate (set) var descriptionLabel: HTLabel!
    
    fileprivate (set) var imageView: UIImageView! {
        didSet {
            imageView.tintColor = UIColor.white
        }
    }
    
    var size: CGSize = .zero {
        didSet {
            imageView.removeConstraints(imageView.constraints)
            imageView.addConstraints([
                imageView.width(constant: size.width),
                imageView.height(constant: size.height)
                ])
            layoutSubviews()
        }
    }
    
    var text: String = "" {
        didSet {
            textLabel.text = text
        }
    }
    
    var descriptionText: String = "" {
        didSet {
            descriptionLabel.text = descriptionText
        }
    }
    
    var image: UIImage? = nil {
        didSet {
            imageView.image = image
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            textContentView.removeConstraints(textContentView.constraints)
            textContentView.addConstraints([
                textLabel.top(),
                textLabel.centerX(),
                textLabel.bottom(descriptionLabel, toAttribute: .top, constant: -2),
                descriptionLabel.centerX(),
                descriptionLabel.bottom(),
                ])
            addConstraints([
                imageView.top(constant: padding.top),
                imageView.centerX(),
                textContentView.centerX(),
//                textContentView.right(),
                imageView.bottom(textContentView, toAttribute: .top, constant: -padding.verticalInterItem),
                textContentView.bottom(constant: -padding.bottom),
                ])
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews(padding)
    }
    
    convenience required init(frame: CGRect, padding: HTPaddingProviderProtocol) {
        self.init(frame: frame)
        defer {
            self.padding = padding
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubViews(padding)
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textLabel = HTLabel(frame: .zero)
        descriptionLabel = HTLabel(frame: .zero)
        textContentView = UIView(frame: .zero)
        textContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        addSubview(textContentView)
        textContentView.addSubview(textLabel)
        textContentView.addSubview(descriptionLabel)
        self.padding = padding
        textLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold)),
            .textColor(HTProvider.style.colors.gray)
            ])
        descriptionLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.info, weight: .bold)),
            .textColor(HTProvider.style.colors.secondary),
            ])
        textLabel.textAlignment = .center
        descriptionLabel.textAlignment = .center
    }
}

