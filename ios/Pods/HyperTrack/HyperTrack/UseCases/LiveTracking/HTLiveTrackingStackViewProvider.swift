//
//  HTLiveTrackingStackViewProvider.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public protocol HTTrackingViewProviderProtocol: class {
    var delegate: HTBottomViewUseCaseDelegate? { get set }
    var containerView: UIView { get }
    func updateData(_ data: [HTComponentProtocol])
    func reloadData()
}

@objc public protocol HTLiveTrackingStackViewProviderProtocol: HTTrackingViewProviderProtocol {
}

@objc final class HTLiveTrackingStackViewProvider: NSObject, HTLiveTrackingStackViewProviderProtocol, HTSwipeableProtocol {
    fileprivate (set) var data: [HTComponentProtocol] = []
    fileprivate var stackView: HTReusableStackView!
    fileprivate var swipeGestureUp: UISwipeGestureRecognizer?
    fileprivate var swipeGestureDown: UISwipeGestureRecognizer?
    fileprivate let itemIdentifier = "htStackViewItemLiveTracking"

    weak var delegate: HTBottomViewUseCaseDelegate?
    
    var isSwipeable: Bool = true {
        didSet {
            if isSwipeable && swipeGestureUp == nil && swipeGestureDown == nil {
                let gestureUp = UISwipeGestureRecognizer(target: self, action: #selector(bottomViewSwiped(_:)))
                gestureUp.direction = .up
                stackView.addGestureRecognizer(gestureUp)
                swipeGestureUp = gestureUp
                
                let gestureDown = UISwipeGestureRecognizer(target: self, action: #selector(bottomViewSwiped(_:)))
                gestureDown.direction = .down
                stackView.addGestureRecognizer(gestureDown)
                swipeGestureDown = gestureDown
            } else if let gestureUp = swipeGestureUp, let gestureDown = swipeGestureDown {
                stackView.removeGestureRecognizer(gestureUp)
                stackView.removeGestureRecognizer(gestureDown)
                swipeGestureUp = nil
                swipeGestureDown = nil
            }
        }
    }

    var position: HTSwipePosition = .collapsed
    
    var containerView: UIView {
        return stackView
    }
    
    convenience override init() {
        self.init([])
    }
    
    init(_ data: [HTComponentProtocol]) {
        self.data = data
        let oldPosition = position
        position = oldPosition
        super.init()
        commonInit()
    }
    
    func updateData(_ data: [HTComponentProtocol]) {
        self.data = data
        let oldPosition = position
        position = oldPosition
    }
    
    func reloadData() {
        var indexes: [Int] = []
        if position == .collapsed && data.count > 2 {
            for i in 1..<(data.count - 1) {
                indexes.append(i)
            }
        }
        stackView.reloadData(collapsedIndexes: indexes)
    }
    
    @objc func bottomViewSwiped(_ gesture: UISwipeGestureRecognizer) {
        guard !data.isEmpty else { return }
        switch gesture.direction {
        case .up:
            if position != .expanded {
                position = .expanded
                if data.count > 2 {
                    var indexes: [Int] = []
                    for i in 1..<(data.count - 1) {
                        indexes.append(i)
                    }
                    stackView.expandItems(indexes, animated: true)
                }
            }
        case .down:
            if position != .collapsed {
                position = .collapsed
                if data.count > 2 {
                    var indexes: [Int] = []
                    for i in 1..<(data.count - 1) {
                        indexes.append(i)
                    }
                    stackView.collapseItems(indexes, animated: true)
                }
            }
        default:
            break
        }
    }
    
    fileprivate func commonInit() {
        stackView = HTReusableStackView(frame: .zero)
        stackView.dataSource = self
        stackView.delegate = self
    }
}

extension HTLiveTrackingStackViewProvider: HTReusableStackViewDataSource {
    func numberOfItems(in stackView: HTReusableStackView) -> Int {
        return data.count
    }
    
    func stackView(_ stackView: HTReusableStackView, viewForRowAt index: Int) -> HTStackViewItem {
        let value = data[index]
        let identifier = "\(itemIdentifier)\(value.type.rawValue)"
        if let segment = value as? HTUserTrackingBottomCard.Data.UserCard, segment.type == .user {
            var item: HTUserInfoView!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) as? HTUserInfoView {
                item = reusableView
            } else {
                item = HTUserInfoView(frame: .zero, padding: HTPaddingProvider(top: 20, left: 20, right: 27, bottom: 27, verticalInterItem: 1, horizontalInterItem: 8))
            }
            item.identifier = identifier
            item.imageSize = CGSize(width: 0, height: 0)
            item.initialize(segment, delegate: delegate)
            itemCommonInit(item)
            item.titleLabel.applyStyles([
                .font(HTProvider.style.fonts.getFont(.caption, weight: .bold)),
                .textColor(HTProvider.style.colors.gray)
                ])
            item.descriptionLabel.applyStyles([
                .font(HTProvider.style.fonts.getFont(.title, weight: .bold)),
                .textColor(HTProvider.style.colors.default)
                ])
            return item
        } else if let segment = value as? HTUserTrackingBottomCard.Data.UserCard, segment.type == .userDetails {
            var item: HTUserInfoView!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) as? HTUserInfoView {
                item = reusableView
            } else {
                item = HTUserInfoView(frame: .zero, padding: HTPaddingProvider(top: 20, left: 20, right: 27, bottom: 27, verticalInterItem: 1, horizontalInterItem: 8))
            }
            item.identifier = identifier
            item.imageSize = CGSize(width: 25, height: 25)
            item.initialize(segment, delegate: delegate)
            itemCommonInit(item)
            item.titleLabel.applyStyles([
                .font(HTProvider.style.fonts.getFont(.normal, weight: .regular)),
                .textColor(HTProvider.style.colors.secondary)
                ])
            item.descriptionLabel.applyStyles([
                .font(HTProvider.style.fonts.getFont(.info, weight: .regular)),
                .textColor(HTProvider.style.colors.gray)
                ])
            return item
        } else if let segment = value as? HTUserTrackingBottomCard.Data.Status, segment.type == .status {
            var item: HTStatusAndActionView!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) as? HTStatusAndActionView {
                item = reusableView
            } else {
                item = HTStatusAndActionView(frame: .zero, padding: HTPaddingProvider(top: 24, left: 20, right: 24, bottom: 24, verticalInterItem: 1, horizontalInterItem: 8))
            }
            item.identifier = identifier
            item.initialize(segment, delegate: delegate)
            return item
        } else if let data = value as? HTOrderTrackingBottomCard.Data.OrderInfoArray {
            var item: HTStackViewItem!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) as? HTStackViewItem {
                item = reusableView
            } else {
                item = HTBottomViewFactory.Order.getOrderSummaryInfoView(data)
                item.identifier = identifier
            }
            return item
        } else if let data = value as? HTOrderTrackingBottomCard.Data.OrderStatus {
            var item: HTStackViewItem!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) as? HTStackViewItem {
                item = reusableView
            } else {
                item = HTBottomViewFactory.Order.getOrderStatusView(data)
                item.identifier = identifier
            }
            return item
        } else {
            return HTStackViewItem()
        }
    }
    
    fileprivate func itemCommonInit(_ item: HTStackViewItem) {
        item.backgroundColor = .clear
    }
}

extension HTLiveTrackingStackViewProvider: HTReusableStackViewDelegate {
}

