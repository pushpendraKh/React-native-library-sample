//
//  HTCalloutView.swift
//  SDKTest
//
//  Created by Atul Manwar on 12/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

public class HTCalloutView: UIStackView {
    fileprivate (set) var disclosureImageView: UIImageView?
    public var data: HTCallout? = nil {
        didSet {
            arrangedSubviews.forEach({ removeArrangedSubview($0) })
            guard let data = data else {
                return
            }
            axis = data.metaData.axis
            createCalloutComponents(data: data, moreInfoAvailable: data.metaData.moreInfoAvailable).enumerated().forEach({
//                if $0.offset >= 1 && data.metaData.moreInfoAvailable {
//
//                }
                addArrangedSubview($0.element)
            })
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public convenience init(arrangedSubviews views: [UIView], metaData: HTCallout.MetaData) {
        self.init(arrangedSubviews: views)
        translatesAutoresizingMaskIntoConstraints = false
        views.forEach({
            addArrangedSubview($0)
            setMetadata(metaData: metaData, view: $0)
        })
        addConstraints([
            width(relation: .lessThanOrEqual, constant: UIScreen.main.bounds.width*0.5)
            ])
        showMoreInfo(metaData.moreInfoAvailable)
        self.axis = metaData.axis
    }
    
    fileprivate func showMoreInfo(_ show: Bool) {
        if show {
            disclosureImageView = UIImageView(image: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.rightArrow))
            disclosureImageView?.translatesAutoresizingMaskIntoConstraints = false
            disclosureImageView?.tintColor = UIColor.white
            addSubview(disclosureImageView!)
            addConstraints([
                disclosureImageView!.centerY(constant: 0),
                disclosureImageView!.left(toAttribute: .trailing, constant: -25)
                ])
        } else {
            disclosureImageView?.removeFromSuperview()
        }
    }
    
    fileprivate func setMetadata(metaData: HTCallout.MetaData, view: UIView) {
        switch metaData.type {
        case .currentUser:
            view.applyBaseStyles([
                .background(HTProvider.style.colors.brand)
                ])
        case .user: fallthrough
        case .destination:
            view.applyBaseStyles([
                .background(HTProvider.style.colors.primary)
                ])
        case .error:
            view.applyBaseStyles([
                .background(HTProvider.style.colors.error)
                ])
        case .none:
            break
        }

    }
    
    fileprivate func createCalloutComponent(type: HTBasicComponentProtocol, padding: HTPaddingProviderProtocol) -> UIView {
        if let data = type as? HTCallout.Data.InfoText {
            let infoView = HTInfoView(frame: .zero, padding: padding)
            infoView.titleText = data.title
            infoView.descriptionText = data.description
            infoView.moreDetailsText = data.moreDetails
            return infoView
        } else if let data = type as? HTCallout.Data.IconText {
            let iconView = HTIconTextView(frame: .zero, padding: padding, axis: data.axis)
            iconView.image = data.image
            iconView.text = data.title
            if data.axis == .vertical {
                iconView.textLabel.applyStyles([
                    .font(HTProvider.style.fonts.getFont(.title, weight: .bold)),
                    .textColor(HTProvider.style.colors.text)
                    ])
            }
            return iconView
        } else if let data = type as? HTCallout.Data.CaptionText {
            let captionView = HTCaptionView(frame: .zero, padding: padding)
            captionView.caption = data.title
            return captionView
        } else if let data = type as? HTCallout.Data.InfoArray {
            let metaData = HTCallout.MetaData(axis: .horizontal, type: self.data?.metaData.type ?? .none, moreInfoAvailable: false)
            return HTCalloutView(arrangedSubviews: data.values.enumerated().map({
                var internalPadding = padding
                if $0 < data.values.count - 1 {
                    internalPadding.right = 0
                } else if data.values.count > 1 {
                    internalPadding.left = 20
                }
                return createCalloutComponent(type: $1, padding: internalPadding)
            }), metaData: metaData)
        } else {
            return UIView()
        }
    }
    
    fileprivate func createCalloutComponents(data: HTCallout, moreInfoAvailable: Bool) -> [UIView] {
        return data.components.enumerated().map({
            var padding = HTPaddingProvider.default
            if $0 < data.components.count - 1 {
                padding.bottom = 0
            } else if data.components.count > 1 {
                padding.top = 0
            }
            if moreInfoAvailable {
                padding.right += 15
            }
            let view = createCalloutComponent(type: $1, padding: padding)
            showMoreInfo(data.metaData.moreInfoAvailable)
            setMetadata(metaData: data.metaData, view: view)
            return view
        })
    }
}
