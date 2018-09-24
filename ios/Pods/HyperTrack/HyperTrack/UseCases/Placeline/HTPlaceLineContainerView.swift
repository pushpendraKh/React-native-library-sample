//
//  HTPlaceLineContainerView.swift
//  SDKTest
//
//  Created by Atul Manwar on 20/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTTableViewContainerView: UIView {
    fileprivate (set) var tableView: UITableView!
    weak var bottomViewDelegate: HTBottomViewUseCaseDelegate?
    fileprivate var bottomViewConstraint: NSLayoutConstraint?

    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            bottomViewConstraint = tableView.bottom(constant: padding.bottom)
            addConstraints([
                tableView.top(constant: padding.top),
                tableView.left(constant: padding.left),
                tableView.right(constant: padding.right),
                bottomViewConstraint!,
                ])
        }
    }
    
    var delegate: UITableViewDelegate? = nil {
        didSet {
            tableView.delegate = delegate
        }
    }
    
    var dataSource: UITableViewDataSource? = nil {
        didSet {
            tableView.dataSource = dataSource
            reloadData()
        }
    }
    
    var shouldResizeToFitContent: Bool = false
    
    func reloadData() {
        self.tableView.reloadData()
//        handleTableViewReload()
    }
    
    func viewSwiped(_ height: CGFloat, delayed: Bool = true) {
        if delayed {
            DispatchQueue.main.asyncAfter(deadline: .now() + HTProvider.animationDuration + 0.1) {
                UIView.performWithoutAnimation {
                    self.bottomViewConstraint?.constant = -height
                }
            }
        } else {
            UIView.performWithoutAnimation {
                self.bottomViewConstraint?.constant = -height
            }
        }
    }
    
    func insertRows(indexPaths: [IndexPath], animated: Bool = true) {
        tableView.beginUpdates()
        tableView.insertRows(at: indexPaths, with: .none)
        tableView.endUpdates()
//        handleTableViewReload()
    }
    
    func deleteRows(indexPaths: [IndexPath], animated: Bool = true) {
        tableView.beginUpdates()
        tableView.deleteRows(at: indexPaths, with: .none)
        tableView.endUpdates()
//        handleTableViewReload()
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
    
//    fileprivate func handleTableViewReload() {
//        if shouldResizeToFitContent {
//            tableViewHeight = tableView.contentSize.height + tableView.contentInset.bottom + tableView.contentInset.top
//            if tableViewHeightConstraint == nil {
//                tableViewHeightConstraint = tableView.height(constant: tableViewHeight)
//                tableView.addConstraint(tableViewHeightConstraint!)
//                UIView.animate(withDuration: HTProvider.animationDuration, animations: {
//                    self.layoutIfNeeded()
//                })
//            } else {
////                self.tableViewHeightConstraint?.constant = self.tableViewHeight
//                UIView.animate(withDuration: HTProvider.animationDuration, animations: {
//                    self.tableViewHeightConstraint?.constant = self.tableViewHeight
//                    self.layoutIfNeeded()
//                })
//            }
////            self.layoutIfNeeded()
//        } else {
//            tableViewHeightConstraint?.isActive = false
//            tableViewHeightConstraint = nil
//        }
//    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.separatorInset = .zero
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 250
        tableView.keyboardDismissMode = .onDrag
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.sectionHeaderHeight = 1
        tableView.sectionFooterHeight = 1
        tableView.contentInset = .zero
        addSubview(tableView)
        backgroundColor = .clear
        self.padding = padding
    }
}

extension HTTableViewContainerView: HTViewProtocol {
}
