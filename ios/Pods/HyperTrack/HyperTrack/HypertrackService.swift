//
//  HypertrackService.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation
import CocoaLumberjack
//import Sentry

class HypertrackService: NSObject {

    static let sharedInstance = HypertrackService()

    let requestManager: RequestManager
    let pushNotificationService: PushNotificationService
    var hasTrackingStarted = false
    override init() {
        self.requestManager = RequestManager()
        self.pushNotificationService = PushNotificationService()
        super.init()
        self.pushNotificationService.delegate = self
    }

    func setPublishableKey(publishableKey: String) {
        Settings.setPublishableKey(publishableKey: publishableKey)
        initializeSentry()
        initialize()
    }

    func getPublishableKey() -> String? {
        return Settings.getPublishableKey()
    }
    
    var isTracking: Bool {
        get {
            return Settings.getTracking()
        }
    }
    
    var isMockTracking: Bool {
        get {
            return Settings.getMockTracking()
        }
    }
    
    func initializeSentry(){
//        // Create a Sentry client and start crash handler
//        do {
//            Client.shared = try Client(dsn: "https://4ae0bb082d3542c38e6e217274545356:dcc72e9b7a814c88a20bed51207febb3@sentry.io/114935")
//            try Client.shared?.startCrashHandler()
//        } catch let error {
//            print("\(error)")
//            // Wrong DSN or KSCrash not installed
//        }
    }
    
    func canStartTracking(completionHandler: ((_ error: HTError?) -> Void)?) -> Bool {
        if (HTUserService.sharedInstance.userId == nil) {
            DDLogError("Can't start tracking. Need userId.")
            let error = HTError(HTErrorType.userIdError)
            guard let completionHandler = completionHandler else { return false }
            completionHandler(error)
            return false
        } else if (Settings.getPublishableKey() == nil) {
            DDLogError("Can't start tracking. Need publishableKey.")
            let error = HTError(HTErrorType.publishableKeyError)
            guard let completionHandler = completionHandler else { return false }
            completionHandler(error)
            return false
        }
        return true
    }
    
    func initialize() {
        HTLogger.shared.initialize()
//        DDLogInfo("Initialize transmitter")
//        if self.isTracking {
//            self.startTracking(completionHandler: nil)
//        }
    }
    
    func startTracking(byUser: Bool, completionHandler: ((_ error: HTError?) -> Void)?) {
        
        if !canStartTracking(completionHandler: completionHandler) {
            return
        }
        
        if isMockTracking {
            // If mock tracking is active, the normal tracking flow will
            // not continue and throw an error.
            // TODO: better error message
            guard let completionHandler = completionHandler else { return }
            let error = HTError(HTErrorType.invalidParamsError)
            completionHandler(error)
            return
        }
       
        if !hasTrackingStarted{
            if !Settings.getTracking() {
                HTSDKDataManager.sharedInstance.locationManager.requestLocation()
            }
            
            HTSDKDataManager.sharedInstance.startTracking(byUser: byUser, completionHandler: completionHandler)
            HTSDKControlsService.sharedInstance.setUpControls()
            HTTransmissionService.sharedInstance.setUpTransmissionControls()
            hasTrackingStarted = true
            guard let completionHandler = completionHandler else { return }
            completionHandler(nil)
        }else{
            guard let completionHandler = completionHandler else { return }
            completionHandler(nil)
        }
    }
    
    func createMockAction(origin: HTLocationCoordinate?, destination: HTLocationCoordinate?, params: HTActionParams, completionHandler: @escaping (_ action: HTAction?, _ error: HTError?) -> Void) {
        if !canStartTracking(completionHandler: { (error) in
            completionHandler(nil, error)
        }) {
            return
        }
        if isTracking {
            // If tracking is active, the mock tracking will
            // not continue and throw an error.
            completionHandler(nil, HTError(HTErrorType.invalidParamsError))
            return
        }
        if !hasTrackingStarted {
            let origin =  origin?.coordinates ?? HyperTrack.getCurrentLocation()?.coordinate
            var destination = destination?.coordinates
            if destination == nil, params.expectedPlace?.location?.coordinates.count == 2, let lng = params.expectedPlace?.location?.coordinates.first, let lat = params.expectedPlace?.location?.coordinates.last {
                destination = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            }
            hasTrackingStarted = true
            HTSDKDataManager.sharedInstance.startMockTracking(origin: origin, destination: destination, completionHandler: { [weak self] (error) in
                if error != nil {
                    completionHandler(nil, error)
                } else {
                    var dict = params.toDict()
                    dict["metadata"] = ["mock_tracking": true]
                    self?.requestManager.createAction(dict, completionHandler: { (action, error) in
                        completionHandler(action, error)
                    })
                }
            })
        }
    }
    
    func completeMockAction(actionId: String?, completionHandler: @escaping (_ action: HTAction?, _ error: HTError?) -> Void) {
        hasTrackingStarted = false
        HTSDKDataManager.sharedInstance.stopMockTracking()
        if let actionId = actionId, !actionId.isEmpty {
            HTActionService.sharedInstance.completeActionInSync(actionId: actionId, completionHandler: completionHandler)
        }
    }
    
    func stopTracking(byUser: Bool, completionHandler: ((_ error: HTError?) -> Void)?) {
        hasTrackingStarted = false
        HTSDKDataManager.sharedInstance.stopTracking(byUser: byUser)
        if let completionBlock = completionHandler{
            completionBlock(nil)
        }
    }
}

extension HypertrackService: PushNotificationDelegate{
    
    func didRecieveNotificationForSDKControls(){
        HTSDKControlsService.sharedInstance.onServerNotification()
    }
}

extension HypertrackService {
    
    func findPlaces(searchText: String, cordinate: CLLocationCoordinate2D, completionHandler: ((_ places: [HTPlace]?, _ error: HTError?) -> Void)?) {
        self.requestManager.findPlaces(searchText: searchText, cordinate: cordinate, completionHandler: completionHandler)
    }
    
    func createPlace(geoJson: HTGeoJSONLocation, completionHandler: ((_ place: HTPlace?, _ error: HTError?) -> Void)?) {
        self.requestManager.createPlace(geoJson: geoJson, completionHandler: completionHandler)
    }
}
