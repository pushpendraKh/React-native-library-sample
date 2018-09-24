//
 //  HTRequestManager.swift
 //  HyperTrack
 //
 //  Created by Tapan Pandita on 24/02/17.
 //  Copyright © 2017 HyperTrack, Inc. All rights reserved.
 //

 import Foundation
 import Alamofire
 import MapKit
 import Gzip
 import CocoaLumberjack


 class RequestManager {
    // Tested
    func getAction(_ actionId: String, completionHandler: @escaping HTActionCompletionHandler) {
        HTApiRouter.getAction(id: actionId).makeRequest { response in
            let data: (HTAction?, HTError?) = response.mapToModel()
            completionHandler(data.0, data.1)
        }
    }
    // Tested
    func getAction(_ type: HTTrackWithTypeData, completionHandler: @escaping HTActionArrayCompletionHandler) {
        let action: HTApiRouter!
        switch type.type {
        case .actionIds:
            action = HTApiRouter.getActionsByIds(ids: type.ids)
        case .collectionId:
            action = HTApiRouter.getActionsByCollectionId(collectionId: type.ids.first ?? "")
        case .uniqueId:
            action = HTApiRouter.getActionsByUniqueId(uniqueId: type.ids.first ?? "")
        case .shortCode:
            action = HTApiRouter.getActionsByShortCodes(codes: type.ids)
        }
        action.makeRequest { response in
            let data: (HTTrackResponse?, HTError?) = response.mapToModel()
            completionHandler(data.0?.actions, data.1)
        }
    }
    
    func trackAction(_ type: HTTrackWithTypeData, completionHandler: @escaping HTTrackActionArrayCompletionHandler) {
        let action: HTApiRouter!
        switch type.type {
        case .actionIds:
            action = HTApiRouter.trackActionsByIds(ids: type.ids)
        case .collectionId:
            action = HTApiRouter.trackActionsByCollectionId(collectionId: type.ids.first ?? "")
        case .uniqueId:
            action = HTApiRouter.trackActionsByUniqueId(uniqueId: type.ids.first ?? "")
        case .shortCode:
            action = HTApiRouter.trackActionsByShortCodes(codes: type.ids)
        }
        action.makeRequest { response in
            let data: (HTTrackResponse?, HTError?) = response.mapToModel()
            completionHandler(data.0?.actions, data.1)
        }
    }

    //Tested
    func createAction(_ action: [String: Any], completionHandler: @escaping HTActionCompletionHandler) {
        HTApiRouter.createAction(params: action).makeRequest { response in
            let data: (HTAction?, HTError?) = response.mapToModel()
            completionHandler(data.0, data.1)
        }
    }

    func assignActions(userId: String, _ params: [String: Any], completionHandler: @escaping (_ action: HTUser?,
        _ error: HTError?) -> Void) {
        HTApiRouter.assignActions(userId: userId, params: params).makeRequest { response in
            let data: (HTUser?, HTError?) = response.mapToModel()
            completionHandler(data.0, data.1)
        }
    }

    func patchActionInSynch(_ actionId: String, _ params: [String: Any], _ completionHandler: @escaping HTActionCompletionHandler) {
        HTApiRouter.patchAction(id: actionId, params: params).makeRequest { response in
            let data: (HTAction?, HTError?) = response.mapToModel()
            completionHandler(data.0, data.1)
        }

    }
    // Tested
    func editDestination(_ collectionId: String, _ params: [String: Any], _ completionHandler: @escaping HTActionCompletionHandler) {
        HTApiRouter.editDestination(collectionId: collectionId, params: params).makeRequest { response in
            let data: (HTAction?, HTError?) = response.mapToModel()
            completionHandler(data.0, data.1)
        }
    }
    // Tested
    func completeActionInSynch(_ actionId: String, params: [String: Any], completionHandler: @escaping HTActionCompletionHandler) {
        HTApiRouter.completeAction(id: actionId, params: params).makeRequest { response in
            let data: (HTAction?, HTError?) = response.mapToModel()
            completionHandler(data.0, data.1)
        }
    }
    func completeActionWithUniqueIdInSync(_ uniqueId: String, params: [String: Any], completionHandler: @escaping HTActionCompletionHandler) {
        HTApiRouter.completeActionWithUniqueId(uniqueId: uniqueId, params: params).makeRequest { response in
            let data: (HTAction?, HTError?) = response.mapToModel()
            completionHandler(data.0, data.1)
        }
    }
    // Tested
    func createUser(_ user: [String: Any], completionHandler: ((_ user: HTUser?, _ error: HTError?) -> Void)?) {
        HTApiRouter.createUser(params: user).makeRequest { response in
            let data: (HTUser?, HTError?) = response.mapToModel()
            completionHandler?(data.0, data.1)
        }
    }

    func updateUser(_ id: String, params: [String: Any], completionHandler: ((_ user: HTUser?, _ error: HTError?) -> Void)?) {
        HTApiRouter.updateUser(id: id, params: params).makeRequest { response in
            let data: (HTUser?, HTError?) = response.mapToModel()
            if let id = data.0?.id, !id.isEmpty {
                completionHandler?(data.0, data.1)
            } else {
                completionHandler?(nil, HTError(HTErrorType.userIdError))
            }
        }
    }

    func cancelActions(userId: String, completionHandler: ((_ user: HTUser?, _ error: HTError?) -> Void)?) {
        HTApiRouter.cancelActions(userId: userId).makeRequest { response in
            let data: (HTUser?, HTError?) = response.mapToModel()
            completionHandler?(data.0, data.1)
        }
    }
    // Tested
    func registerDeviceToken(userId: String, deviceId: String, registrationId: String, completionHandler: ((_ error: HTError?) -> Void)?) {
        HTApiRouter.registerDeviceToken(userId: userId, deviceId: deviceId, registrationId: registrationId).makeRequest { response in
            let data: (HTBasicModel?, HTError?) = response.mapToModel()
            completionHandler?(data.1)
        }
    }

    func getSDKControls(userId: String, completionHandler: ((_ controls: HTSDKControls?, _ error: HTError?) -> Void)?) {
        HTApiRouter.getSdkControls(userId: userId).makeRequest { response in
            let data: (HTSDKControls?, HTError?) = response.mapToModel()
            completionHandler?(data.0, data.1)
        }
    }

    func getSimulatePolyline(originLatlng: String, destinationLatLong: String? = nil, completionHandler: ((_ polyline: String?, _ error: HTError?) -> Void)?) {
        HTApiRouter.simulatePolyline(origin: originLatlng, destination: destinationLatLong).makeRequest { response in
            let data: (HTBasicModel?, HTError?) = response.mapToModel()
            completionHandler?(data.0?.dict["time_aware_polyline"] as? String, data.1)
        }
    }
    // Tested
    func findPlaces(searchText: String, cordinate: CLLocationCoordinate2D, completionHandler: ((_ places: [HTPlace]?, _ error: HTError?) -> Void)?) {
        HTApiRouter.autocompletePlaces(query: searchText, lat: cordinate.latitude, lng: cordinate.longitude).makeRequest { response in
            let data: ([HTPlace]?, HTError?) = response.mapToArray()
            completionHandler?(data.0, data.1)
        }
    }
    // Tested
    func createPlace(geoJson: HTGeoJSONLocation, completionHandler: ((_ place: HTPlace?, _ error: HTError?) -> Void)?) {
        HTApiRouter.createPlace(place: geoJson.toDict()).makeRequest { response in
            let data: (HTPlace?, HTError?) = response.mapToModel()
            completionHandler?(data.0, data.1)
        }
    }
    // Tested
    func getUserPlaceline(date: Date? = nil, userId: String, completionHandler: ((_ placeline: HTPlaceline?, _ error: HTError?) -> Void)?) {
        HTApiRouter.placeline(userId: userId, date: HTSpaceTimeUtil.instance.getFormattedDate("yyyy-MM-dd", date: date ?? Date())).makeRequest { response in
            let data: (HTPlaceline?, HTError?) = response.mapToModel()
            completionHandler?(data.0, data.1)
        }
    }
    // Tested
    func getPendingActions(_ userId: String, completionHandler: @escaping HTActionArrayCompletionHandler) {
        HTApiRouter.getPendingActions(userId: userId).makeRequest { (response) in
            let data: ([HTAction]?, HTError?) = response.mapToArray()
            completionHandler(data.0, data.1)
        }
    }
}
