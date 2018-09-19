//
//  HTBaseTrackingViewModel.swift
//  HyperTrack
//
//  Created by Atul Manwar on 13/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public protocol HTBaseTrackingViewModelProtocol: HTBaseViewModelProtocol {
    func completeAction(_ id: String, completionHandler: HTActionCompletionHandler?)
    func trackActionWithIds(_ ids: [String], completionHandler: HTTrackActionArrayCompletionHandler?)
    func trackActionWithCollectionId(_ id: String, completionHandler: HTTrackActionArrayCompletionHandler?)
    func trackActionWithUniqueId(_ id: String, completionHandler: HTTrackActionArrayCompletionHandler?)
    func trackActionWithShortCodes(_ codes: [String], completionHandler: HTTrackActionArrayCompletionHandler?)
    func addExpectedPlace(actionId: String, newPlace: HTPlace, completionHandler: HTActionCompletionHandler?)
    func addExpectedPlace(collectionId: String, newPlace: HTPlace, completionHandler: HTActionCompletionHandler?)
}

@objc public class HTBaseTrackingViewModel: NSObject, HTBaseTrackingViewModelProtocol {
    public func trackActionWithIds(_ ids: [String], completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackAction(HTTrackWithTypeData(ids: ids, type: .actionIds), completionHandler: completionHandler)
    }
    
    public func trackActionWithCollectionId(_ id: String, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackAction(HTTrackWithTypeData(id: id, type: .collectionId), completionHandler: completionHandler)
    }
    
    public func trackActionWithUniqueId(_ id: String, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackAction(HTTrackWithTypeData(id: id, type: .uniqueId), completionHandler: completionHandler)
    }
    
    public func trackActionWithShortCodes(_ codes: [String], completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackAction(HTTrackWithTypeData(ids: codes, type: .shortCode), completionHandler: completionHandler)
    }
    
    public func addExpectedPlace(actionId: String, newPlace: HTPlace, completionHandler: HTActionCompletionHandler?) {
        HTActionService.sharedInstance.patchExpectedPlaceInAction(actionId: actionId, newExpectedPlaces: newPlace) { (response, error) in
            completionHandler?(response, error)
        }
    }
    
    public func addExpectedPlace(collectionId: String, newPlace: HTPlace, completionHandler: HTActionCompletionHandler?) {
        HTActionService.sharedInstance.editDestination(collectionId: collectionId, newExpectedPlace: newPlace) { (response, error) in
            completionHandler?(response, error)
        }
    }
    
    public func completeAction(_ id: String, completionHandler: HTActionCompletionHandler?) {
        HTActionService.sharedInstance.completeActionInSync(actionId: id) { (response, error) in
            completionHandler?(response, error)
        }
    }

    fileprivate func trackAction(_ type: HTTrackWithTypeData, completionHandler: HTTrackActionArrayCompletionHandler?) {
        HTActionService.sharedInstance.trackActionFor(type: type) { (response, error) in
            completionHandler?(response, error)
        }
    }
}
