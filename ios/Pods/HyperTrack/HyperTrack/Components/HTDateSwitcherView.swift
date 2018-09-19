//
//  HTDateSwitcherView.swift
//  SDKTest
//
//  Created by Atul Manwar on 20/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

@objc public protocol HTDateSwitcherViewDelegate: class {
    func dateChanged(_ date: Date)
    func openCalendar(_ open: Bool, selectedDate: Date)
}

@objc public protocol HTCalendarDelegate: class {
    func didSelectDate(_ date: Date)
}

final class HTDateSwitcherView: HTBaseView {
    fileprivate (set) var stackView: UIStackView!
    fileprivate (set) var containerView: HTBaseView!
    fileprivate (set) var middleButton: HTButton!
    fileprivate (set) var leftButton: HTButton!
    fileprivate (set) var rightButton: HTButton! {
        didSet {
            rightButton.isHidden = true
        }
    }
    var heightValue: CGFloat = 55
    weak var delegate: HTDateSwitcherViewDelegate?
    fileprivate (set) var date: Date = Date() {
        didSet {
            rightButton.isHidden = HTSpaceTimeUtil.instance.isDateToday(date)
            delegate?.dateChanged(date)
            middleButton.setTitle(HTSpaceTimeUtil.instance.getReadableDate(date), for: .normal)
        }
    }
    var maxSupportedDate: Date {
        return (date - 30)
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            containerView.removeConstraints(containerView.constraints)
            addConstraints([
                stackView.top(),
                stackView.left(constant: 35),
                stackView.right(constant: -35),
                stackView.bottom()
                ])
            containerView.addConstraints([
                leftButton.centerY(),
                leftButton.top(),
                leftButton.bottom(),
                leftButton.left(constant: padding.left),
                leftButton.right(middleButton, toAttribute: .leading),
                leftButton.width(constant: 44),
                
                rightButton.centerY(),
                rightButton.top(),
                rightButton.bottom(),
                rightButton.right(constant: -padding.right),
                rightButton.width(constant: 44),
                
                middleButton.centerY(),
                middleButton.centerX(),
                middleButton.top(),
                middleButton.bottom(),
                middleButton.right(rightButton, toAttribute: .leading),
                ])
            addConstraints([
                height(constant: heightValue)
                ])
        }
    }
    
    var middleButtonText: String = "" {
        didSet {
            middleButton.setTitle(middleButtonText, for: .normal)
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
    
    func updateDate(_ date: Date) {
        self.date = date
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        containerView = HTBaseView(frame: .zero)
        stackView = UIStackView(frame: .zero)
        stackView.axis = .horizontal
        containerView.topCornerRadius = 14
        
        leftButton = HTButton(frame: .zero)
        leftButton.setImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.leftArrowButton), for: .normal)
        leftButton.addTarget(self, action: #selector(dateSwitched(_:)), for: .touchUpInside)
        
        rightButton = HTButton(frame: .zero)
        rightButton.setImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.rightArrowButton), for: .normal)
        rightButton.addTarget(self, action: #selector(dateSwitched(_:)), for: .touchUpInside)
        
        middleButton = HTButton(frame: .zero)
        middleButton.setImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.calendar), for: .normal)
        middleButton.addTarget(self, action: #selector(middleButtonClicked), for: .touchUpInside)
        middleButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -padding.horizontalInterItem, bottom: 0, right: 0)
        middleButtonText = "TODAY"
        middleButton.applyStyles([
            .textColor(HTProvider.style.colors.text),
            .tintColor(HTProvider.style.colors.text),
            .font(HTProvider.style.fonts.getFont(.info, weight: .bold))
            ])
        containerView.applyBaseStyles([
            .background(HTProvider.style.colors.default)
            ])
        applyBaseStyles([.background(UIColor.clear)])
        
        containerView.addSubview(leftButton)
        containerView.addSubview(middleButton)
        containerView.addSubview(rightButton)
        stackView.addArrangedSubview(containerView)
        
        addSubview(stackView)
        self.padding = padding
    }
}

extension HTDateSwitcherView {
    @objc func dateSwitched(_ sender: UIButton) {
        if sender == leftButton {
            date = (date - 86400)
        } else if sender == rightButton {
            date = (date + 86400)
        }
    }
    
    @objc func middleButtonClicked() {
        delegate?.openCalendar(true, selectedDate: date)
    }
}

extension HTDateSwitcherView: HTViewProtocol {
}
