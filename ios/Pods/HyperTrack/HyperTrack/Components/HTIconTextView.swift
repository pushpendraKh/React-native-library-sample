//
//  HTIconTextView.swift
//  SDKTest
//
//  Created by Atul Manwar on 13/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

class HTIconTextView: UIView {
    fileprivate (set) var textLabel: HTLabel!
    fileprivate (set) var textContentView: UIView!
    fileprivate (set) var descriptionLabel: HTLabel!

    fileprivate (set) var imageView: UIImageView!
    fileprivate var axis: UILayoutConstraintAxis = .horizontal
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
            if axis == .horizontal {
                textContentView.addConstraints([
                    textLabel.top(),
                    textLabel.left(),
                    textLabel.right(relation: .lessThanOrEqual),
                    textLabel.bottom(descriptionLabel, toAttribute: .top, constant: -padding.verticalInterItem),
                    descriptionLabel.left(),
                    descriptionLabel.right(relation: .lessThanOrEqual),
                    descriptionLabel.bottom(),
                    ])
                addConstraints([
                    imageView.top(constant: padding.top),
                    imageView.centerY(),
                    imageView.left(constant: padding.left),
                    textContentView.centerY(),
                    imageView.right(textContentView, toAttribute: .leading, relation: .lessThanOrEqual, constant: -padding.horizontalInterItem),
                    textContentView.right(constant: -padding.right),
                    ])
            } else {
                textContentView.addConstraints([
                    textLabel.top(),
                    textLabel.left(),
                    textLabel.right(relation: .lessThanOrEqual),
                    textLabel.bottom(),
                    ])
                addConstraints([
                    imageView.top(constant: padding.top),
                    imageView.left(constant: padding.left),
                    imageView.bottom(textContentView, toAttribute: .top, constant: -padding.verticalInterItem),
                    textContentView.left(constant: padding.left),
                    textContentView.right(relation: .lessThanOrEqual, constant: -padding.right),
                    textContentView.bottom(constant: -padding.bottom),
                    ])
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews(padding)
    }
    
    convenience required init(frame: CGRect, padding: HTPaddingProviderProtocol, axis: UILayoutConstraintAxis) {
        self.init(frame: frame)
        self.axis = axis
        defer {
            self.padding = padding
        }
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
            .font(HTProvider.style.fonts.getFont(.caption, weight: .regular)),
            .textColor(HTProvider.style.colors.gray)
            ])
        descriptionLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold)),
            .textColor(HTProvider.style.colors.gray),
            ])
    }
}

extension HTIconTextView: HTViewProtocol {
}

