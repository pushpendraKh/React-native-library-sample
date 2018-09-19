//
//  HTCalendarProvider.swift
//  HyperTrack
//
//  Created by Atul Manwar on 02/04/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public protocol HTCalendarProviderProtocol: class {
    var contentView: UIView { get }
    var minimumDate: Date { get set }
    var maximumDate: Date { get set }
    var delegate: HTCalendarDelegate? { get set }
}

public class HTCalendarProvider: NSObject, HTCalendarProviderProtocol {
    public var contentView: UIView {
        return containerView
    }
    public weak var delegate: HTCalendarDelegate?
    fileprivate lazy var calendar: UIDatePicker = {
        let calendar = UIDatePicker(frame: .zero)
        calendar.datePickerMode = .date
        return calendar
    }()
    fileprivate var containerView: UIView
    fileprivate var dismissButton: UIButton
    fileprivate var doneButton: UIButton
    
    public var minimumDate: Date = Date() {
        didSet {
            calendar.minimumDate = minimumDate
        }
    }
    public var maximumDate: Date = Date() {
        didSet {
            calendar.maximumDate = maximumDate
        }
    }
    
    public override init() {
        containerView = UIView(frame: .zero)
        dismissButton = UIButton(frame: .zero)
        doneButton = UIButton(frame: .zero)
        super.init()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        calendar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(calendar)
        containerView.addSubview(dismissButton)
        containerView.addSubview(doneButton)
        containerView.addConstraints([
            calendar.top(),
            calendar.left(),
            calendar.right(),
            calendar.bottom(dismissButton, toAttribute: .top),
            dismissButton.left(),
            dismissButton.right(doneButton, toAttribute: .leading, constant: 10),
            dismissButton.bottom(constant: -20),
            dismissButton.width(doneButton),
            doneButton.top(dismissButton),
            doneButton.right(),
            doneButton.bottom(constant: -20),
            ])
        dismissButton.addConstraints([
            dismissButton.height(constant: 44)
            ])
        dismissButton.applyStyles([
            .textColor(HTProvider.style.colors.error),
            .font(HTProvider.style.fonts.getFont(.normal, weight: .medium)),
            .background(.white)
            ])
        dismissButton.setTitle("DISMISS", for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonClicked), for: .touchUpInside)
        doneButton.addConstraints([
            doneButton.height(constant: 44)
            ])
        doneButton.applyStyles([
            .textColor(HTProvider.style.colors.default),
            .font(HTProvider.style.fonts.getFont(.normal, weight: .medium)),
            .background(.white)
            ])
        doneButton.setTitle("DONE", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonClicked), for: .touchUpInside)
        containerView.backgroundColor = .white
    }
    
    func dismissButtonClicked() {
        containerView.removeFromSuperview()
    }

    func doneButtonClicked() {
        delegate?.didSelectDate(calendar.date)
        containerView.removeFromSuperview()
    }
}

