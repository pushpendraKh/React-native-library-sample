//
//  HTActivitySummaryContainerView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 23/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

final class HTActivitySummaryContainerView: UIView {
    fileprivate (set) var infoView: HTInfoView!
//    fileprivate (set) var separatorView: HTBaseView!
    fileprivate (set) var headerView: HTActivitySummaryHeaderView!
    fileprivate (set) var actionButton: HTButton!
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            addConstraints([
                infoView.top(constant: padding.top),
                infoView.left(constant: padding.left),
                infoView.right(constant: -padding.right),
                infoView.bottom(headerView, toAttribute: .top, constant: -padding.verticalInterItem),
                headerView.left(constant: padding.left),
                headerView.right(constant: -padding.right),
                headerView.bottom(actionButton, toAttribute: .top, constant: -padding.verticalInterItem),
                headerView.centerX(),
                actionButton.centerX(),
                actionButton.bottom(constant: -padding.bottom),
                actionButton.height(constant: 35)
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
        infoView = HTInfoView(frame: .zero, padding: HTPaddingProvider(top: 0, left: 0, right: 0, bottom: 0, verticalInterItem: padding.verticalInterItem, horizontalInterItem: padding.horizontalInterItem))
        headerView = HTActivitySummaryHeaderView(frame: .zero, padding: HTPaddingProvider(top: 20, left: 0, right: 0, bottom: 20, verticalInterItem: 0, horizontalInterItem: 0))
        actionButton = HTButton(frame: .zero)
        actionButton.applyStyles([
            .textColor(HTProvider.style.colors.primary),
            .radius(HTProvider.style.layer.cornerRadius),
            .font(HTProvider.style.fonts.getFont(.info, weight: .bold))
            ])
        actionButton.setTitle("See your Placeline", for: .normal)
        actionButton.layer.borderWidth = HTProvider.style.layer.borderWidth
        actionButton.layer.borderColor = HTProvider.style.colors.primary.cgColor
        addSubview(headerView)
        addSubview(infoView)
        addSubview(actionButton)
        self.padding = padding
        infoView.titleLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.normal, weight: .regular)),
            .textColor(HTProvider.style.colors.secondary)
            ])
        infoView.descriptionLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.normal, weight: .bold)),
            .textColor(HTProvider.style.colors.default),
            ])
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 30, bottom: 5, right: 30)
    }
    
    func setPlaceline(_ placeline: HTPlaceline) {
        infoView.titleText = "Howdy \(placeline.name ?? "")"
        infoView.descriptionText = "Your day at a glance"
        headerView.setSummaryInfo(placeline.activitySummary)
    }
}

 extension HTActivitySummaryContainerView: HTViewProtocol {
}
