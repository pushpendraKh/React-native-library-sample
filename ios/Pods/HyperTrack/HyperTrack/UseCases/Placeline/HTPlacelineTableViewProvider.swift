//
//  HTPlacelineTableViewProvider.swift
//  HyperTrack
//
//  Created by Atul Manwar on 15/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

public protocol HTPlaceLineTableViewProviderProtocol: UITableViewDelegate, UITableViewDataSource {
    var delegate: HTPlaceLineCallbackDelegate? { get set }
    var contentView: UIView { get }
    init(_ data: [HTActivity], summary: HTPlaceline.ActivitySummary?)
    func updateData(_ data: [HTActivity], summary: HTPlaceline.ActivitySummary?)
    func reloadData()
    func bottomViewPadding(padding: CGFloat)
}

@objc final class HTPlaceLineTableViewProvider: NSObject, HTSwipeableProtocol, HTPlaceLineTableViewProviderProtocol {
    fileprivate var data: [Any] = []
    fileprivate var activities: [HTActivity] = []
    fileprivate let identifier = "htActivitySegmentCell"
    fileprivate var tableViewContainer: HTTableViewContainerView!
    fileprivate var tableViewHeightConstraint: NSLayoutConstraint?
    fileprivate var swipeGestureUp: UISwipeGestureRecognizer?
    fileprivate var swipeGestureDown: UISwipeGestureRecognizer?
    fileprivate var contentOffset = CGPoint.zero
    fileprivate var summary: HTPlaceline.ActivitySummary?
    weak var delegate: HTPlaceLineCallbackDelegate?
    fileprivate var shouldIncrease = false
    var isSwipeable: Bool = true
    
    var position: HTSwipePosition = .partial {
        didSet {
            tableViewContainer.viewSwiped(delegate?.swipePosition(position) ?? 0, delayed: shouldIncrease)
        }
    }

    var contentView: UIView {
        return tableViewContainer
    }
    
    convenience override init() {
        self.init([], summary: nil)
    }
    
    init(_ data: [HTActivity], summary: HTPlaceline.ActivitySummary?) {
        self.data = HTPlaceline.DisplayData(activities: data).values
        self.activities = data
        self.summary = summary
        super.init()
        commonInit()
    }
    
    func updateData(_ data: [HTActivity], summary: HTPlaceline.ActivitySummary?) {
//        tableViewContainer.tableView.contentOffset = CGPoint.zero
        self.data = HTPlaceline.DisplayData(activities: data).values
        self.activities = data
        self.summary = summary
    }
    
    func reloadData() {
        tableViewContainer.reloadData()
//        position = .partial
    }
    
    func bottomViewPadding(padding: CGFloat) {
        tableViewContainer.viewSwiped(padding)
    }
    
    enum SpecialCellType: Int {
        case summary = 0
        case total = 1
    }
    
    fileprivate func commonInit() {
        tableViewContainer = HTTableViewContainerView(frame: .zero, padding: HTPaddingProvider(top: 20, left: 0, right: 0, bottom: 0, verticalInterItem: 0, horizontalInterItem: 0))
        tableViewContainer.dataSource = self
        tableViewContainer.delegate = self
        tableViewHeightConstraint = tableViewContainer.height(constant: HTSwipePosition.expanded.getHeight() ?? 0)
        tableViewContainer.addConstraints([
            tableViewHeightConstraint!
            ])
    }
}

extension HTPlaceLineTableViewProvider: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == SpecialCellType.summary.rawValue {
            return 1
        } else {
            return data.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.separatorColor = .clear
        tableView.separatorInset = .zero
        switch indexPath.section {
        case SpecialCellType.summary.rawValue:
            let id = "\(identifier)Summary"
            var cell: HTActivitySummaryHeaderTableViewCell? = tableView.dequeueReusableCell(withIdentifier: id) as? HTActivitySummaryHeaderTableViewCell
            if cell == nil {
                cell = HTActivitySummaryHeaderTableViewCell(style: .default, reuseIdentifier: id, padding: HTPaddingProvider(top: 0, left: 35, right: 35, bottom: 30, verticalInterItem: 0, horizontalInterItem: 0))
            }
            cell?.initialize(summary)
            cell?.layoutSubviews()
            return cell!
        default:
            if let headerData = data[indexPath.row] as? HTPlaceline.DisplayData.Header {
                let identifier = "\(self.identifier)\(headerData.startTime.isEmpty ? "ActivityTransition" : "Stop")"
                var cell: HTPlaceLineMarkerTableViewCell? = tableView.dequeueReusableCell(withIdentifier: identifier) as? HTPlaceLineMarkerTableViewCell
                if cell == nil {
                    cell = HTPlaceLineMarkerTableViewCell(style: .default, reuseIdentifier: identifier, padding: HTPaddingProvider(top: 10, left: 20, right: 40, bottom: 10, verticalInterItem: 6, horizontalInterItem: 10))
                }
                if headerData.startTime.isEmpty {
                    cell?.padding = HTPaddingProvider(top: 0, left: 90, right: 40, bottom: 0, verticalInterItem: 6, horizontalInterItem: 10)
                } else {
                    cell?.padding = HTPaddingProvider(top: 20, left: 90, right: 40, bottom: 20, verticalInterItem: 6, horizontalInterItem: 10)
                }
                cell?.setData(title: headerData.title, startTime: headerData.startTime, endTime: headerData.endTime)
                return cell!
            } else if let activityData = data[indexPath.row] as? HTPlaceline.DisplayData.ActivityInfo {
                var cell: HTPlaceLineTableViewCell? = tableView.dequeueReusableCell(withIdentifier: identifier) as? HTPlaceLineTableViewCell
                if cell == nil {
                    cell = HTPlaceLineTableViewCell(style: .default, reuseIdentifier: identifier, padding: HTPaddingProvider(top: 10, left: 95, right: 20, bottom: 10, verticalInterItem: 6, horizontalInterItem: 11))
                }
                cell?.initialize(activityData)
                return cell!
            } else {
                return UITableViewCell()
            }
        }
    }
}

extension HTPlaceLineTableViewProvider: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == SpecialCellType.summary.rawValue {
            return 115
        } else if indexPath.row == (data.count - 1) {
            return 50
        } else {
            return 250
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == SpecialCellType.summary.rawValue {
            return 1
        } else {
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == SpecialCellType.total.rawValue, let activityInfo = data[indexPath.row] as? HTPlaceline.DisplayData.ActivityInfo, let activity = activities.filter({ $0.id == activityInfo.id }).first else { return }
        delegate?.selectedActivity(activity)
    }
}

extension HTPlaceLineTableViewProvider: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        contentOffset = scrollView.contentOffset
    }
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
    }
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y > 2 {
            if position == .partial {
                position = .expanded
            }
            shouldIncrease = true
        } else if velocity.y < -2 {
            if position == .expanded {
                position = .partial
            }
            shouldIncrease = false
        }
    }
}
