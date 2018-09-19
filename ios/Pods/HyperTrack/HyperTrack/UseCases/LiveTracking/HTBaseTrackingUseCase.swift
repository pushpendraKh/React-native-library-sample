//
//  HTBaseTrackingUseCase.swift
//  HyperTrack
//
//  Created by Atul Manwar on 13/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

@objc open class HTBaseUseCase: NSObject {
    public weak var delegate: HTBaseUseCaseDelegate?
    
    var isProcessing: Bool = false {
        didSet {
            delegate?.showLoader(isProcessing)
        }
    }
}

@objc open class HTBaseTrackingUseCase: HTBaseUseCase {
    fileprivate let viewModel: HTBaseTrackingViewModelProtocol
    private (set) var trackWithType: HTTrackWithTypeData? {
        didSet {
            startTimer(trackWithType)
        }
    }
    fileprivate var timer: Timer?
    public var pollDuration: Double = HTProvider.pollDuration
    public var isPollingEnabled: Bool {
        return (pollDuration > 0)
    }
    
    fileprivate var trackingCompletionHandler: HTTrackActionArrayCompletionHandler?

    public func update() {
        
    }
    
    @objc public init(viewModel: HTBaseTrackingViewModelProtocol?) {
        if let vm = viewModel {
            self.viewModel = vm
        } else {
            self.viewModel = HTBaseTrackingViewModel()
        }
        super.init()
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    public func stop() {
        stopTimer()
    }
    
    public func trackActionWithType(_ type: HTTrackWithTypeData, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        if pollDuration > 0 {
            trackingCompletionHandler = completionHandler
            self.pollDuration = pollDuration
            trackWithType = type
        } else {
            startTracking(type, completionHandler: completionHandler)
        }
    }
    
    public func trackActionWithIds(_ ids: [String], pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(ids: ids, type: .actionIds), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    public func trackActionWithCollectionId(_ id: String, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(id: id, type: .collectionId), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    public func trackActionWithUniqueId(_ id: String, pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(id: id, type: .uniqueId), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    public func trackActionWithShortCodes(_ codes: [String], pollDuration: Double = 0, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionWithType(HTTrackWithTypeData(ids: codes, type: .shortCode), pollDuration: pollDuration, completionHandler: completionHandler)
    }
    
    deinit {
        stopTimer()
    }
}

extension HTBaseTrackingUseCase {
    @objc fileprivate func trackAction() {
        startTracking(trackWithType) { [weak self] (actions, error) in
            guard self?.timer?.isValid == true else { return }
            self?.trackingCompletionHandler?(actions, error)
        }
    }
    
    fileprivate func startTracking(_ type: HTTrackWithTypeData?, completionHandler: HTTrackActionArrayCompletionHandler?) {
        guard let type = type else { return }
        switch type.type {
        case .actionIds:
            viewModel.trackActionWithIds(type.ids, completionHandler: completionHandler)
        case .collectionId:
            viewModel.trackActionWithCollectionId(type.ids.first ?? "", completionHandler: completionHandler)
        case .uniqueId:
            viewModel.trackActionWithUniqueId(type.ids.first ?? "", completionHandler: completionHandler)
        case .shortCode:
            viewModel.trackActionWithShortCodes(type.ids, completionHandler: completionHandler)
        }
    }
    
    fileprivate func startTimer(_ type: HTTrackWithTypeData?) {
        stopTimer()
        if let _ = type {
            timer = Timer.scheduledTimer(timeInterval: pollDuration, target: self, selector: #selector(trackAction), userInfo: nil, repeats: isPollingEnabled)
            timer?.fire()
        }
    }
}
