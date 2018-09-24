//
//  HTPlaceLineUseCase.swift
//  HyperTrack
//
//  Created by Atul Manwar on 22/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

public protocol HTPlaceLineCallbackDelegate: class {
    func selectedActivity(_ activity: HTActivity)
    func swipePosition(_ position: HTSwipePosition) -> CGFloat
}

@objc public protocol HTPlaceLineUseCaseDelegate: class {
}

@objc public protocol HTMapViewUseCase: class {
    var mapDelegate: HTMapUseCaseDelegate? { get set }
    func update()
    init(mapDelegate: HTMapUseCaseDelegate?)
}

extension HTMapViewUseCase {
    public func setMapDelegate(_ mapDelegate: HTMapUseCaseDelegate?) {
        self.mapDelegate = mapDelegate
    }
}

public enum HTBottomViewUseCaseType {
    case placeline
    case liveTracking
    case other(HTMapViewUseCase)
}

//public enum HTAPIResponse<T> {
//    case success(T)
//    case failure(HTError?)
//    
//    static var unknownFailure: HTAPIResponse<T> {
//        return HTAPIResponse<T>.failure(HTError.default)
//    }
//}

public typealias HTPlacelineCompletionHandler = (HTPlaceline?, HTError?) -> Void

public protocol HTPlaceLineUseCaseViewModelProtocol: HTBaseViewModelProtocol {
    func getPlacelineData(_ date: Date, completionHandler: HTPlacelineCompletionHandler?)
}

public class HTPlaceLineUseCaseViewModel: HTPlaceLineUseCaseViewModelProtocol {
    public func getPlacelineData(_ date: Date, completionHandler: HTPlacelineCompletionHandler?) {
        HyperTrack.getPlaceline(date: date) { (placeline, error) in
            completionHandler?(placeline, error)
        }
    }
}

@objc public class HTPlaceLineUseCase: HTBaseUseCase, HTMapViewUseCase {
    public weak var mapDelegate: HTMapUseCaseDelegate? {
        didSet {
            mapDelegate?.setBottomView(stackView, atPosition: .partial)
            if let padding = mapDelegate?.getBottomPadding() {
                self.provider.bottomViewPadding(padding: padding - dateSwitcherView.heightValue)
            }
            mapDelegate?.setPrimaryAction(primaryActionButton, anchor: .topLeft)
            
        }
    }
    fileprivate var dateSwitcherView: HTDateSwitcherView!
    fileprivate var provider: HTPlaceLineTableViewProviderProtocol
    fileprivate var calendarProvider: HTCalendarProviderProtocol
    var viewModel: HTPlaceLineUseCaseViewModelProtocol
    fileprivate var stackView: UIStackView!
    fileprivate var bottomView: HTBottomViewContainer!
    fileprivate var buttonWidthConstraint: NSLayoutConstraint?
    fileprivate var buttonHeightConstraint: NSLayoutConstraint?
    fileprivate var completionHandler: HTPlacelineCompletionHandler? = nil
    
