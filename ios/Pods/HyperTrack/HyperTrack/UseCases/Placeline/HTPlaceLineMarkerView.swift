//
//  HTPlaceLineMarkerView.swift
//  SDKTest
//
//  Created by Atul Manwar on 20/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTPlaceLineMarkerView: UIView {
    fileprivate (set) var textContentView: UIView!
    fileprivate (set) var titleLabel: HTLabel!
    fileprivate (set) var actionInfoView: HTActionInfoView!
    fileprivate var dateView: HTPlaceLineTimeView!
    fileprivate (set) var dividerView: UIView!
    fileprivate (set) var dividerViewWidthConstraint: NSLayoutConstraint!
    fileprivate (set) var dividerViewHeigthConstraint: NSLayoutConstraint!
    fileprivate (set) var dividerViewTopConstraint: NSLayoutConstraint?
    fileprivate (set) var dividerViewBottomConstraint: NSLayoutConstraint?
    
    var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }
    
    var actionDescriptionText: String = "" {
        didSet {
            actionInfoView.titleText = actionDescriptionText
        }
    }
    
    var actionIdDisplayText: String = "" {
        didSet {
            actionInfoView.leftText = actionIdDisplayText
        }
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            dividerView.removeConstraints(dividerView.constraints)
            textContentView.removeConstraints(textContentView.constraints)
            textContentView.addConstraints([
                titleLabel.top(constant: padding.top),
                titleLabel.left(),
                titleLabel.right(),
                titleLabel.bottom(actionInfoView, toAttribute: .top),
                actionInfoView.left(titleLabel),
                actionInfoView.right(titleLabel),
                actionInfoView.bottom(constant: -padding.bottom),
                ])
            dividerViewWidthConstraint = dividerView.width(constant: 12)
            dividerViewHeigthConstraint = dividerView.height(constant: 12)
            dividerView.addConstraints([
                dividerViewWidthConstraint,
                dividerViewHeigthConstraint
                ])
            addConstraints([
                textContentView.top(),
                textContentView.bottom(),
                textContentView.right(relation: .lessThanOrEqual, constant: -padding.right),
                dateView.top(textContentView),
                dateView.bottom(textContentView),
                dividerView.left(constant: padding.left),
                dateView.right(dividerView, toAttribute: .leading, constant: -padding.horizontalInterItem),
                dividerView.centerY(textContentView),
                dividerView.right(textContentView, toAttribute: .leading, constant: -padding.horizontalInterItem),
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
    
    func setTime(_ startTime: String, endTime: String) {
        dividerViewHeigthConstraint.isActive = startTime.isEmpty
        dividerViewTopConstraint?.isActive = !startTime.isEmpty
        dividerViewBottomConstraint?.isActive = !startTime.isEmpty
        if !startTime.isEmpty {
            dividerViewTopConstraint = dividerView.top(textContentView)
            dividerViewBottomConstraint = dividerView.bottom(textContentView)
            addConstraints([
                dividerViewTopConstraint!,
                dividerViewBottomConstraint!,
                ])
        }
        dateView.setTime(startTime, endTime: endTime)
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel = HTLabel(frame: .zero)
        actionInfoView = HTActionInfoView(frame: .zero, padding: HTPaddingProvider(top: 0, left: 0, right: 0, bottom: 0, verticalInterItem: 0, horizontalInterItem: padding.horizontalInterItem))
        dateView = HTPlaceLineTimeView(frame: .zero, padding: HTPaddingProvider(top: 0, left: 0, right: 0, bottom: 0, verticalInterItem: 4, horizontalInterItem: 4))
        dividerView = UIView(frame: .zero)
        textContentView = UIView(frame: .zero)
        textContentView.translatesAutoresizingMaskIntoConstraints = false
        textContentView.addSubview(titleLabel)
        textContentView.addSubview(actionInfoView)
        
        addSubview(dateView)
        addSubview(dividerView)
        addSubview(textContentView)
        self.padding = padding
        actionInfoView.titleLabel.applyStyles([
            .textColor(HTProvider.style.colors.gray),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold))
            ])
        titleLabel.applyStyles([
            .textColor(HTProvider.style.colors.primary),
            .font(HTProvider.style.fonts.getFont(.info, weight: .bold))
            ])
        dividerView.applyBaseStyles([
            .radius(6),
            .background(HTProvider.style.colors.primary)
            ])
    }
    
}

extension HTPlaceLineMarkerView: HTViewProtocol {
}

final class HTPlaceLineMarkerTableViewCell: UITableViewCell {
    fileprivate (set) var markerContentView: HTPlaceLineMarkerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews(padding)
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            markerContentView.padding = padding
        }
    }

    convenience init(style: UITableViewCellStyle, reuseIdentifier: String?, padding: HTPaddingProviderProtocol) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        defer {
            self.padding = padding
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews(padding)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setData(title: String, startTime: String, endTime: String) {
        markerContentView.titleText = title
        markerContentView.setTime(startTime, endTime: endTime)
    }
    
    fileprivate func setupSubviews(_ padding: HTPaddingProviderProtocol) {
        markerContentView = HTPlaceLineMarkerView(frame: .zero, padding: padding)
        contentView.addSubview(markerContentView)
        markerContentView.edges()
        self.padding = padding
        backgroundColor = .clear
        selectionStyle = .none
        separatorInset = .zero
    }
}
