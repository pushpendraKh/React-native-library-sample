//
//  HTUserInfoView.swift
//  SDKTest
//
//  Created by Atul Manwar on 14/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

public class HTUserInfoView: HTStackViewItem {
    public private (set) var imageView: UIImageView!
    fileprivate var textContentView: UIView!
    public private (set) var titleLabel: HTLabel!
    public private (set) var descriptionLabel: HTLabel!
    public private (set) var actionButton: HTButton!
    fileprivate var imageWidthConstraint: NSLayoutConstraint!
    fileprivate var imageHeightConstraint: NSLayoutConstraint!
    weak var delegate: HTBottomViewUseCaseDelegate?
    
    public var actionType: HTBottomViewActionData!

    var imageSize: CGSize = CGSize(width: 50, height: 50) {
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
    
    public var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    public var descriptionText: String = "" {
        didSet {
            descriptionLabel.text = descriptionText
        }
    }
    
    public var image: UIImage? = nil {
        didSet {
            imageView.image = image
        }
    }
    
    public var imageUrl: String? = nil {
        didSet {
            if let url = imageUrl {
                HTDownloadManager.instance.downloadImage(urlString: url, completionHandler: { [weak self] (image) in
                    self?.image = image
                })
            } else {
                image = nil
            }
        }
    }
    
    public var actionButtonText: String = "" {
        didSet {
            actionButton.setTitle(actionButtonText, for: .normal)
        }
    }
    
    var actionButtonImage: UIImage? = nil {
        didSet {
            actionButton.setImage(actionButtonImage, for: .normal)
        }
    }
    
    public var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            imageView.removeConstraints(imageView.constraints)
            removeConstraints(constraints)
            textContentView.removeConstraints(textContentView.constraints)
            imageWidthConstraint = imageView.width(constant: imageSize.width)
            imageHeightConstraint = imageView.height(constant: imageSize.height)
            imageView.addConstraints([
                imageWidthConstraint,
                imageHeightConstraint,
                ])
            textContentView.addConstraints([
                titleLabel.top(),
                titleLabel.left(),
                titleLabel.right(),
                titleLabel.bottom(descriptionLabel, toAttribute: .top, constant: -padding.verticalInterItem),
                descriptionLabel.left(),
                descriptionLabel.right(),
                descriptionLabel.bottom(),
                ])
            addConstraints([
                imageView.centerY(),
                textContentView.top(constant: padding.top),
                imageView.left(constant: padding.left),
                imageView.right(textContentView, toAttribute: .leading, constant: -padding.horizontalInterItem),
                textContentView.centerY(),
                textContentView.right(actionButton, relation: .lessThanOrEqual, constant: -padding.horizontalInterItem),
                actionButton.right(relation: .lessThanOrEqual, constant: -padding.right),
                actionButton.centerY(),
                ])
            actionButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -padding.horizontalInterItem, bottom: 0, right: 0)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews(padding)
    }
    
    public convenience required init(frame: CGRect, padding: HTPaddingProviderProtocol) {
        self.init(frame: frame)
        defer {
            self.padding = padding
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubViews(padding)
    }
    
    public func initialize(_ data: HTUserTrackingBottomCard.Data.UserCard, delegate: HTBottomViewUseCaseDelegate? = nil) {
        titleText = data.title
        descriptionText = data.description
        actionButtonText = data.actionText
        imageUrl = data.imageUrl
        actionButtonImage = data.actionImage
        actionType = data.actionType
        self.delegate = delegate
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = imageSize.height/2
        imageView.applyBaseStyles([
            .background(HTProvider.style.colors.lightGray)
            ])
        titleLabel = HTLabel(frame: .zero)
        descriptionLabel = HTLabel(frame: .zero)
        actionButton = HTButton(frame: .zero)
        actionButton.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        textContentView = UIView(frame: .zero)
        textContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        addSubview(textContentView)
        textContentView.addSubview(titleLabel)
        textContentView.addSubview(descriptionLabel)
        addSubview(actionButton)
        self.padding = padding
        titleLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.title, weight: .bold)),
            .textColor(HTProvider.style.colors.default),
            ])
        descriptionLabel.applyStyles([
            .font(HTProvider.style.fonts.getFont(.caption, weight: .regular)),
            .textColor(HTProvider.style.colors.gray),
            ])
        actionButton.applyStyles([
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold)),
            .textColor(HTProvider.style.colors.positive),
            ])
        actionButton.imageView?.tintColor = HTProvider.style.colors.positive
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 15, left: 5, bottom: 15, right: 5)
    }
    
    @objc func buttonClicked() {
        delegate?.actionPerformed(actionType)
    }
}

extension HTUserInfoView: HTViewProtocol {
}