    public lazy var primaryActionButton: UIButton = {
        return self.createButtonForImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.backButton), rounded: true)
    }()
    
    public var isBackButtonHidden: Bool = false {
        didSet {
            primaryActionButton.isHidden = isBackButtonHidden
        }
    }
    
    public var isPrimaryActionHidden: Bool = false

    public weak var navigationDelegate: HTUseCaseNavigationDelegate?
    
    var isBottomViewSwipeable: Bool = true {
        didSet {
            if let swipeableProvider = provider as? HTSwipeableProtocol {
                swipeableProvider.isSwipeable = isBottomViewSwipeable
            }
        }
    }

    @objc convenience public override init() {
        self.init(viewModel: nil, provider: nil, calendarProvider: nil)
    }
    
    @objc public convenience required init(mapDelegate: HTMapUseCaseDelegate?) {
        self.init()
        self.mapDelegate = mapDelegate
    }

    public init(viewModel: HTPlaceLineUseCaseViewModelProtocol? = nil, provider: HTPlaceLineTableViewProviderProtocol? = nil, calendarProvider: HTCalendarProviderProtocol? = nil) {
        self.viewModel = viewModel ?? HTPlaceLineUseCaseViewModel()
        self.provider = provider ?? HTPlaceLineTableViewProvider([], summary: nil)
        self.calendarProvider = calendarProvider ?? HTCalendarProvider()
        self.calendarProvider.maximumDate = Date()
        self.calendarProvider.minimumDate = (Date() - 86400 * 120)
        super.init()
        self.calendarProvider.delegate = self
        self.provider.delegate = self
        dateSwitcherView = HTDateSwitcherView(frame: .zero, padding: HTPaddingProvider.default)
        dateSwitcherView.delegate = self
        bottomView = HTViewFactory.createBottomViewContainer()
        bottomView.isBlurEnabled = false
        bottomView.backgroundColor = .white
        bottomView.setContentView(self.provider.contentView)
        self.provider.contentView.edges()
        self.provider.reloadData()
        if let padding = mapDelegate?.getBottomPadding() {
            self.provider.bottomViewPadding(padding: padding)
        }
        stackView = UIStackView(arrangedSubviews: [dateSwitcherView, bottomView])
        stackView.axis = .vertical
        defer {
            isBottomViewSwipeable = true
        }
    }
    
    fileprivate func updateData(_ data: HTPlaceline) {
        updateData(data.placeline, summary: data.activitySummary)
    }
    
    fileprivate func updateData(_ placeline: [HTActivity], summary: HTPlaceline.ActivitySummary?) {
        provider.updateData(placeline.reversed(), summary: summary)
        provider.reloadData()
    }
    
    func getPlaceline(_ date: Date? = nil, completionHandler: HTPlacelineCompletionHandler? = nil) {
        guard date != nil else {
            self.completionHandler = completionHandler
            dateSwitcherView.updateDate(Date())
            return
        }
        isProcessing = true
        updateData([], summary: nil)
        let givenDate = date ?? Date()
        if HTSpaceTimeUtil.instance.getReadableDate(givenDate) == HTSpaceTimeUtil.instance.getReadableDate(dateSwitcherView.date) {
            viewModel.getPlacelineData(givenDate, completionHandler: { [weak self] (placeline, error) in
                self?.isProcessing = false
                if let data = placeline {
                    self?.updateData(data)
                    self?.mapDelegate?.showError(text: nil)
                    } else {
                    self?.mapDelegate?.showError(text: error?.displayErrorMessage)
                }
                completionHandler?(placeline, error)
                self?.completionHandler = nil
            })
        }
    }
    
    public func update() {
        if !HTSpaceTimeUtil.instance.isDateToday(dateSwitcherView.date) {
            dateSwitcherView.updateDate(Date())
        } else {
            getPlaceline(dateSwitcherView.date)
        }
    }
    
    public func setDate(_ date: Date) {
        dateSwitcherView.updateDate(date)
    }
}

extension HTPlaceLineUseCase: HTDateSwitcherViewDelegate {
    public func dateChanged(_ date: Date) {
        mapDelegate?.cleanUp()
        mapDelegate?.showCurrentLocation = true
        getPlaceline(date, completionHandler: completionHandler)
    }
}

extension HTPlaceLineUseCase: HTCalendarDelegate {
    public func didSelectDate(_ date: Date) {
        dateSwitcherView.updateDate(date)
    }
    
    public func openCalendar(_ open: Bool, selectedDate: Date) {
        let calendar = calendarProvider.contentView
        guard let view = stackView.superview else { return }
        calendar.removeFromSuperview()
        if open {
            view.addSubview(calendar)
            calendar.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraints([
                calendar.left(),
                calendar.right(),
                calendar.bottom()
                ])
        } else {
            calendar.removeFromSuperview()
        }
    }
}

extension HTPlaceLineUseCase: HTPlaceLineCallbackDelegate {
    fileprivate func getAnnotationData(_ id: String, activity: HTActivity, type: HTAnnotationType, coordinate: CLLocationCoordinate2D, start: Bool = true) -> HTAnnotationData {
        return HTAnnotationData(id: id, coordinate: coordinate, metaData: HTAnnotationData.MetaData(isPulsating: false, type: type, actionInfo: nil), callout: nil)
    }
    
    public func swipePosition(_ position: HTSwipePosition) -> CGFloat {
        if position == .expanded {
            openCalendar(false, selectedDate: dateSwitcherView.date)
        }
        return mapDelegate?.updateBottomViewPosition(position) ?? 0
    }
    
    public func selectedActivity(_ activity: HTActivity) {
        mapDelegate?.cleanUp()
        mapDelegate?.showCurrentLocation = false
        if let encodedPolylineString = activity.route {
            guard let coordinates = PolylineUtils.decodePolyline(encodedPolylineString) else { return }
            mapDelegate?.addPolyline([HTPolylineData(id: activity.id, type: .filled, coordinates: coordinates, encodedRoute: encodedPolylineString)])
            var annotationData: [HTAnnotationData] = []
            if let coordinate = coordinates.first {
                annotationData.append(getAnnotationData("start", activity: activity, type: .user, coordinate: coordinate, start: true))
            }
            if let coordinate = coordinates.last {
                annotationData.append(getAnnotationData("expected", activity: activity, type: .destination, coordinate: coordinate, start: false))
            }
            mapDelegate?.addAnnotations(annotationData)
            mapDelegate?.showCoordinates(coordinates)
        }
    }
}

extension HTPlaceLineUseCase: HTUseCaseBackNavigationProtocol {
    public func performActionOnButtonClick() {
        mapDelegate?.cleanUp()
        mapDelegate?.setPrimaryAction(nil, anchor: .topLeft)
        navigationDelegate?.backClicked()
    }
}

