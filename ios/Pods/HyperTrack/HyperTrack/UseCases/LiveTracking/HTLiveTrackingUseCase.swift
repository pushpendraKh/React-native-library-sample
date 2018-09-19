//
//  HTLiveTrackingUseCase.swift
//  HyperTrack
//
//  Created by Atul Manwar on 23/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

@objc public class HTTrackWithTypeData: NSObject {
    let ids: [String]
    let type: HTTrackWithType
    
    public init(ids: [String], type: HTTrackWithType) {
        self.ids = ids
        self.type = type
    }
    
    public init(id: String, type: HTTrackWithType) {
        self.ids = [id]
        self.type = type
    }
}

@objc public enum HTTrackWithType: Int {
    case actionIds = 0
    case collectionId
    case shortCode
    case uniqueId
}

@objc public enum HTBottomViewActionType: Int {
    case share
    case stopSharing
    case call
    case none
}

@objc public class HTBottomViewActionData: NSObject {
    let type: HTBottomViewActionType
    let data: Any?
    
    init(type: HTBottomViewActionType, data: Any? = nil) {
        self.type = type
        self.data = data
        super.init()
    }
}

@objc public protocol HTBottomViewUseCaseDelegate: class {
    func actionPerformed(_ data: HTBottomViewActionData)
}

@objc public enum HTSwipePosition: Int {
    case expanded = 0
    case collapsed
    case partial
    case none
    
    func getHeight() -> CGFloat? {
        switch self {
        case .expanded:
            return UIScreen.main.bounds.height - 100
        case .partial:
            return UIScreen.main.bounds.height/2
        case .collapsed:
            return 200
        case .none:
            return nil
        }
    }
}

@objc public protocol HTSwipeableProtocol: class {
    var isSwipeable: Bool { get set }
    var position: HTSwipePosition { get set }
}

@objc public protocol HTBaseUseCaseDelegate: class {
    func showLoader(_ show: Bool)
}

@objc public protocol HTLiveTrackingUseCaseDelegate: HTBaseUseCaseDelegate {
    func shareLiveTrackingDetails(_ url: String, eta: String)
    func shareLiveLocationClicked()
    func liveTrackingEnded(_ type: HTTrackWithTypeData)
}

@objc public protocol HTOrderTrackingUseCaseDelegate: HTBaseUseCaseDelegate {
    func placeOrderClicked()
    func orderTrackingEnded(_ type: HTTrackWithTypeData)
}

@objc public protocol HTTrackingCustomizationUseCaseDelegate {
    func handleTrackingResponse(_ actions: [HTAction]?, error: HTError?, mapDelegate: HTMapUseCaseDelegate?) -> Bool
}

@objc public class HTLiveTrackingUseCase: HTBaseTrackingUseCase, HTMapViewUseCase {
    fileprivate let viewModel: HTLiveTrackingUseCaseViewModelProtocol
    public weak var trackingDelegate: HTLiveTrackingUseCaseDelegate? {
        didSet {
            super.delegate = trackingDelegate
        }
    }
    public weak var customizationDelegate: HTTrackingCustomizationUseCaseDelegate?
    fileprivate lazy var etaUseCase: HTPlaceSelectionUseCase = {
        let etaUC = HTPlaceSelectionUseCase(coordinate: HyperTrack.getCurrentLocation()?.coordinate ?? CLLocationCoordinate2D.zero)
        etaUC.delegate = self
        etaUC.navigationDelegate = self
        return etaUC
    }()
    fileprivate var stackView: UIStackView!
    fileprivate var provider: HTLiveTrackingStackViewProviderProtocol!
    fileprivate var primaryAction: HTButton!
    fileprivate var bottomView: HTBottomViewContainer!
    fileprivate var isPrimaryActionHiddenInternal = true
    
    public lazy var primaryActionButton: UIButton = {
        return self.createButtonForImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.backButton), rounded: true)
    }()
    
    public var isPrimaryActionHidden: Bool = false {
        didSet {
            isPrimaryActionHiddenInternal = false
            primaryAction.isHidden = isPrimaryActionHidden
            primaryAction.removeConstraints(primaryAction.constraints)
            primaryAction.addConstraints([
                primaryAction.height(constant: isPrimaryActionHidden ? 0 : 50)
                ])
        }
    }
    
    public var isBackButtonHidden: Bool = false {
        didSet {
            primaryActionButton.isHidden = isBackButtonHidden
        }
    }

//    fileprivate let geoFenceRadius = 100

    public var isTrackingEnabled: Bool = true {
        didSet {
            primaryAction.isHidden = !isTrackingEnabled
        }
    }
    
    public weak var navigationDelegate: HTUseCaseNavigationDelegate?
    
    public var mapDelegate: HTMapUseCaseDelegate? {
        didSet {
            mapDelegate?.setBottomView(stackView)
            mapDelegate?.setPrimaryAction(primaryActionButton, anchor: .topLeft)
            mapDelegate?.setMapViewUpdatesDelegate(nil)
        }
    }
    
    var isBottomViewSwipeable: Bool = true {
        didSet {
            if let swipeableProvider = provider as? HTSwipeableProtocol {
                swipeableProvider.isSwipeable = isBottomViewSwipeable
            }
        }
    }
    
    fileprivate var isLiveTrackingEnabled: Bool = false
    
    fileprivate var isCurrentUserBeingTracked: Bool {
        return (isLiveTrackingEnabled && !viewModel.trackingInfo.currentCollectionId.isEmpty)
    }
    
    public override func update() {
        super.update()
    }
    
