//
//  HTPlaceLineTimeView.swift
//  SDKTest
//
//  Created by Atul Manwar on 20/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTPlaceLineTimeView: UIView {
    fileprivate (set) var fromDateLabel: HTLabel? {
        didSet {
            fromDateLabel?.textAlignment = .right
        }
    }
    fileprivate (set) var toDateLabel: HTLabel! {
        didSet {
            toDateLabel.textAlignment = .right
        }
    }
    fileprivate var separator: UIView?
    fileprivate var toDateLabelBottomConstraint: NSLayoutConstraint?
    
    func setTime(_ startTime: String, endTime: String) {
        toDateLabel.text = endTime
        if startTime.isEmpty {
            fromDateLabel?.removeFromSuperview()
            separator?.removeFromSuperview()
            fromDateLabel = nil
            separator = nil
        } else {
            guard fromDateLabel == nil else {
                fromDateLabel?.text = startTime
                return
            }
            separator = HTViewFactory.createVerticalSeparatorView(1, backgroundColor: HTProvider.style.colors.gray)
            separator?.translatesAutoresizingMaskIntoConstraints = false
            addSubview(separator!)
            fromDateLabel = HTLabel(frame: .zero)
            addSubview(fromDateLabel!)
            fromDateLabel?.text = startTime
            fromDateLabel?.applyStyles([
                .textColor(HTProvider.style.colors.gray),
                .font(HTProvider.style.fonts.getFont(.caption, weight: .bold))
                ])
            toDateLabelBottomConstraint?.isActive = false
            addConstraints([
                separator!.top(toDateLabel, toAttribute: .bottom, constant: 1),
                separator!.bottom(fromDateLabel, toAttribute: .top, constant: -1),
                separator!.centerX(self),
                fromDateLabel!.left(toDateLabel),
                fromDateLabel!.right(toDateLabel),
                fromDateLabel!.bottom(constant: -padding.bottom)
                ])
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            toDateLabelBottomConstraint = toDateLabel.bottom()
            addConstraints([
                toDateLabel.top(),
                toDateLabel.left(),
                toDateLabel.right(),
                toDateLabelBottomConstraint!
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
    
    fileprivate func updateStackView() {
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        toDateLabel = HTLabel(frame: .zero)
        addSubview(toDateLabel)
        self.padding = padding
        toDateLabel.applyStyles([
            .textColor(HTProvider.style.colors.gray),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold))
            ])
    }
}

extension HTPlaceLineTimeView: HTViewProtocol {
}

