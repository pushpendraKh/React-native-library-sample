//
//  HTShareEtaUseCase.swift
//  HyperTrack
//
//  Created by Atul Manwar on 05/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

public typealias HTPlaceCompletionHandler = ([HTPlace]?, HTError?) -> Void

@objc public protocol HTShareEtaViewModelProtocol: HTBaseViewModelProtocol {
    func getAutocompleteResults(_ query: String, coordinate: CLLocationCoordinate2D, completionHandler: HTPlaceCompletionHandler?)
    func createPlace(geoJson: HTGeoJSONLocation, completionHandler: ((_ place: HTPlace?, _ error: HTError?) -> Void)?)
}

@objc public class HTShareEtaUseCaseViewModel: NSObject, HTShareEtaViewModelProtocol {
    fileprivate var findPlacesDebouncedOperation: HTDebouncer?
    fileprivate var createPlaceDebouncedOperation: HTDebouncer?
    fileprivate var findPlacesQueue: OperationQueue?
    fileprivate var createPlaceQueue: OperationQueue?
    fileprivate var query = ""
    fileprivate var coordinate: CLLocationCoordinate2D?
    fileprivate var findPlacesCompletionHandler: HTPlaceCompletionHandler?
    fileprivate var createPlaceCompletionHandler: ((_ place: HTPlace?, _ error: HTError?) -> Void)?
    fileprivate var geoJson: HTGeoJSONLocation?

    public override init() {
        super.init()
        findPlacesQueue = OperationQueue()
        findPlacesDebouncedOperation = HTDebouncer(delay: 0.6, callback: { [weak self] in
            guard let `self` = self else { return }
            guard self.query.count > 2,  let coordinate = self.coordinate, let completionHandler = self.findPlacesCompletionHandler else { return }
            self.findPlacesQueue?.cancelAllOperations()
            self.findPlacesQueue?.addOperation {
                HypertrackService.sharedInstance.findPlaces(searchText: self.query, cordinate: coordinate, completionHandler: { (places, error) in
                    completionHandler(places, error)
                })
            }
        })
        
        createPlaceQueue = OperationQueue()
        createPlaceDebouncedOperation = HTDebouncer(delay: 1, callback: { [weak self] in
            guard let `self` = self, let geoJson = self.geoJson, let completionHandler = self.createPlaceCompletionHandler else { return }
            self.createPlaceQueue?.cancelAllOperations()
            self.createPlaceQueue?.addOperation {
                HypertrackService.sharedInstance.createPlace(geoJson: geoJson, completionHandler: { (place, error) in
                    completionHandler(place, error)
                })
            }
        })
    }

    public func getAutocompleteResults(_ query: String, coordinate: CLLocationCoordinate2D, completionHandler: HTPlaceCompletionHandler?) {
        self.query = query
        self.coordinate = coordinate
        findPlacesCompletionHandler = completionHandler
        findPlacesDebouncedOperation?.call()
    }
    
    public func createPlace(geoJson: HTGeoJSONLocation, completionHandler: ((_ place: HTPlace?, _ error: HTError?) -> Void)?) {
        self.geoJson = geoJson
        createPlaceCompletionHandler = completionHandler
        createPlaceDebouncedOperation?.call()
    }
}

@objc open class HTPlaceSelectionUseCase: NSObject, HTMapViewUseCase {
    public weak var mapDelegate: HTMapUseCaseDelegate? {
        didSet {
            bottomView.setContentView(provider.contentView)
            provider.contentView.edges()
            mapDelegate?.setBottomView(bottomView)
            mapDelegate?.setMapViewUpdatesDelegate(self)
            mapDelegate?.setPrimaryAction(primaryActionButton, anchor: .topLeft)
            provider.clear()
        }
    }
    fileprivate (set) var isProcessing: Bool = false {
        didSet {
        }
    }
    public weak var navigationDelegate: HTUseCaseNavigationDelegate?
    public weak var delegate: HTPlaceSelectionDelegate?
    fileprivate var provider: HTLocationSearchProviderProtocol!
    public private (set) var bottomView: HTBottomViewContainer!
    fileprivate var viewModel: HTShareEtaViewModelProtocol!
    fileprivate var selectedPlace: HTPlace?
    fileprivate lazy var confirmLocationView: HTConfirmLocationView = {
        let view = HTConfirmLocationView(frame: .zero, padding: HTPaddingProvider(top: 35, left: 35, right: 35, bottom: 35, verticalInterItem: 15, horizontalInterItem: 0))
        view.delegate = self
        return view
    }()
    fileprivate var setOnMapInProgress = false
    
