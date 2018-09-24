//
//  HTInfoTextView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

final class HTInfoView: UIView {
    fileprivate (set) var titleLabel: HTLabel!
    fileprivate (set) var descriptionLabel: HTLabel!
    fileprivate (set) var moreDetailsLabel: HTLabel!
    
    var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    var descriptionText: String = "" {
        didSet {
            descriptionLabel.text = descriptionText
        }
    }
    
    var moreDetailsText: String = "" {
        didSet {
            moreDetailsLabel.text = moreDetailsText
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            addConstraints([
                titleLabel.top(constant: padding.top),
                titleLabel.left(constant: padding.left),
                titleLabel.bottom(descriptionLabel, toAttribute: .top, constant: -padding.verticalInterItem),
                titleLabel.right(constant: -padding.right),
                descriptionLabel.left(constant: padding.left),
                descriptionLabel.bottom(moreDetailsLabel, toAttribute: .top, constant: -padding.verticalInterItem),
                descriptionLabel.right(constant: -padding.right),
                moreDetailsLabel.left(constant: padding.left),
                moreDetailsLabel.bottom(constant: -padding.bottom),
                moreDetailsLabel.right(constant: -padding.right),
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
        titleLabel = HTLabel(frame: .zero)
        descriptionLabel = HTLabel(frame: .zero)
        moreDetailsLabel = HTLabel(frame: .zero)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(moreDetailsLabel)
        let commonStyles: [HTTheme.Style] = [
            .textColor(HTProvider.style.colors.text),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .regular))
        ]
        self.padding = padding
        titleLabel.applyStyles(commonStyles)
        descriptionLabel.applyStyles([
            .textColor(HTProvider.style.colors.text),
            .font(HTProvider.style.fonts.getFont(.title, weight: .bold))
            ])
        moreDetailsLabel.applyStyles(commonStyles)
    }
}

extension HTInfoView: HTViewProtocol {
}
