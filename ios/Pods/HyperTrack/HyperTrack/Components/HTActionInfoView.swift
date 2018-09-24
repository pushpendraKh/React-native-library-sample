//
//  HTActionInfoView.swift
//  SDKTest
//
//  Created by Atul Manwar on 19/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTActionInfoView: UIView {
    fileprivate (set) var titleLabel: HTLabel!
    fileprivate (set) var leftLabel: HTLabel!
    
    var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    var leftText: String = "" {
        didSet {
            leftLabel.text = leftText
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            addConstraints([
                leftLabel.top(constant: padding.top),
                leftLabel.left(constant: padding.left),
                leftLabel.centerY(),
                leftLabel.right(titleLabel, toAttribute: .leading, constant: -padding.horizontalInterItem),
                titleLabel.centerY(),
                titleLabel.right(relation: .lessThanOrEqual, constant: -padding.right),
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
        leftLabel = HTLabel(frame: .zero)
        addSubview(leftLabel)
        addSubview(titleLabel)
        let commonStyles: [HTTheme.Style] = [
            .textColor(HTProvider.style.colors.gray),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold))
        ]
        self.padding = padding
        titleLabel.applyStyles(commonStyles)
        leftLabel.applyStyles(commonStyles)
        leftLabel.applyStyles([
            .background(HTProvider.style.colors.positive),
            .textColor(HTProvider.style.colors.text),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold))
            ])
    }
}

extension HTActionInfoView: HTViewProtocol {
}
