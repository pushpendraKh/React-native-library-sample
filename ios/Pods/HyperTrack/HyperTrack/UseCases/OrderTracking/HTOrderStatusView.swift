//
//  HTOrderStatusView.swift
//  SDKTest
//
//  Created by Atul Manwar on 14/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTOrderStatusView: HTStackViewItem {
    fileprivate (set) var textLabel: HTLabel!
    fileprivate (set) var imageView: UIImageView!
    fileprivate var leftPaddingView: UIView!
    fileprivate var rightPaddingView: UIView!
    
    var text: String = "" {
        didSet {
            textLabel.text = text
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
            addConstraints([
                leftPaddingView.centerY(),
                leftPaddingView.left(constant: padding.left),
                leftPaddingView.right(imageView, toAttribute: .leading, relation: .equal),
                imageView.centerY(),
                imageView.right(textLabel, toAttribute: .leading, relation: .equal, constant: -padding.horizontalInterItem),
                textLabel.top(constant: padding.top),
                textLabel.right(rightPaddingView, toAttribute: .leading),
                textLabel.centerY(),
                rightPaddingView.right(constant: -padding.right),
                leftPaddingView.width(rightPaddingView),
                ])
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews(padding)
    }
    
    convenience init(frame: CGRect, padding: HTPaddingProviderProtocol) {
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
        leftPaddingView = UIView(frame: .zero)
        rightPaddingView = UIView(frame: .zero)
        addSubview(leftPaddingView)
        addSubview(imageView)
        addSubview(textLabel)
        addSubview(rightPaddingView)
        self.padding = padding
        textLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.title, weight: .bold)),
            .textColor(HTProvider.style.colors.default)
            ])
    }
}

extension HTOrderStatusView: HTViewProtocol {
}
