//
//  HTActionService.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit

class HTActionService: NSObject {

    static let sharedInstance = HTActionService()

    let requestManager: RequestManager

    override init() {
        self.requestManager = RequestManager()
    }

    func getAction(_ actionId: String, _ completionHandler: @escaping HTActionCompletionHandler) {
        self.requestManager.getAction(actionId, completionHandler: completionHandler)
    }
    
    func getActionsForCollectionId(_ collectionId: String, _ completionHandler: @escaping HTActionArrayCompletionHandler) {
        self.requestManager.getAction(HTTrackWithTypeData(id: collectionId, type: .collectionId ), completionHandler: completionHandler)
    }
    
    func getActionsForUniqueId(_ uniqueId: String, _ completionHandler: @escaping HTActionArrayCompletionHandler) {
        self.requestManager.getAction(HTTrackWithTypeData(id: uniqueId, type: .uniqueId ), completionHandler: completionHandler)
    }

    func getActionsForShortCode(_ shortCode: String, _ completionHandler: @escaping (_ action: [HTAction]?, _ error: HTError?) -> Void) {
        self.requestManager.getAction(HTTrackWithTypeData(id: shortCode, type: .shortCode ), completionHandler: completionHandler)
    }

    func createAction(_ actionParams: HTActionParams, _ completionHandler: @escaping HTActionCompletionHandler) {
        if HyperTrack.getUserId() != nil {
            HyperTrack.resumeTracking()
        }
        var action: [String: Any] = actionParams.toDict()
        HTSDKDataManager.sharedInstance.getCurrentLocation(completionHandler: { (currentLocation, _) in
            if currentLocation != nil {
                action["current_location"] = HTLocation.init(locationCoordinate: currentLocation!.coordinate,
                                                                     timeStamp: Date()).toDict()
            }
        })

        requestManager.createAction(action, completionHandler: completionHandler)
    }

    func assignActions(_ actionIds: [String], _ completionHandler: @escaping (_ action: HTUser?,
        _ error: HTError?) -> Void) {
        if actionIds.isEmpty {
            completionHandler(nil, HTError(HTErrorType.invalidParamsError))
            return
        }

        guard let userId = HTUserService.sharedInstance.userId else {
            completionHandler(nil, HTError(HTErrorType.userIdError))
            return
        }

        var params = [
            "action_ids": actionIds as Any
            ] as [String: Any]

        HTSDKDataManager.sharedInstance.getCurrentLocation(completionHandler: { (currentLocation, _) in
            if currentLocation != nil {
                params["current_location"] = HTLocation.init(locationCoordinate: currentLocation!.coordinate,
                                                                     timeStamp: Date()).toDict()
            }
        })

        requestManager.assignActions(userId: userId, params, completionHandler: completionHandler)
    }

    func completeAction(actionId: String) {
        HTSDKDataManager.sharedInstance.saveActionCompletedEvent(actionId: actionId)
    }

    func completeActionInSync(actionId: String, completionHandler: @escaping HTActionCompletionHandler) {
        let params: HTPayload = ["completion_time": Date().iso8601, "completion_location": HTGeoJSONLocation(type: "Point", coordinates: HyperTrack.getCurrentLocation()?.coordinate ?? .zero).toDict()]
        self.requestManager.completeActionInSynch(actionId, params: params, completionHandler: completionHandler)
    }
    
    func completeActionWithUniqueIdInSync(uniqueId: String, completionHandler: @escaping HTActionCompletionHandler) {
        let params: HTPayload = ["completion_time": Date().iso8601, "completion_location": HTGeoJSONLocation(type: "Point", coordinates: HyperTrack.getCurrentLocation()?.coordinate ?? .zero).toDict()]
        self.requestManager.completeActionWithUniqueIdInSync(uniqueId, params: params, completionHandler: completionHandler)
    }

    func completeActionWithUniqueId(uniqueId: String) {
        HTSDKDataManager.sharedInstance.saveActionCompletedEvent(uniqueId: uniqueId)
    }

    func patchExpectedPlaceInAction(actionId: String, newExpectedPlaces: HTPlace, _ completionHandler: @escaping HTActionCompletionHandler) {
        let action = ["expected_place": newExpectedPlaces.toDict() as Any] as [String: Any]
        self.requestManager.patchActionInSynch(actionId, action, completionHandler)
    }
    
    func editDestination(collectionId: String, newExpectedPlace: HTPlace, _ completionHandler: @escaping HTActionCompletionHandler) {
        let params = ["expected_place": newExpectedPlace.toDict() as Any] as [String: Any]
        self.requestManager.editDestination(collectionId, params, completionHandler)
    }

    func cancelPendingActions(completionHandler: ((_ user: HTUser?, _ error: HTError?) -> Void)?) {
        guard let userId = HTUserService.sharedInstance.userId else {
            if let completion = completionHandler {
                completion(nil, HTError.init(HTErrorType.invalidParamsError))
            }
            return
        }

        self.requestManager.cancelActions(userId: userId, completionHandler: completionHandler)
    }

    /**
     Method to track Action for an ActionID
     */
    func trackActionFor(actionId: String, completionHandler: HTTrackActionCompletionHandler?) {
        trackActionFor(type: HTTrackWithTypeData(id: actionId, type: .actionIds)) { (response, error) in
            completionHandler?(response?.filter({$0.id == actionId}).first, error)
        }
    }

    /**
     Method to track Action for an action's Short code
     */
    func trackActionFor(shortCode: String, completionHandler: HTTrackActionCompletionHandler?) {
        trackActionFor(type: HTTrackWithTypeData(id: shortCode, type: .shortCode)) { (response, error) in
            completionHandler?(response?.first, error)
        }
    }

    /**
     Method to track Action for an action's collection id
     */
    func trackActionFor(collectionId: String, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionFor(type: HTTrackWithTypeData(id: collectionId, type: .collectionId)) { (actions, error) in
            completionHandler?(actions, error)
        }
    }

    /**
     Method to track Action for an action's UniqueId
     */
    func trackActionFor(uniqueId: String, completionHandler: HTTrackActionArrayCompletionHandler?) {
        trackActionFor(type: HTTrackWithTypeData(id: uniqueId, type: .uniqueId)) { (actions, error) in
            completionHandler?(actions, error)
        }
    }

    func isActionTrackable(actionId: String!, completionHandler: @escaping (_ isTrackable: Bool, _ error: HTError?) -> Void ) {
        self.getAction(actionId) { (action, error) in
            guard let trackable = action?.actionStatus.isCompleted else {
                completionHandler(false, error)
                return
            }
            completionHandler(trackable, nil)
        }
    }
    
    /**
     Call this method to track an Action on MapView embedded in your screen
     
     - Parameter type: Pass the action type to be tracked on the mapView
     - Parameter completionHandler: Pass instance of completion block as parameter
     */
    func trackActionFor(type: HTTrackWithTypeData, completionHandler: @escaping HTTrackActionArrayCompletionHandler) {
        requestManager.trackAction(type, completionHandler: completionHandler)
    }
}