//    public func stopTracking() {
//        HyperTrack.stopTracking()
//        isLiveTrackingEnabled = false
//    }
    
    @objc public convenience init() {
        self.init(viewModel: nil, provider: nil)
    }
    
    @objc public convenience required init(mapDelegate: HTMapUseCaseDelegate?) {
        self.init()
        self.mapDelegate = mapDelegate
    }
    
    @objc public init(viewModel: HTLiveTrackingUseCaseViewModelProtocol?, provider: HTLiveTrackingStackViewProviderProtocol?) {
        self.viewModel = viewModel ?? HTLiveTrackingUseCaseViewModel()
        self.provider = provider ?? HTLiveTrackingStackViewProvider([])
        super.init(viewModel: self.viewModel)
        self.provider.delegate = self
        bottomView = HTViewFactory.createBottomViewContainer()
        primaryAction = HTViewFactory.createPrimaryActionButton("SHARE LIVE LOCATION")
        primaryAction.addConstraints([
            primaryAction.height(constant: 50)
            ])
        primaryAction.applyStyles([
            .font(HTProvider.style.fonts.getFont(.normal, weight: .bold))
            ])
        primaryAction.topCornerRadius = 14
        primaryAction.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        bottomView.setContentView(self.provider.containerView)
        self.provider.containerView.edges()
        stackView = UIStackView(arrangedSubviews: [HTViewFactory.createPrimaryActionView(button: primaryAction), bottomView])
        stackView.axis = .vertical
        defer {
            isBottomViewSwipeable = true
            isLiveTrackingEnabled = false
            resetView()
        }
    }
    
    override func stopTimer() {
        super.stopTimer()
        isLiveTrackingEnabled = false
        resetView()
    }
    
    override public func stop() {
        stopTimer()
    }
    
    deinit {
        stopTimer()
    }
    
    override public func trackActionWithType(_ type: HTTrackWithTypeData, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        startTracking(type, pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    override public func trackActionWithIds(_ ids: [String], pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(ids: ids, type: .actionIds), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    override public func trackActionWithCollectionId(_ id: String, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(id: id, type: .collectionId), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    override public func trackActionWithUniqueId(_ id: String, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(id: id, type: .uniqueId), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    override public func trackActionWithShortCodes(_ codes: [String], pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(ids: codes, type: .shortCode), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    @objc func buttonPressed() {
        if isCurrentUserBeingTracked {
            shareEta()
        } else {
            trackingDelegate?.shareLiveLocationClicked()
        }
    }
    
    fileprivate func shareEta() {
        stopTimer()
        etaUseCase.coordinate = HyperTrack.getCurrentLocation()?.coordinate ?? CLLocationCoordinate2D.zero
        etaUseCase.mapDelegate = self.mapDelegate
    }
}

extension HTLiveTrackingUseCase: HTUseCaseBackNavigationProtocol {
    public func performActionOnButtonClick() {
        mapDelegate?.setPrimaryAction(nil, anchor: .topLeft)
        navigationDelegate?.backClicked()
    }
}

extension HTLiveTrackingUseCase: HTPlaceSelectionDelegate {
    fileprivate func removeEtaView() {
        if let type = trackWithType {
            startTracking(type, pollDuration: pollDuration, completionHandler: nil)
        }
        mapDelegate?.setBottomView(stackView)
        mapDelegate?.setPrimaryAction(primaryActionButton, anchor: .topLeft)
    }
    
    fileprivate func startTracking(_ type: HTTrackWithTypeData, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        isProcessing = true
        super.trackActionWithType(type, pollDuration: pollDuration, completionHandler: { [weak self] (actions, error) in
            
            self?.handleTrackingResponse(actions, error: error, type: type)
            completionHandler?(actions, error)
        })
    }
    
    fileprivate func resetView() {
        primaryAction.setTitle("SHARE LIVE LOCATION", for: .normal)
        mapDelegate?.showCurrentLocation = true
        mapDelegate?.cleanUp()
        bottomView.isHidden = false
        provider.updateData([])
        provider.reloadData()
        primaryAction.isHidden = isPrimaryActionHidden
    }
    
    public func cancelClicked() {
        removeEtaView()
    }
    
    public func expectedPlaceSet(_ data: HTPlace) {
        removeEtaView()
        self.isProcessing = true
        viewModel.addExpectedPlace(collectionId: viewModel.trackingInfo.currentCollectionId, newPlace: data) { [weak self] (data, error) in
            if let _ = data?.expectedPlace, let _ = data?.id {
                self?.mapDelegate?.showError(text: nil)
                guard let type = self?.trackWithType else {
                    self?.isProcessing = false
                    return
                }
//                HyperTrack.startMonitoringForEntryAtPlace(place: place, radius: CLLocationDistance(self.geoFenceRadius), identifier: id)
//                HyperTrack.setEventsDelegate(eventDelegate: self)
                self?.startTracking(type, pollDuration: 0, completionHandler: nil)
            } else {
                self?.isProcessing = true
                self?.mapDelegate?.showError(text: error?.displayErrorMessage)
            }
        }
    }
}

extension HTLiveTrackingUseCase: HTBottomViewUseCaseDelegate {
    public func actionPerformed(_ data: HTBottomViewActionData) {
        switch data.type {
        case .share:
            trackingDelegate?.shareLiveTrackingDetails(viewModel.trackingInfo.trackingUrl, eta: viewModel.trackingInfo.eta)
            break
        case .stopSharing:
            guard let actionId = data.data as? String else { return }
            isProcessing = true
            viewModel.completeAction(actionId, completionHandler: { [weak self] (data, error) in
                guard error == nil, let type = self?.trackWithType else {
                    self?.isProcessing = false
                    self?.mapDelegate?.showError(text: error?.displayErrorMessage)
                    return
                }
                self?.startTracking(type, pollDuration: 0, completionHandler: nil)
            })
            provider.reloadData()
        case .call:
            guard let phone = data.data as? String else { return }
            guard !phone.isEmpty else { return }
            UIApplication.shared.openURL(URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))")!)
        default:
            break
        }
    }
    
    fileprivate func handleData(_ data: HTLiveTrackingUseCase.LiveData, type: HTTrackWithTypeData) {
        isLiveTrackingEnabled = data.isTrackingEnabled
        if !data.isTrackingEnabled {
            trackingDelegate?.liveTrackingEnded(type)
        }
        if let mapData = data.mapData {
            mapDelegate?.addAnnotations(mapData.annotations)
            mapDelegate?.addPolyline(mapData.polylines)
        }
        provider.updateData(data.bottomViewData)
        provider.reloadData()
        if !isPrimaryActionHiddenInternal {
            primaryAction.isHidden = isPrimaryActionHidden
        } else if data.isCompleted {
            primaryAction.isHidden = true
        }
        if data.isCompleted {
        } else if isCurrentUserBeingTracked {
            if data.isExpectedPlaceSet {
                primaryAction.setTitle("UPDATE LOCATION", for: .normal)
            } else {
                primaryAction.setTitle("SHARE ETA", for: .normal)
            }
        } else {
            primaryAction.setTitle("SHARE LIVE LOCATION", for: .normal)
        }
    }

    fileprivate func handleTrackingResponse(_ actions: [HTTrackAction]?, error: HTError?, type: HTTrackWithTypeData) {
        isProcessing = false
        if customizationDelegate?.handleTrackingResponse(actions, error: error, mapDelegate: mapDelegate) ==  true {
            return
        } else if let actions = actions {
            viewModel.mapToLiveTrackingUseCase(actions: actions, completionHandler: { (data) in
                DispatchQueue.main.async { [weak self] in
                    self?.handleData(data, type: type)
                }
            })
            mapDelegate?.showError(text: nil)
        } else {
            mapDelegate?.showError(text: error?.displayErrorMessage)
        }
    }
}

extension HTLiveTrackingUseCase {
    @objc public class LiveData: NSObject {
        var isTrackingEnabled: Bool
        var isExpectedPlaceSet: Bool
        var mapData: HTMapData?
        var bottomViewData: [HTComponentProtocol]
        var isCompleted: Bool
        var showCurrentLocation: Bool
        
        static var `default`: LiveData {
            return HTLiveTrackingUseCase.LiveData(isLiveTrackingEnabled: false, isExpectedPlaceSet: false, mapData: nil, bottomViewData: [], isCompleted: false, showCurrentLocation: true)
        }
        
        init(isLiveTrackingEnabled: Bool, isExpectedPlaceSet: Bool, mapData: HTMapData?, bottomViewData: [HTComponentProtocol]?, isCompleted: Bool, showCurrentLocation: Bool) {
            self.isTrackingEnabled = isLiveTrackingEnabled
            self.isExpectedPlaceSet = isExpectedPlaceSet
            self.bottomViewData = bottomViewData ?? []
            self.isCompleted = isCompleted
            self.showCurrentLocation = showCurrentLocation
            super.init()
            self.mapData = mapData
        }
    }
    
    public class TrackingInfo: NSObject {
        let trackingUrl: String
        let currentCollectionId: String
        let eta: String
        
        static var `default`: TrackingInfo {
            return TrackingInfo(trackingUrl: "", collectionId: "", eta: "")
        }
        
        init(trackingUrl: String, collectionId: String, eta: String) {
            self.trackingUrl = trackingUrl
            self.currentCollectionId = collectionId
            self.eta = eta
        }
    }
}

extension HTLiveTrackingUseCase: HTUseCaseNavigationDelegate {
    public func backClicked() {
        removeEtaView()
    }
}
