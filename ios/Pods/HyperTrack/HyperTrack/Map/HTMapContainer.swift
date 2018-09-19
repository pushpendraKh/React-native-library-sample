//
//  HTMapContainer.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

@objc public protocol HTMapCustomizationDelegate {
    @objc optional func userMarkerImage(annotationType: HTAnnotationType) -> UIImage?
    @objc optional func userMarkerImage(actionInfo: HTActionInfo) -> UIImage?
    @objc optional func expectedPlaceMarkerImage() -> UIImage?
    @objc optional func expectedPlaceMarkerImage(actionInfo: HTActionInfo) -> UIImage?
}

@objc public protocol HTMapViewDelegate: class {
    var showCurrentLocation: Bool { get set }
    func cleanUp()
    func addAnnotations(_ data: [HTAnnotationData])
    func addPolyline(_ data: [HTPolylineData])
    func addTrailingPolyline(_ data: [HTTimeAwarePolyline])
    func updateMapVisibleRegion(_ insets: UIEdgeInsets)
    func getCenterCoordinates() -> CLLocationCoordinate2D
    func showCoordinates(_ coordinates: [CLLocationCoordinate2D])
}

@objc public protocol HTMapViewUpdatesDelegate: class {
    func mapViewDidChange(centerCoordinate: CLLocationCoordinate2D)
}

@objc public protocol HTMapUseCaseDelegate: HTMapViewDelegate {
    func showError(text: String?)
    func setBottomView(_ view: UIView?)
    func setBottomView(_ view: UIView?, atPosition: HTSwipePosition)
    func updateBottomViewPosition(_ position: HTSwipePosition) -> CGFloat
    func setPrimaryAction(_ view: UIView?, anchor: AnchorPosition)
    func setCenterFloatingView(_ view: UIView?, offset: CGPoint)
    func setMapViewUpdatesDelegate(_ delegate: HTMapViewUpdatesDelegate?)
    var enableZoom: Bool { get set }
    func getBottomPadding() -> CGFloat
}

