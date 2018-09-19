//
//  HTActivitySummaryUseCase.swift
//  HyperTrack
//
//  Created by Atul Manwar on 23/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public protocol HTActivitySummaryUseCaseDelegate: HTLiveTrackingUseCaseDelegate, HTPlaceLineUseCaseDelegate {
}

@objc public protocol HTUseCaseBackNavigationProtocol: class {
    var primaryActionButton: UIButton { get set }
    var isPrimaryActionHidden: Bool { get set }
    var navigationDelegate: HTUseCaseNavigationDelegate? { get set }
    func performActionOnButtonClick()
}

extension HTUseCaseBackNavigationProtocol {
    var buttonSize: CGFloat {
        return 48
    }
    
    func createButtonForImage(_ image: UIImage?, rounded: Bool) -> UIButton {
        let button = UIButton(frame: .zero)
        button.setImage(image, for: .normal)
        let buttonWidthConstraint = button.width(constant: buttonSize)
        let buttonHeightConstraint = button.height(constant: buttonSize)
        button.addConstraints([
            buttonWidthConstraint,
            buttonHeightConstraint
            ])
        button.isHidden = isPrimaryActionHidden
        if rounded {
            button.applyStyle(.radius(buttonSize))
        }
        button.addTarget(self, action: #selector(performActionOnButtonClick), for: .touchUpInside)
        return button
    }
    
    func setButtonSize(_ size: CGFloat) {
        primaryActionButton.removeConstraints(primaryActionButton.constraints)
        let buttonWidthConstraint = primaryActionButton.width(constant: size)
        let buttonHeightConstraint = primaryActionButton.height(constant: size)
        primaryActionButton.addConstraints([
            buttonWidthConstraint,
            buttonHeightConstraint
            ])
    }
}

@objc public protocol HTUseCaseNavigationDelegate: class {
    func backClicked()
}

public final class HTActivitySummaryUseCase: HTBaseUseCase, HTMapViewUseCase {
    weak public var mapDelegate: HTMapUseCaseDelegate? {
        didSet {
            mapDelegate?.setBottomView(stackView)
        }
    }
    
    public var liveUC: HTLiveTrackingUseCase! {
        return liveUseCase
    }
    
    public var placelineUC: HTPlaceLineUseCase! {
        return placelineUseCase
    }
    
    fileprivate var liveUseCase: HTLiveTrackingUseCase!
    fileprivate var placelineUseCase: HTPlaceLineUseCase!
    fileprivate var contentView: HTActivitySummaryContainerView!
    fileprivate var bottomView: HTBottomViewContainer!
    fileprivate var stackView: UIStackView!
    fileprivate var primaryAction: HTButton!
    fileprivate var fetchedOnce = false
    
    public weak var activityDelegate: HTActivitySummaryUseCaseDelegate? {
        didSet {
            super.delegate = activityDelegate
            liveUseCase.trackingDelegate = activityDelegate
        }
    }
    
    public var isPrimaryActionHidden: Bool = false {
        didSet {
            primaryAction.isHidden = isPrimaryActionHidden
        }
    }

    public convenience override init() {
        self.init(liveUseCase: nil, placelineUseCase: nil)
    }
    
    @objc public convenience required init(mapDelegate: HTMapUseCaseDelegate?) {
        self.init()
        self.mapDelegate = mapDelegate
    }
    
    public init(liveUseCase: HTLiveTrackingUseCase?, placelineUseCase: HTPlaceLineUseCase?) {
        contentView = HTActivitySummaryContainerView(frame: .zero, padding: HTPaddingProvider(top: 30, left: 35, right: 35, bottom: 30, verticalInterItem: 15, horizontalInterItem: 40))
        self.liveUseCase = liveUseCase ?? HTLiveTrackingUseCase()
        self.placelineUseCase = placelineUseCase ?? HTPlaceLineUseCase()
        bottomView = HTViewFactory.createBottomViewContainer()
        primaryAction = HTViewFactory.createPrimaryActionButton("SHARE LIVE LOCATION")
        primaryAction.addConstraints([
            primaryAction.height(constant: 50)
            ])
        primaryAction.applyStyles([
            .font(HTProvider.style.fonts.getFont(.normal, weight: .bold))
            ])
        primaryAction.topCornerRadius = 14
        bottomView.isBlurEnabled = false
        bottomView.backgroundColor = .white
        bottomView.setContentView(contentView)
        contentView.edges()
        stackView = UIStackView(arrangedSubviews: [HTViewFactory.createPrimaryActionView(button: primaryAction), bottomView])
        bottomView.isHidden = true
        stackView.axis = .vertical
        super.init()
        self.liveUseCase.navigationDelegate = self
        self.placelineUseCase.navigationDelegate = self
        primaryAction.addTarget(self, action: #selector(startTracking), for: .touchUpInside)
        contentView.actionButton.addTarget(self, action: #selector(showPlaceline), for: .touchUpInside)
    }
    
    public func update() {
        placelineUseCase.delegate = delegate
        placelineUseCase.getPlaceline(nil) { [weak self] (placeline, error) in
            self?.fetchedOnce = true
            if let placeline = placeline {
                self?.handlePlacelineResponse(placeline)
            } else {
                self?.mapDelegate?.showError(text: error?.displayErrorMessage)
            }
        }
        if fetchedOnce {
            isProcessing = false
        }
    }
    
    @objc func showPlaceline() {
        mapDelegate?.enableZoom = false
        placelineUseCase.mapDelegate = mapDelegate
        placelineUseCase.delegate = delegate
        mapDelegate?.enableZoom = true
    }
    
    @objc public func enabeLiveTracking() {
        mapDelegate?.enableZoom = false
        liveUseCase.trackingDelegate = activityDelegate
        liveUseCase.mapDelegate = mapDelegate
        mapDelegate?.enableZoom = true
    }
    
    @objc func startTracking() {
        enabeLiveTracking()
        liveUseCase.trackingDelegate?.shareLiveLocationClicked()
    }
    
    fileprivate func handlePlacelineResponse(_ placeline: HTPlaceline) {
        contentView.setPlaceline(placeline)
        bottomView.isHidden = false
    }
}

extension HTActivitySummaryUseCase: HTUseCaseNavigationDelegate {
    public func backClicked() {
        liveUseCase.stopTimer()
        mapDelegate?.setCenterFloatingView(nil, offset: .zero)
        mapDelegate?.enableZoom = false
        mapDelegate?.showCurrentLocation = true
        mapDelegate?.cleanUp()
        mapDelegate?.setBottomView(stackView)
        mapDelegate?.enableZoom = true
        update()
    }
}
