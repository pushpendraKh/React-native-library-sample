//
//  HTOrderTrackingUseCase.swift
//  HyperTrack
//
//  Created by Atul Manwar on 02/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public class HTOrderTrackingUseCase: HTBaseTrackingUseCase, HTMapViewUseCase {
    public var mapDelegate: HTMapUseCaseDelegate? {
        didSet {
            mapDelegate?.setBottomView(stackView)
            mapDelegate?.setPrimaryAction(primaryActionButton, anchor: .topLeft)
        }
    }
    fileprivate var stackView: UIStackView!
    public private (set) var primaryAction: HTButton!
    fileprivate var bottomView: HTBottomViewContainer?
    public weak var customizationDelegate: HTTrackingCustomizationUseCaseDelegate?
    fileprivate let viewModel: HTOrderTrackingUseCaseViewModelProtocol
    fileprivate var provider: HTOrderTrackingStackViewProviderProtocol?
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
    public weak var trackingDelegate: HTOrderTrackingUseCaseDelegate? {
        didSet {
            super.delegate = trackingDelegate
        }
    }
    public weak var navigationDelegate: HTUseCaseNavigationDelegate?

//    @objc public func setViewProvider(provider: HTOrderTrackingStackViewProviderProtocol?) {
//
//    }
    
    @objc public convenience init() {
        self.init(viewModel: nil, provider: HTOrderTrackingUseCaseStackViewProvider([]))
    }
    
    @objc public convenience required init(mapDelegate: HTMapUseCaseDelegate?) {
        self.init()
        self.mapDelegate = mapDelegate
    }
    
    public init(viewModel: HTOrderTrackingUseCaseViewModelProtocol?, provider: HTOrderTrackingStackViewProviderProtocol?) {
        self.viewModel = viewModel ?? HTOrderTrackingUseCaseViewModel()
        self.provider = provider
        super.init(viewModel: self.viewModel)
        primaryAction = HTViewFactory.createPrimaryActionButton("PLACE ORDER")
        primaryAction.addConstraints([
            primaryAction.height(constant: 50)
            ])
        primaryAction.applyStyles([
            .font(HTProvider.style.fonts.getFont(.normal, weight: .bold))
            ])
        primaryAction.topCornerRadius = 14
        primaryAction.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        if let provider = self.provider {
            let bottomView = HTViewFactory.createBottomViewContainer()
            bottomView.setContentView(provider.containerView)
            provider.containerView.edges()
            provider.reloadData()
            stackView = UIStackView(arrangedSubviews: [HTViewFactory.createPrimaryActionView(button: primaryAction), bottomView])
            stackView.axis = .vertical
            self.bottomView = bottomView
        } else {
            stackView = UIStackView(arrangedSubviews: [HTViewFactory.createPrimaryActionView(button: primaryAction)])
            stackView.axis = .vertical
        }
        defer {
            resetView()
        }
    }
    
    fileprivate func resetView() {
        mapDelegate?.showCurrentLocation = true
        mapDelegate?.cleanUp()
        bottomView?.isHidden = true
        primaryAction.isHidden = isPrimaryActionHidden
    }
    
    override func stopTimer() {
        super.stopTimer()
        resetView()
    }
    
    override public func stop() {
        stopTimer()
    }
    
    deinit {
        stopTimer()
    }
    
    override public func trackActionWithType(_ type: HTTrackWithTypeData, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        isProcessing = true
        super.trackActionWithType(type, pollDuration: pollDuration, completionHandler: { [weak self] (actions, error) in
            self?.handleTrackingResponse(actions, error: error, type: type)
            completionHandler?(actions, error)
        })
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
        trackingDelegate?.placeOrderClicked()
    }

    override public func update() {
        super.update()
    }
}

extension HTOrderTrackingUseCase {
    fileprivate func handleTrackingResponse(_ actions: [HTTrackAction]?, error: HTError?, type: HTTrackWithTypeData) {
        if customizationDelegate?.handleTrackingResponse(actions, error: error, mapDelegate: mapDelegate) ==  true {
            return
        } else if let actions = actions {
            let data = viewModel.mapToTrackingUseCase(actions: actions)
            if isPrimaryActionHiddenInternal {
                primaryAction.isHidden = true
            } else {
                primaryAction.isHidden = isPrimaryActionHidden
            }
            bottomView?.isHidden = false
            if !data.isTrackingEnabled {
                trackingDelegate?.orderTrackingEnded(type)
            }
            mapDelegate?.showCurrentLocation = data.shouldShowCurrentLocation
            if let mapData = data.mapData {
                mapDelegate?.addAnnotations(mapData.annotations)
                mapDelegate?.addPolyline(mapData.polylines)
            }
            provider?.updateData(data.bottomViewData)
            provider?.reloadData()
            mapDelegate?.showError(text: nil)
        } else {
            mapDelegate?.showError(text: error?.displayErrorMessage)
        }
        isProcessing = false
    }
}

extension HTOrderTrackingUseCase {
    @objc public class OrderData: NSObject {
        var isTrackingEnabled: Bool
        var isExpectedPlaceSet: Bool
        var shouldShowCurrentLocation: Bool
        var mapData: HTMapData?
        var bottomViewData: [HTComponentProtocol]

        static var `default`: OrderData {
            return HTOrderTrackingUseCase.OrderData(isLiveTrackingEnabled: false, isExpectedPlaceSet: false, shouldShowCurrentLocation: true, mapData: nil, bottomViewData: [])
        }

        init(isLiveTrackingEnabled: Bool, isExpectedPlaceSet: Bool, shouldShowCurrentLocation: Bool, mapData: HTMapData?, bottomViewData: [HTComponentProtocol]?) {
            self.isTrackingEnabled = isLiveTrackingEnabled
            self.isExpectedPlaceSet = isExpectedPlaceSet
            self.shouldShowCurrentLocation = shouldShowCurrentLocation
            self.bottomViewData = bottomViewData ?? []
            super.init()
            self.mapData = mapData
        }
    }

    public class TrackingInfo: NSObject {
        let trackingUrl: String
        let currentActionId: String

        init(trackingUrl: String, currentActionId: String) {
            self.trackingUrl = trackingUrl
            self.currentActionId = currentActionId
        }
    }
}

extension HTOrderTrackingUseCase: HTUseCaseBackNavigationProtocol {
    public func performActionOnButtonClick() {
        stopTimer()
        mapDelegate?.setPrimaryAction(nil, anchor: .topLeft)
        navigationDelegate?.backClicked()
    }
}

