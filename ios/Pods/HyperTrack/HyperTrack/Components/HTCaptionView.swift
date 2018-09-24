//
//  HTCaptionView.swift
//  SDKTest
//
//  Created by Atul Manwar on 13/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTCaptionView: UIView {
    fileprivate (set) var captionLabel: HTLabel!
    
    var caption: String = "" {
        didSet {
            captionLabel.text = caption
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            addConstraints([
                captionLabel.top(constant: padding.top),
                captionLabel.left(constant: padding.left),
                captionLabel.bottom(constant: -padding.bottom),
                captionLabel.right(constant: -padding.right),
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
        captionLabel = HTLabel(frame: .zero)
        addSubview(captionLabel)
        self.padding = padding
        captionLabel.applyStyles([
            .textColor(HTProvider.style.colors.text),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .regular))
            ])
    }
}

extension HTCaptionView: HTViewProtocol {
}
