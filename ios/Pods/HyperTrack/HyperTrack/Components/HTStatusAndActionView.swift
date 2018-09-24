//
//  HTStatusAndActionView.swift
//  SDKTest
//
//  Created by Atul Manwar on 14/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTStatusAndActionView: HTStackViewItem {
    fileprivate (set) var titleLabel: HTLabel!
    fileprivate (set) var actionButton: HTButton!
    weak var delegate: HTBottomViewUseCaseDelegate?
    var actionType: HTBottomViewActionData!
    
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
            addConstraints([
                titleLabel.centerY(),
                titleLabel.top(constant: padding.top),
                titleLabel.left(constant: padding.left),
                actionButton.centerY(),
                titleLabel.right(actionButton, toAttribute: .leading, relation: .lessThanOrEqual, constant: -padding.horizontalInterItem),
                actionButton.right(constant: -padding.right),
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
    
    func initialize(_ data: HTUserTrackingBottomCard.Data.Status, delegate: HTBottomViewUseCaseDelegate? = nil) {
        titleText = data.title
        actionButtonText = data.actionText
        actionType = data.actionType
        self.delegate = delegate
    }

    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel = HTLabel(frame: .zero)
        actionButton = HTButton(frame: .zero)
        addSubview(titleLabel)
        addSubview(actionButton)
        self.padding = padding
        titleLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.info, weight: .bold)),
            .textColor(HTProvider.style.colors.secondary)
            ])
        actionButton.applyStyles([
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold)),
            .textColor(HTProvider.style.colors.error),
            .radius(4),
            .background(HTProvider.style.colors.error.withAlphaComponent(0.5))
            ])
        actionButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        applyBaseStyle(.background(HTProvider.style.colors.lightGray))
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        actionButton.imageView?.tintColor = HTProvider.style.colors.positive
        titleLabel.numberOfLines = 2
    }
    
    @objc func buttonClicked() {
        delegate?.actionPerformed(actionType)
    }
}

extension HTStatusAndActionView: HTViewProtocol {
}

