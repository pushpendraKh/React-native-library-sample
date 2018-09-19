//
//  HTActivitySummaryHeaderView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 22/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

final class HTActivitySummaryHeaderView: UIView {
    fileprivate (set) var stackView: HTReusableStackView!
    fileprivate (set) var separatorView: HTBaseView!
    fileprivate var summary: HTPlaceline.ActivitySummary?
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            separatorView.removeConstraints(separatorView.constraints)
            addConstraints([
                stackView.left(constant: padding.left),
                stackView.right(constant: -padding.right),
                stackView.top(),
                stackView.bottom(),
                separatorView.top(stackView, toAttribute: .bottom),
                separatorView.left(stackView, toAttribute: .leading),
                separatorView.right(stackView, toAttribute: .trailing),
                ])
            separatorView.addConstraints([
                separatorView.height(constant: 1)
                ])
        }
    }
    
    var isSeparatorHidden: Bool = false {
        didSet {
            separatorView.isHidden = isSeparatorHidden
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
    
    func setSummaryInfo(_ summary: HTPlaceline.ActivitySummary?) {
        self.summary = summary
        stackView.reloadData(false)
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubViews(padding)
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        stackView = HTReusableStackView(arrangedSubviews: [])
        stackView.shouldAddSeparators = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.dataSource = self
        stackView.delegate = self
        separatorView = HTViewFactory.createHorizontalSeparatorView(1, backgroundColor: .clear)
        addSubview(stackView)
        addSubview(separatorView)
        separatorView.dashBorderedColor = HTProvider.style.colors.gray
        separatorView.isHidden = true
        self.padding = padding
    }
}

extension HTActivitySummaryHeaderView: HTViewProtocol {
}

extension HTActivitySummaryHeaderView: HTReusableStackViewDataSource {
    func numberOfItems(in stackView: HTReusableStackView) -> Int {
        return summary?.viewModel?.count ?? 0
    }
    
    func stackView(_ stackView: HTReusableStackView, viewForRowAt index: Int) -> HTStackViewItem {
        guard let info = summary?.viewModel?[index] else {
            return HTStackViewItem()
        }
        let identifier = "htActivitySummaryHeader"
        var view: HTActivitySummaryView? = stackView.dequeueReusableView(identifier: identifier, atIndex: index) as? HTActivitySummaryView
        if view == nil {
            view = HTActivitySummaryView(frame: .zero, padding: HTPaddingProvider(top: padding.top, left: 0, right: 0, bottom: padding.bottom, verticalInterItem: 6, horizontalInterItem: 0))
            view?.identifier = identifier
        }
        view?.image = info.image
        view?.text = ""//info.type.uppercased()
        view?.descriptionText = info.descriptionString
        view?.addConstraint(
            view!.width(constant: 70)
        )
        view?.layoutSubviews()
        return view!
    }
}
extension HTActivitySummaryHeaderView: HTReusableStackViewDelegate {
    
}