@objc public final class HTMapContainer: UIView {
    fileprivate var useCases: [HTMapViewUseCase] = [] {
        didSet {
            
        }
    }
    public var showCurrentLocation: Bool = false {
        didSet {
            mapProvider.showCurrentLocation = showCurrentLocation
        }
    }
    fileprivate var mapProvider: HTMapsProviderProtocol {
        didSet {
            mapProvider.updatesDelegate = self
        }
    }
    fileprivate var position: HTSwipePosition = .none
    fileprivate var mapView: UIView {
        return mapProvider.contentView
    }
    var sidePaddingForBottomView: CGFloat = 10 {
        didSet {
            bottomViewLeftConstraint?.constant = sidePaddingForBottomView
            bottomViewRightConstraint?.constant = sidePaddingForBottomView
        }
    }
    fileprivate var recenterButtonBottomSpacing: CGFloat = -15
    fileprivate var recenterButtonRightSpacing: CGFloat = -15
    fileprivate var bottomView: UIView? {
        didSet {
            guard let bottomView = bottomView else {
                recenterButtonBottomConstraint?.isActive = false
                recenterButtonBottomConstraint = recenterButton.bottom(constant: recenterButtonBottomSpacing)
                addConstraints([
                    recenterButtonBottomConstraint!
                    ])
                return
            }
            addSubview(bottomView)
            bottomViewBottomConstraint = bottomView.bottom(constant: UIScreen.main.bounds.height)
            bottomViewLeftConstraint = bottomView.left(constant: sidePaddingForBottomView)
            bottomViewRightConstraint = bottomView.right(constant: -sidePaddingForBottomView)
            addConstraints([
                bottomViewBottomConstraint!,
                bottomViewLeftConstraint!,
                bottomViewRightConstraint!
                ])
            _ = updateBottomViewPosition(position)
            recenterButtonBottomConstraint?.isActive = false
            recenterButtonBottomConstraint = recenterButton.bottom(bottomView, toAttribute: .top, constant: recenterButtonRightSpacing)
            addConstraints([
                recenterButtonBottomConstraint!
                ])
        }
    }
    fileprivate var floatingView: UIView?
    fileprivate var primaryActionView: UIView?
    fileprivate lazy var recenterButton: HTButton = {
        let button = HTButton(frame: .zero)
        button.setImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.recenterButton), for: .normal)
        button.addTarget(self, action: #selector(recenterButtonClicked), for: .touchUpInside)
        button.addConstraints([
            button.width(constant: 44),
            button.height(constant: 44)
            ])
        return button
    }()
    fileprivate var recenterButtonBottomConstraint: NSLayoutConstraint?
    fileprivate var errorView: HTErrorStatusView?
    fileprivate var coordinates: [CLLocationCoordinate2D] = []
    fileprivate var locatedUser: Bool = false
    fileprivate var bottomViewBottomConstraint: NSLayoutConstraint?
    fileprivate var bottomViewLeftConstraint: NSLayoutConstraint?
    fileprivate var bottomViewRightConstraint: NSLayoutConstraint?
    fileprivate var shouldZoom: Bool {
        return (enableZoom && !lockZoom)
    }
    
    fileprivate var lockZoom: Bool = false
    
    var keyboardSize: CGSize = .zero
    var keyboardShown: Bool = false {
        didSet {
            guard let bottomConstraint = bottomViewBottomConstraint, let bottomView = bottomView else {
                return
            }
            if keyboardShown {
                UIView.animate(withDuration: HTProvider.animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                    let emptySpace = UIScreen.main.bounds.height - bottomView.bounds.height - 20
                    bottomConstraint.constant = -min(self.keyboardSize.height, emptySpace)
                    self.layoutSubviews()
                }, completion: nil)
            } else {
                UIView.animate(withDuration: HTProvider.animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                    bottomConstraint.constant = 0
                    self.layoutSubviews()
                }, completion: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var isBottomViewHidden: Bool = false {
        didSet {
            bottomView?.isHidden = isBottomViewHidden
        }
    }
    
    public var enableZoom: Bool = true
    public var isRecenterButtonHidden = false {
        didSet {
            UIView.animate(withDuration: HTProvider.animationDuration, animations: {
                self.recenterButton.alpha = self.isRecenterButtonHidden ? 0 : 1
            }) { (_) in
                self.recenterButton.isHidden = self.isRecenterButtonHidden
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if let bottomView = bottomView, shouldZoom {
            guard position != .expanded else { return }
            let height = position.getHeight() ?? bottomView.bounds.height
            updateMapVisibleRegion(UIEdgeInsets(top: 40, left: 40, bottom: height, right: 40))
        }
    }
    
    @objc public init(frame: CGRect, mapProvider: HTMapsProviderProtocol) {
        self.mapProvider = mapProvider
        super.init(frame: frame)
        setupSubViews()
    }
    
    public override init(frame: CGRect) {
        mapProvider = HTAppleMapsProvider()
        super.init(frame: frame)
        setupSubViews()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        mapProvider = HTAppleMapsProvider()
        super.init(coder: aDecoder)
        setupSubViews()
    }
    
    @objc public func setBottomViewWithUseCase(_ useCase: HTMapViewUseCase) {
        useCase.mapDelegate = self
    }
    
    enum State: Int {
        case collapsed
        case partial
        case expanded
    }
}

extension HTMapContainer {
    fileprivate func setupSubViews() {
        addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.edges()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        addSubview(recenterButton)
        recenterButtonBottomConstraint = recenterButton.bottom(constant: recenterButtonBottomSpacing)
        addConstraints([
            recenterButton.right(constant: recenterButtonRightSpacing),
            recenterButtonBottomConstraint!
            ])
        mapProvider.updatesDelegate = self
    }
}

extension HTMapContainer {
    fileprivate func addPanGesture(view: UIView?) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_ :)))
        view?.addGestureRecognizer(panGesture)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        
    }
}

extension HTMapContainer: HTKeyboardEvents {
}

protocol HTKeyboardEvents: NSObjectProtocol {
    var keyboardSize: CGSize { get set }
    var keyboardShown: Bool { get set }
}

extension HTMapContainer {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect)?.size {
            self.keyboardSize = keyboardSize
        }
        keyboardShown = true
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        keyboardShown = false
    }
    
    @objc func recenterButtonClicked() {
        mapProvider.centerMapOnAllAnnotations(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + HTProvider.animationDuration * 2) {
            self.isRecenterButtonHidden = true
        }
    }
    
    @objc func appDidBecomeActive(_ notification: Notification) {
        recenterButtonClicked()
    }
    
}

extension HTMapContainer: HTMapUseCaseDelegate {
    public func getBottomPadding() -> CGFloat {
        return bottomViewBottomConstraint?.constant ?? 0
    }
    
