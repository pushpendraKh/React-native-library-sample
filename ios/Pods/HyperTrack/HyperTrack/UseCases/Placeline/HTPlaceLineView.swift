//
//  HTPlaceLineView.swift
//  SDKTest
//
//  Created by Atul Manwar on 19/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTPlaceLineView: UIView {
    fileprivate (set) var activitySegmentView: HTIconTextView!
    fileprivate var stackView: UIStackView!
    fileprivate (set) var verticalDivider: HTBaseView!
    fileprivate (set) var disclosureImageView: UIImageView?
    fileprivate var dividerWidthConstraint: NSLayoutConstraint?
    fileprivate let dividerDefaultWidth: CGFloat = 2
    fileprivate let dividerSelectedWidth: CGFloat = 4
//    var titleText: String = "" {
//        didSet {
//        }
//    }
//
//    var actionDescriptionText: String = "" {
//        didSet {
//        }
//    }
//
//    var actionIdDisplayText: String = "" {
//        didSet {
//        }
//    }
    
    var activityType: HTActivity.ActivityType = .walk {
        didSet {
            if .none == activityType || .stop == activityType {
                activitySegmentView.image = nil
                activitySegmentView.text = ""
            } else {
                activitySegmentView.image = activityType.getPlacelineImage()
                activitySegmentView.imageView.applyBaseStyle(.tintColor(HTProvider.style.colors.gray))
//                activitySegmentView.size = CGSize(width: 20, height: 20)
                activitySegmentView.text = activityType.getName()
                if .unknown == activityType {
                    verticalDivider.backgroundColor = UIColor.clear
                    verticalDivider.dashBorderedColor = HTProvider.style.colors.error
                } else {
                    verticalDivider.backgroundColor = HTProvider.style.colors.primary
                    verticalDivider.dashBorderedColor = nil
                }
                verticalDivider.layoutSubviews()
            }
            switch self.activityType {
            case .unknown:
                return activitySegmentView.textLabel.applyStyles([.textColor(HTProvider.style.colors.error)])
            default:
                return activitySegmentView.textLabel.applyStyles([.textColor(HTProvider.style.colors.gray)])
            }
        }
    }
    
    var activityDescription: String = "" {
        didSet {
            activitySegmentView.descriptionText = activityDescription
        }
    }
    
    var moreInfoAvailable: Bool = false {
        didSet {
            if moreInfoAvailable {
                disclosureImageView?.removeFromSuperview()
                disclosureImageView = UIImageView(image: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.rightArrow))
                disclosureImageView?.translatesAutoresizingMaskIntoConstraints = false
                disclosureImageView?.tintColor = HTProvider.style.colors.primary
                addSubview(disclosureImageView!)
                addConstraints([
                    disclosureImageView!.centerY(stackView),
                    disclosureImageView!.right(toAttribute: .trailing, constant: -padding.right * 2)
                    ])
            } else {
                disclosureImageView?.removeFromSuperview()
            }
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            addConstraints([
                verticalDivider.top(constant: -2),
                verticalDivider.left(constant: padding.left),
                verticalDivider.right(stackView, toAttribute: .leading, constant: -padding.horizontalInterItem),
                verticalDivider.bottom(constant: 2),
                stackView.top(constant: padding.top),
                stackView.centerY(),
                stackView.right(constant: -padding.right),
                ])
            self.moreInfoAvailable = (moreInfoAvailable && true)
        }
    }
    
//    var isNextActivityStop: Bool = false {
//        didSet {
//            markerView.isHidden = isNextActivityStop
//            reDrawView(padding)
//        }
//    }
//
//    var isPreviousActivityStop: Bool = false {
//        didSet {
//            reDrawView(padding)
//        }
//    }
    
//    var isVerticalDividerHidden: Bool = false {
//        didSet {
//            verticalDivider.removeFromSuperview()
//            stackView.removeFromSuperview()
//            if !isVerticalDividerHidden {
//                addSubview(verticalDivider)
//                addSubview(stackView)
//                reDrawView(padding)
//            }
//        }
//    }
    
    fileprivate func reDrawView(_ padding: HTPaddingProviderProtocol) {
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
    
    func setSelected(_ selected: Bool, animated: Bool) {
        if activityType == .unknown {
            verticalDivider.dashBorderedColor = selected ? nil : HTProvider.style.colors.error
        } else {
            verticalDivider.dashBorderedColor = nil
        }
        UIView.animate(withDuration: 0.2) {
            self.verticalDivider.applyBaseStyles([
                .background(selected ? HTProvider.style.colors.brand : (self.activityType == .unknown ? UIColor.clear : HTProvider.style.colors.primary))
                ])
            self.dividerWidthConstraint?.constant = selected ? self.dividerSelectedWidth : self.dividerDefaultWidth
            self.layoutSubviews()
        }
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        activitySegmentView = HTIconTextView(frame: .zero, padding: HTPaddingProvider(top: 20, left: padding.left, right: padding.right, bottom: 20, verticalInterItem: 1, horizontalInterItem: 6))
        stackView = UIStackView(arrangedSubviews: [activitySegmentView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        verticalDivider = HTViewFactory.createVerticalSeparatorView(2, backgroundColor: HTProvider.style.colors.primary)
        verticalDivider.translatesAutoresizingMaskIntoConstraints = false
        verticalDivider.removeConstraints(verticalDivider.constraints)
        dividerWidthConstraint = verticalDivider.width(constant: dividerDefaultWidth)
        verticalDivider.addConstraints([
            dividerWidthConstraint!
            ])
        addSubview(verticalDivider)
        addSubview(stackView)
        let commonStyles: [HTTheme.Style] = [
            .textColor(HTProvider.style.colors.gray),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold))
        ]
        self.padding = padding
        activitySegmentView.textLabel.applyStyles(commonStyles)
        activitySegmentView.descriptionLabel.applyStyles(commonStyles)
    }

}

extension HTPlaceLineView: HTViewProtocol {
}