    public lazy var primaryActionButton: UIButton = {
        return self.createButtonForImage(UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.crossButton), rounded: true)
    }()

    public var isPrimaryActionHidden: Bool = false {
        didSet {
            primaryActionButton.isHidden = isPrimaryActionHidden
        }
    }
    
    @objc public var searchBarPlaceHolderText: String = "" {
        didSet {
            guard provider != nil else { return }
            provider.searchBarPlaceHolderText = searchBarPlaceHolderText
        }
    }
    
    @objc public var enableCurrentLocationSelection: Bool = true {
        didSet {
            guard provider != nil else { return }
            provider.enableCurrentLocationSelection = enableCurrentLocationSelection
        }
    }
    
    @objc public var enableChooseOnMapSelection: Bool  = true {
        didSet {
            guard provider != nil else { return }
            provider.enableChooseOnMapSelection = enableChooseOnMapSelection
        }
    }

    var coordinate: CLLocationCoordinate2D
    
    @objc public convenience init(coordinates: CLLocationCoordinate2D) {
        self.init(nil, provider: nil, coordinate: coordinates)
    }
    
    @objc public convenience override init() {
        self.init(nil, provider: nil, coordinate: HyperTrack.getCurrentLocation()?.coordinate ?? .zero)
    }
    
    @objc public convenience required init(mapDelegate: HTMapUseCaseDelegate?) {
        self.init(nil, provider: nil, coordinate: HyperTrack.getCurrentLocation()?.coordinate ?? .zero)
        self.mapDelegate = mapDelegate
    }
    
    public init(_ viewModel: HTShareEtaViewModelProtocol? = nil, provider: HTLocationSearchProviderProtocol? = nil, coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        self.provider = provider ?? HTLocationSearchProvider([])
        self.viewModel = viewModel ?? HTShareEtaUseCaseViewModel()
        bottomView = HTViewFactory.createBottomViewContainer()
        super.init()
        self.provider.delegate = self
    }
    
    public func update() {
        
    }
}

extension HTPlaceSelectionUseCase: HTShareEtaDelegate {
    public func cancelClicked() {
        delegate?.cancelClicked()
    }
    
    public func primaryActionClicked(_ data: Int) {
        delegate?.expectedPlaceSet(provider.data[data])
    }
    
    public func handleSpecialCase(_ selection: HTLocationSearchProvider.SearchLocationType) {
        switch selection {
        case .current:
            isProcessing = true
            let geoJson = HTGeoJSONLocation(type: "Point", coordinates: coordinate)
            viewModel.createPlace(geoJson: geoJson, completionHandler: { [weak self] (response, error) in
                if let data = response {
                    self?.delegate?.expectedPlaceSet(data)
                } else {
                    self?.mapDelegate?.showError(text: error?.displayErrorMessage)
                }
            })
            break
        case .usingMap:
            setOnMapInProgress = true
            mapDelegate?.cleanUp()
            mapDelegate?.showCurrentLocation = false
            bottomView.setContentView(confirmLocationView)
            confirmLocationView.edges()
            mapDelegate?.setBottomView(bottomView)
            let image = UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.floatingIcon)
            let imageView = UIImageView(image: image)
//            imageView.addConstraints([
//                imageView.width(constant: 20),
//                imageView.height(constant: 20),
//                ])
            var offset = CGPoint.zero
            if let image = image {
                offset = CGPoint(x: 0, y: -image.size.height/2)
            }
            mapDelegate?.setCenterFloatingView(imageView, offset: offset)
        default:
            break
        }
    }
    
    public func updatedQuery(_ query: String) {
        self.viewModel.getAutocompleteResults(query, coordinate: coordinate) { (response, error) in
            if let data = response {
                self.provider.updateData(data)
                self.provider.reloadData()
            } else {
                self.mapDelegate?.showError(text: error?.displayErrorMessage)
            }
        }
    }
}

extension HTPlaceSelectionUseCase: HTConfirmLocationDelegate {
    func actionPerformed() {
        mapDelegate?.setCenterFloatingView(nil, offset: .zero)
        bottomView.setContentView(provider.contentView)
        provider.contentView.edges()
        setOnMapInProgress = false
        mapDelegate?.showCurrentLocation = true
        if let data = selectedPlace {
            delegate?.expectedPlaceSet(data)
        } else {
            delegate?.cancelClicked()
        }
    }
}

extension HTPlaceSelectionUseCase: HTMapViewUpdatesDelegate {
    public func mapViewDidChange(centerCoordinate: CLLocationCoordinate2D) {
        guard setOnMapInProgress else { return }
        let geoJson = HTGeoJSONLocation(type: "Point", coordinates: centerCoordinate)
        confirmLocationView.actionButton.isUserInteractionEnabled = false
        viewModel.createPlace(geoJson: geoJson, completionHandler: { [weak self] (response, error) in
            if let data = response {
                self?.selectedPlace = data
                self?.confirmLocationView.titleText = data.displayName
                self?.confirmLocationView.actionButton.isUserInteractionEnabled = true
            } else {
                self?.mapDelegate?.showError(text: error?.displayErrorMessage)
                self?.confirmLocationView.actionButton.isUserInteractionEnabled = false
            }
        })
    }
}

extension HTPlaceSelectionUseCase: HTUseCaseBackNavigationProtocol {
    public func performActionOnButtonClick() {
        mapDelegate?.setPrimaryAction(nil, anchor: .topLeft)
        mapDelegate?.setCenterFloatingView(nil, offset: .zero)
        navigationDelegate?.backClicked()
        delegate?.cancelClicked()
    }
}