    public func updateBottomViewPosition(_ position: HTSwipePosition) -> CGFloat {
        lockZoom = true
        guard let bottomView = bottomView else {
            lockZoom = false
            return 0
        }
        self.position = position
        layoutSubviews()
        var bottomPadding: CGFloat = bottomView.bounds.height
        if let height = position.getHeight() {
            bottomPadding -= height
        } else {
            bottomViewBottomConstraint?.constant = bottomPadding
            bottomPadding = 0
        }
        layoutSubviews()
        UIView.animate(withDuration: HTProvider.animationDuration, delay: 0.1, options: .curveEaseInOut, animations: {
            self.bottomViewBottomConstraint?.constant = bottomPadding
            self.layoutSubviews()
        }, completion: { _ in
            self.lockZoom = false
            self.layoutSubviews()
        })
        return bottomPadding
    }
    
    public func setBottomView(_ view: UIView?, atPosition: HTSwipePosition) {
        lockZoom = true
        position = atPosition
        if let bottomView = bottomView {
            UIView.animate(withDuration: HTProvider.animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                self.bottomViewBottomConstraint?.constant = bottomView.bounds.height
                self.layoutSubviews()
            }, completion: { (_) in
                self.bottomView?.removeFromSuperview()
                self.bottomViewBottomConstraint?.isActive = false
                self.bottomViewBottomConstraint = nil
                self.bottomView = view
                self.lockZoom = false
            })
        } else {
            bottomView = view
            lockZoom = false
        }
    }
    
    public func cleanUp() {
        mapProvider.cleanUp()
    }
    
    public func addAnnotations(_ data: [HTAnnotationData]) {
        mapProvider.addAnnotations(data)
    }
    
    public func addPolyline(_ data: [HTPolylineData]) {
        mapProvider.addPolyline(data)
    }
    
    public func addTrailingPolyline(_ data: [HTTimeAwarePolyline]) {
        mapProvider.addTrailingPolyline(data)
    }
    
    public func updateMapVisibleRegion(_ insets: UIEdgeInsets) {
        mapProvider.updateMapVisibleRegion(insets)
    }
    
    public func setBottomView(_ view: UIView?) {
        position = .none
        if let bottomView = bottomView {
            UIView.animate(withDuration: HTProvider.animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                self.bottomViewBottomConstraint?.constant = bottomView.bounds.height
                self.layoutSubviews()
            }, completion: { (_) in
                self.bottomView?.removeFromSuperview()
                self.bottomView = view
            })
        } else {
            bottomView = view
        }
    }
    
    public func setPrimaryAction(_ view: UIView?, anchor: AnchorPosition) {
        primaryActionView?.removeFromSuperview()
        primaryActionView = view
        if let view = primaryActionView {
            view.alpha = 0
            addSubview(view)
            switch anchor {
            case .topLeft:
                addConstraints([
                    view.top(constant: 20),
                    view.left(constant: 15)
                    ])
            default:
                addConstraints([
                    view.top(constant: 20),
                    view.right(constant: -15)
                    ])
            }
            UIView.animate(withDuration: HTProvider.animationDuration, delay: 0, options: .curveEaseOut, animations: {
                view.alpha = 1
            }, completion: nil)
        }
    }
    
    public func setCenterFloatingView(_ view: UIView?, offset: CGPoint) {
        floatingView?.removeFromSuperview()
        floatingView = nil
        guard let view = view else { return }
        insertSubview(view, aboveSubview: mapView)
        addConstraints([
            view.centerX(constant: offset.x),
            view.centerY(constant: offset.y)
            ])
        floatingView = view
    }
    
    public func getCenterCoordinates() -> CLLocationCoordinate2D {
        return mapProvider.getCenterCoordinates()
    }
    
    public func showError(text: String?) {
        errorView?.removeFromSuperview()
        guard let text = text  else { return }
        errorView = HTErrorStatusView(text: text, showIn: self, anchor: .top, padding: 30, automaticallyDismiss: false)
    }
    
    public func setMapViewUpdatesDelegate(_ delegate: HTMapViewUpdatesDelegate?) {
        mapProvider.updatesDelegate = (delegate ?? self)
    }
    
    public func showCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
        mapProvider.showCoordinates(coordinates)
    }
}

extension HTMapContainer: HTMapViewUpdatesDelegate {
    public func mapViewDidChange(centerCoordinate: CLLocationCoordinate2D) {
        isRecenterButtonHidden = false
    }
}
