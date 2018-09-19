//
//  HTErrorStatusView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 06/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

class HTErrorStatusView: UIView {
    fileprivate (set) var imageView: UIImageView!
    fileprivate (set) var actionView: HTStatusAndActionView!
    fileprivate var imageWidthConstraint: NSLayoutConstraint!
    fileprivate var imageHeightConstraint: NSLayoutConstraint!

    var imageSize: CGSize = CGSize(width: 25, height: 25) {
        didSet {
            imageWidthConstraint.constant = imageSize.width
            imageHeightConstraint.constant = imageSize.height
            if imageSize.width == imageSize.height {
                imageView.layer.cornerRadius = imageSize.height/2
            } else {
                imageView.layer.cornerRadius = 0
            }
            imageView.isHidden = (imageSize.width == 0 || imageSize.height == 0)
        }
    }
    
    var titleText: String = "" {
        didSet {
            actionView.titleText = titleText
        }
    }
    
    var image: UIImage? = nil {
        didSet {
            imageView.image = image
        }
    }
    
    var actionButtonText: String = "" {
        didSet {
            actionView.actionButton.setTitle(actionButtonText, for: .normal)
        }
    }
    
    var actionButtonImage: UIImage? = nil {
        didSet {
            actionView.actionButton.setImage(actionButtonImage, for: .normal)
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            imageView.removeConstraints(imageView.constraints)
            removeConstraints(constraints)
            imageWidthConstraint = imageView.width(constant: imageSize.width)
            imageHeightConstraint = imageView.height(constant: imageSize.height)
            imageView.addConstraints([
                imageWidthConstraint,
                imageHeightConstraint,
                ])
            addConstraints([
                imageView.centerY(),
                imageView.left(constant: padding.left),
                imageView.right(actionView, toAttribute: .leading, constant: -padding.horizontalInterItem),
                actionView.top(constant: padding.top),
                actionView.bottom(constant: -padding.bottom),
                actionView.right(constant: -padding.right),
                ])
            actionView.actionButton.addConstraints([
                actionView.actionButton.width(constant: 65),
                ])
        }
    }
    
    fileprivate var showView: Bool = false {
        didSet {
            if showView {
                alpha = 0
                UIView.animate(withDuration: HTProvider.animationDuration) {
                    self.alpha = 1
                }
            } else {
                UIView.animate(withDuration: HTProvider.animationDuration, animations: {
                    self.alpha = 0
                }, completion: { (_) in
                    self.removeFromSuperview()
                })
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews(HTPaddingProvider(top: 15, left: 15, right: 15, bottom: 15, verticalInterItem: 1, horizontalInterItem: 5))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews(HTPaddingProvider(top: 15, left: 15, right: 15, bottom: 15, verticalInterItem: 1, horizontalInterItem: 5))
    }
    
    convenience init(text: String, showIn: UIView, anchor: AnchorPosition = .top, padding: CGFloat = 30, automaticallyDismiss: Bool = false) {
        self.init(frame: .zero)
        showIn.addSubview(self)
        pinView(showIn, anchor: anchor, padding: padding)
        actionView.titleText = text
        showView = true
        if automaticallyDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                self.showView = false
            })
        }
    }
    
    fileprivate func pinView(_ superView: UIView, anchor: AnchorPosition, padding: CGFloat) {
        switch anchor {
        case .bottom:
            superView.addConstraints([
                centerX(constant: 0),
                left(toAttribute: .leading, constant: padding),
                right(toAttribute: .trailing, constant: -padding),
                bottom(constant: -padding)
                ])
        default:
            superView.addConstraints([
                centerX(constant: 0),
                left(toAttribute: .leading, constant: padding),
                right(toAttribute: .trailing, constant: -padding),
                top(constant: padding)
                ])
        }
    }
    
    fileprivate func setupSubviews(_ padding: HTPaddingProviderProtocol) {
        actionView = HTStatusAndActionView(frame: .zero, padding: HTPaddingProvider(top: 0, left: 0, right: 0, bottom: 0, verticalInterItem: padding.verticalInterItem, horizontalInterItem: padding.horizontalInterItem))
        imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(actionView)
        addSubview(imageView)
        applyBaseStyles([
            .background(HTProvider.style.colors.error),
            .radius(2)
            ])
        actionView.actionButton.applyStyles([
            .background(HTProvider.style.colors.errorDark),
            .textColor(HTProvider.style.colors.text)
            ])
        actionView.titleLabel.applyStyles([
            .textColor(HTProvider.style.colors.text)
            ])
        image = UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.errorIcon)
        actionButtonText = "DISMISS"
        self.padding = padding
        actionView.actionButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        actionView.applyBaseStyles([
            .background(HTProvider.style.colors.error),
            ])
        actionView.titleLabel.numberOfLines = 3
    }
    
    @objc func buttonClicked() {
        showView = false
    }
}
