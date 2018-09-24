//
//  HTOrderTrackingUseCaseStackViewProvider.swift
//  HyperTrack
//
//  Created by Atul Manwar on 13/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public protocol HTOrderTrackingStackViewProviderProtocol: HTTrackingViewProviderProtocol {
}

@objc final class HTOrderTrackingUseCaseStackViewProvider: NSObject {
    fileprivate (set) var data: [HTComponentProtocol] = []
    fileprivate var stackView: HTReusableStackView!
    fileprivate var itemIdentifier = "htStackViewItemOrderTracking"

    weak var delegate: HTBottomViewUseCaseDelegate?
    
    convenience override init() {
        self.init([])
    }
    
    init(_ data: [HTComponentProtocol]) {
        self.data = data
        super.init()
        commonInit()
    }
    
    func updateData(_ data: [HTComponentProtocol]) {
        self.data = data
    }
    
    fileprivate func commonInit() {
        stackView = HTReusableStackView(frame: .zero)
        stackView.dataSource = self
        stackView.delegate = self
    }
}

extension HTOrderTrackingUseCaseStackViewProvider: HTOrderTrackingStackViewProviderProtocol {
    var containerView: UIView {
        return stackView
    }
    
    func reloadData() {
        stackView.reloadData()
    }
    
}

extension HTOrderTrackingUseCaseStackViewProvider: HTReusableStackViewDataSource {
    public func numberOfItems(in stackView: HTReusableStackView) -> Int {
        return data.count
    }
    
    public func stackView(_ stackView: HTReusableStackView, viewForRowAt index: Int) -> HTStackViewItem {
        let value = data[index]
        let identifier = "\(itemIdentifier)\(value.type)"
        if let data = value as? HTUserTrackingBottomCard.Data.UserCard, value.type == .user {
            var item: HTUserInfoView!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) as? HTUserInfoView {
                item = reusableView
            } else {
                item = HTUserInfoView(frame: .zero, padding: HTPaddingProvider(top: 20, left: 20, right: 27, bottom: 27, verticalInterItem: 1, horizontalInterItem: 8))
            }
            item.identifier = identifier
            item.imageSize = CGSize(width: 0, height: 0)
            item.initialize(data, delegate: delegate)
            itemCommonInit(item)
            stackView.shouldAddSeparators = true
            return item
        } else if let data = value as? HTOrderTrackingBottomCard.Data.OrderInfoArray {
            stackView.shouldAddSeparators = false
            var item: HTStackViewItem!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) {
                item = reusableView
            } else {
                item = HTBottomViewFactory.Order.getOrderSummaryInfoView(data)
                item.identifier = identifier
            }
            return item
        } else if let data = value as? HTOrderTrackingBottomCard.Data.OrderStatus {
            var item: HTStackViewItem!
            if let reusableView = stackView.dequeueReusableView(identifier: identifier, atIndex: index) {
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

extension HTOrderTrackingUseCaseStackViewProvider: HTReusableStackViewDelegate {
}

