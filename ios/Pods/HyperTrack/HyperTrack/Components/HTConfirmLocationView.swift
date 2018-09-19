//
//  HTConfirmLocationView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 26/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

protocol HTConfirmLocationDelegate: class {
    func actionPerformed()
}

final class HTConfirmLocationView: UIView {
    fileprivate (set) var titleLabel: HTLabel!
    fileprivate (set) var actionButton: HTButton!
    weak var delegate: HTConfirmLocationDelegate?
    
    var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    var actionButtonText: String = "" {
        didSet {
            actionButton.setTitle(actionButtonText, for: .normal)
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            titleLabel.removeConstraints(titleLabel.constraints)
            titleLabel.addConstraints([
                titleLabel.height(constant: 45)
                ])
            actionButton.removeConstraints(actionButton.constraints)
            actionButton.addConstraints([
                actionButton.height(constant: 45)
                ])
            addConstraints([
                titleLabel.top(constant: padding.top),
                titleLabel.left(constant: padding.left),
                titleLabel.right(constant: -padding.right),
                titleLabel.bottom(actionButton, toAttribute: .top, constant: -padding.verticalInterItem),
                actionButton.left(constant: padding.left),
                actionButton.right(constant: -padding.right),
//                actionButton.centerX(),
                actionButton.bottom(constant: -padding.bottom),
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
        actionButton = HTViewFactory.createPrimaryActionButton("ADD DESTINATION")
        addSubview(titleLabel)
        addSubview(actionButton)
        self.padding = padding
        titleLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.info, weight: .bold)),
            .textColor(HTProvider.style.colors.brand),
            .radius(2),
            ])
        titleLabel.applyBaseStyles([
            .background(HTProvider.style.colors.lightGray),
            ])
//        actionButton.applyStyles([
//            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold)),
//            .textColor(HTProvider.style.colors.error),
//            .radius(4),
//            .background(HTProvider.style.colors.error.withAlphaComponent(0.5))
//            ])
        actionButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 30, bottom: 10, right: 30)
        actionButton.imageView?.tintColor = HTProvider.style.colors.positive
        titleLabel.textAlignment = .center
    }
    
    @objc func buttonClicked() {
        delegate?.actionPerformed()
    }
}

extension HTConfirmLocationView: HTViewProtocol {
}

