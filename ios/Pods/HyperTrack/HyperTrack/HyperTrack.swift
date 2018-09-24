//
//  Hypertrack.swift
//  HyperTrack
//
//  Created by Pratik Naik on 2/17/17.
//  Copyright © 2017 Pratik Naik. All rights reserved.
//

import Foundation
import MapKit
import CoreMotion
import CocoaLumberjack
//import Sentry

/**
 HyperTrack is the easiest way to build live location features in your application.
 The SDK is built to collect accurate location data with battery efficiency.
 The SDK has methods to start and stop tracking, and implement use-cases like order tracking, mileage tracking.
 For more information, visit http://docs.hypertrack.com
 */
@objc public class HyperTrack: NSObject {
    
    /**
     Call this method to initialize HyperTrack SDKs with your Account's PublishableKey
     in the application didFinishLaunchingWithOptions delegate method
     
     - Parameter publishableKey: Your account's publishable key
     */
    @objc public class func initialize(_ publishableKey: String) {
        HypertrackService.sharedInstance.setPublishableKey(publishableKey: publishableKey)
    }
    
    /**
     Call this method to get the publishableKey set on the HyperTrack SDK
     
     - Returns: The publishableKey configured on the SDK
     */
    @objc public class func getPublishableKey() -> String? {
        return HypertrackService.sharedInstance.getPublishableKey()
    }
    
    /**
     Call this method to start tracking on the SDK. This starts the location service if needed.
     
     - Requires: A userId (either through `setUserId` or `createUser`) and a publishable key(through `initialize`) to be set.
     */
    @objc public class func resumeTracking() {
        HTUserService.sharedInstance.startTracking(byUser: true, completionHandler: nil)
    }
    
    /**
     Call this method to start tracking on the SDK. This starts the location service if needed.
     
     - Parameter completionHandler: The completion handler which is called with an error if there is an error starting
     - Requires: A userId (either through `setUserId` or `createUser`) and a publishable key(through `initialize`) to be set.
     */
    @objc public class func resumeTracking(completionHandler: @escaping (_ error: HTError?) -> Void) {
        HTUserService.sharedInstance.startTracking(byUser: true, completionHandler: completionHandler)
    }
    
    /**
     Call this method to get the UserId set on the HyperTrack SDK
     
     - Returns: The userId configured on the SDK
     */
    @objc public class func getUserId() -> String? {
        return HTUserService.sharedInstance.userId
    }
    
    /**
     This attribute refers to the current tracking status of the SDK.
     
     - Returns: A boolean representing if the SDK is currently tracking the User
     */
    @objc public class var isTracking: Bool {
        get {
            return HypertrackService.sharedInstance.isTracking
        }
    }
    
    /**
     Call this method to fetch user's current location.
     
     - Parameter completionHandler: The completion handler which is called
     with the fetched location (CLLocation) on success or an error on failure
     */
    @objc public class func getCurrentLocation(completionHandler: @escaping (_ currentLocation: CLLocation?,
        _ error: HTError?) -> Void) {
        HTSDKDataManager.sharedInstance.getCurrentLocation(completionHandler: completionHandler)
    }

    /**
     Call this method to get or create a User on HyperTrack API Server for the current device
     with given unique_id. Refer to the documentation on creating a user
     
     - Parameter userName : Name of the user
     - Parameter phone: E164 formatted phone number of the user
     - Parameter uniqueId: A unique id that you can add to the user to search
     - Parameter completionHandler: The completion handler which is called with the newly created user on success or an error on failure
     */
    @objc public class func getOrCreateUser(name: String, phone: String, uniqueId: String, completionHandler: @escaping (_ user: HTUser?, _ error: HTError?) -> Void) {
        HTUserService.sharedInstance.createUser(name, phone, uniqueId, completionHandler)
    }
    
    @objc public class func getUser(id: String, completionHandler: @escaping (_ user: HTUser?, _ error: HTError?) -> Void) {
        HTUserService.sharedInstance.createUser(id: id, completionHandler: completionHandler)
    }
    /**
     Call this method to get or create a User on HyperTrack API Server for the current device
     with given unique_id. Refer to the documentation on creating a user
     
     - Parameter userName : Name of the user
     - Parameter phone: E164 formatted phone number of the user
     - Parameter uniqueId: A unique id that you can add to the user to search
     - Parameter photo: Image of the user
     - Parameter completionHandler: The completion handler which is called with the newly created user on success or an error on failure
     */
    @objc public class func getOrCreateUser(name: String, phone: String, uniqueId: String, photo: UIImage?, completionHandler: @escaping (_ user: HTUser?, _ error: HTError?) -> Void) {
        HTUserService.sharedInstance.createUser(name, phone, uniqueId, photo, completionHandler)
    }
    
    /**
     Call this method to update a User on HyperTrack API Server for the current user. Refer to the documentation on creating a user
     
     - Parameter name : updated name of the user
     - Parameter phone: (optional) updated E164 formatted phone number of the user
     - Parameter uniqueId: (optional) updated unique id that you can add to the user to search
     - Parameter photo: (optional) updated image of the user
     - Parameter completionHandler: The completion handler which is called with the updated user on success or an error on failure
     */    
    @objc public class func updateUser(name: String, phone: String? = nil, uniqueId: String? = nil, photo: UIImage? = nil, completionHandler: @escaping (_ user: HTUser?, _ error: HTError?) -> Void) {
        HTUserService.sharedInstance.updateUser(name, phone, uniqueId, photo, completionHandler)
    }
    
    /**
     Call this method to create and assign an Action to the current user.
     
     - Parameter actionParams: Pass instance of HTActionParams
     - Parameter callback: Pass instance of HyperTrack callback as parameter
     */
    @objc public class func createAction(_ actionParams: HTActionParams, _ completionHandler: @escaping (_ action: HTAction?, _ error: HTError?) -> Void) {
        HTActionService.sharedInstance.createAction(actionParams, completionHandler)
    }

    /**
     Call this method to get action model for a given actionId
     
     - Parameter actionId: Pass the action's unique id generated on HyperTrack API Server
     - Parameter completionHandler: Pass instance of HyperTrack callback as parameter
     */
    @objc public class func getActionFor(actionId: String, completionHandler: @escaping (_ action: HTAction?, _ error: HTError?) -> Void) {
        HTActionService.sharedInstance.getAction(actionId, completionHandler)
    }
    
    @objc public class func getActionsFor(collectionId: String, completionHandler: @escaping (_ action: [HTAction]?, _ error: HTError?) -> Void) {
        HTActionService.sharedInstance.getActionsForCollectionId(collectionId, completionHandler)
    }
    
    @objc public class func getActionsFor(uniqueId: String, _ completionHandler: @escaping (_ action: [HTAction]?, _ error: HTError?) -> Void) {
        HTActionService.sharedInstance.getActionsForUniqueId(uniqueId, completionHandler)
    }
    
    @objc public class func getActionsFor(shortCode: String, _ completionHandler: @escaping (_ action: [HTAction]?, _ error: HTError?) -> Void) {
        HTActionService.sharedInstance.getActionsForShortCode(shortCode, completionHandler)
    }

    /**
     Call this method to track an Action on MapView embedded in your screen
     
     - Parameter actionId:  Pass the ActionId to be tracked on the mapView
     - Parameter completionHandler:  Pass instance of completion block as parameter
     */
    @objc public class func trackActionFor(actionId: String,
                                           completionHandler: ((_ action: HTAction?, _ error: HTError?) -> Void)? = nil) {
        HTActionService.sharedInstance.trackActionFor(actionId: actionId, completionHandler: completionHandler)
    }
    
    /**
     Call this method to track an Action on MapView embedded in your screen
     
     - Parameter shortCode: Pass the action short code to be tracked on the mapView
     - Parameter completionHandler: Pass instance of completion block as parameter
     */
    @objc public class func trackActionFor(shortCode: String,
                                           completionHandler: ((_ action: HTAction?, _ error: HTError?) -> Void)? = nil) {
        HTActionService.sharedInstance.trackActionFor(shortCode: shortCode, completionHandler: completionHandler)
    }
    
    /**
     Call this method to track an Action on MapView embedded in your screen
     
     - Parameter uniqueId: Pass the action uniqueId to be tracked on the mapView
     - Parameter completionHandler: Pass instance of completion block as parameter
     */
    @objc public class func trackActionFor(uniqueId: String,
                                           completionHandler: ((_ actions: [HTTrackAction]?, _ error: HTError?) -> Void)? = nil) {
        HTActionService.sharedInstance.trackActionFor(uniqueId: uniqueId, completionHandler: completionHandler)
    }
    
    /**
     Call this method to track an Action on MapView embedded in your screen
     
     - Parameter collectionId: Pass the collectionId to be tracked on the mapView
     - Parameter completionHandler: Pass instance of completion block as parameter
     */
    @objc public class func trackActionFor(collectionId: String,
                                           completionHandler: ((_ actions: [HTTrackAction]?, _ error: HTError?) -> Void)? = nil) {
        HTActionService.sharedInstance.trackActionFor(collectionId: collectionId, completionHandler: completionHandler)
    }
    
    /**
     Call this method to complete an action from the SDK with an actionId. Completes the provided actionId on HyperTrack.
     
     - Parameter actionId: The actionId to complete
     */
    @objc public class func completeAction(_ actionId: String) {
        HTActionService.sharedInstance.completeAction(actionId: actionId)
    }
    
    /**
     Call this method to complete an action from the SDK with an actionId. Completes the provided actionId on HyperTrack.
     
     - Parameter actionId: The actionId to complete
     */
    @objc public class func completeActionInSync(_ actionId: String, completionHandler : @escaping HTActionCompletionHandler) {
        HTActionService.sharedInstance.completeActionInSync(actionId: actionId, completionHandler: completionHandler)
    }
    
    /**
     Call this method to complete an action from the SDK with an uniqueId. Completes the provided uniqueId on HyperTrack.
     
     - Parameter actionId: The actionId to complete
     */
    @objc public class func completeActionWithUniqueIdInSync(_ uniqueId: String, completionHandler : @escaping HTActionCompletionHandler) {
        HTActionService.sharedInstance.completeActionWithUniqueIdInSync(uniqueId: uniqueId, completionHandler: completionHandler)
    }
    
    /**
     Call this method to stop tracking on the SDK and stop all running services.
     */
    @objc public class func pauseTracking() {
        HTUserService.sharedInstance.stopTracking(byUser: true)
    }
    
    
    @objc public class func createMockAction(_ origin: HTLocationCoordinate?, _ destination: HTLocationCoordinate?, _ params: HTActionParams, completionHandler: @escaping (_ action: HTAction?, _ error: HTError?) -> Void) {
        HypertrackService.sharedInstance.createMockAction(origin: origin, destination: destination, params: params, completionHandler: completionHandler)
    }
    
    /**
     Call this method to stop simulated tracking on the SDK and stop all mock services.
     */
    @objc public class func completeMockAction(actionId: String?, completionHandler: @escaping (_ action: HTAction?, _ error: HTError?) -> Void) {
        HypertrackService.sharedInstance.completeMockAction(actionId: actionId, completionHandler: completionHandler)
    }
//
//    /**
//     Returns an instance of the HyperTrack Map which can be used to track actions on.
//
//     - Returns: HyperTrack map object
//     */
//    @objc public class func map() -> HTMap {
//        return HTMap.sharedInstance
//    }
    
    /**
     Call this method to get Location Authorization status. This can be one of:
     
     - notDetermined 
     (User has not yet made a choice with regards to this application)
     
     - restricted
     (This application is not authorized to use location services.)
     
     - denied
     (User has explicitly denied authorization for this application, or
     location services are disabled in Settings.)
     
     - authorizedAlways
     (User has granted authorization to use their location at any time,
     including monitoring for regions, visits, or significant location changes.)
     
     - authorizedWhenInUse
     (User has granted authorization to use their location only when your app
     is visible to them.)
     */
    @objc public class func locationAuthorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    /**
     Call this method to request the location always permission.
     */
    @objc public class func requestAlwaysLocationAuthorization(completionHandler: @escaping (_ isAuthorized: Bool) -> Void) {
        HTSDKDataManager.sharedInstance.locationManager.requestAlwaysAuthorization(completionHandler: completionHandler)
    }
    
    /**
     Call this method to check Motion Activity Authorization status.
     
     - Parameter completionHandler: The completion handler which is called with a 
     Bool indicating whether motion activity is authorized or not.
     */
    @objc public class func motionAuthorizationStatus(completionHandler: @escaping (_ isAuthorized: Bool) -> Void) {
        HTSDKDataManager.sharedInstance.activityManager.motionAuthorizationStatus(completionHandler)
    }
    
    /**
     Call this method to check wether the device support activity estimation .
     
     Bool indicating whether motion activity is available or not.
     */
    
    @objc public class func isActivityAvailable() -> Bool {
        return CMMotionActivityManager.isActivityAvailable()
    }
    
    /**
     Call this method to request the motion permission.
     */
    @objc public class func requestMotionAuthorization() {
        HTSDKDataManager.sharedInstance.activityManager.requestMotionAuthorization()
    }
    
    /**
     Call this method to check if Location Services are enabled or not.
     */
    @objc public class func locationServicesEnabled() -> Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    /**
     Call this method to request the motion permission.
     */
    @objc public class func requestLocationServices() {
        guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (_) in
                    DDLogInfo("Location Services settings opened for user to enable it.")
                })
            } else {
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    // If general location settings are disabled then open general location settings
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    /**
     Call this method to register for remote (silent) notifications inside
     application(_:didFinishLaunchingWithOptions:launchOptions:)
     */
    @objc public class func registerForNotifications() {
         HypertrackService.sharedInstance.pushNotificationService.registerForNotifications()
    }
    
    /**
     Call this method to handle successful remote notification registration
     inside application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
     
     - Parameter deviceToken: The device token passed to the didRegisterForRemoteNotificationsWithDeviceToken application method
     */
    @objc public class func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) {
          HypertrackService.sharedInstance.pushNotificationService.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: deviceToken)
    }
    
    /**
     Call this method to handle unsuccessful remote notification registration
     inside application(_:didFailToRegisterForRemoteNotificationsWithError:)
     */
    @objc public class func didFailToRegisterForRemoteNotificationsWithError(error: Error) {
          HypertrackService.sharedInstance.pushNotificationService.didFailToRegisterForRemoteNotificationsWithError(error: error)
    }
    
    /**
     Call this method to handle receiving a silent (remote) notification
     inside application(_:didReceiveRemoteNotification:)
     */
    @objc public class func didReceiveRemoteNotification(userInfo: [AnyHashable: Any]) {
        // Read notification data
          HypertrackService.sharedInstance.pushNotificationService.didReceiveRemoteNotification(userInfo: userInfo)
    }
    
    /**
     Call this method to check if notification is a HyperTrack notification
     
     - Parameter userInfo: The user info of the received notification
     - Returns: Boolean denoting whether user info belongs to a HyperTrack notification
     */
    @objc public class func isHyperTrackNotification(userInfo: [AnyHashable: Any]) -> Bool {
        return   HypertrackService.sharedInstance.pushNotificationService.isHyperTrackNotification(userInfo: userInfo)
    }
    
    /**
     Call this method to get the current placeline activity of the user.
     */
    @objc public class func getPlaceline(date: Date? = nil, userId: String? = nil, completionHandler: @escaping (_ placeline: HTPlaceline?, _ error: HTError?) -> Void) {
        return HTUserService.sharedInstance.getPlacelineActivity(date: date, userID: userId, completionHandler: completionHandler)
    }
    
    /**
     Call this method to enable console logging
     */
    @objc public class func enableConsoleLogging() {
    }
    
    /**
     Call this method to get events around actions.
     */
    @objc public class func setEventsDelegate(eventDelegate: HTEventsDelegate) {
        HTSDKDataManager.sharedInstance.eventDelegate = eventDelegate
        HTSDKDataManager.sharedInstance.locationManager.eventDelegate = eventDelegate
    }

    /**
     Call this method to start monitoring for an entry in  place
     - Parameter place: HTPlace object
     identifier : unique identifier given to the place that needs to be monitored
     */
    @objc public class func setGeofenceAtPlace(place: HTPlace, radius: CLLocationDistance, identifier: String) {
        return HTSDKDataManager.sharedInstance.locationManager.startMonitoringForEntryAtPlace(place: place, radius: radius, identifier: identifier)
    }
    
    @objc public class func getCurrentLocation() -> CLLocation? {
        return HTSDKDataManager.sharedInstance.locationManager.getLastKnownLocation()
    }
    
    @objc public class func getCurrentActivity() -> HTActivity? {
      return HTSDKDataManager.sharedInstance.activityManager.getCurrentActivity()?.toHTActivity()
    }
    
    @objc public class func getPendingActions(completionHandler: @escaping (_ action: [HTAction]?, _ error: HTError?) -> Void) {
        HTUserService.sharedInstance.getPendingActions(completionHandler: completionHandler)
    }
    
    @objc public class func setLocationUpdatesDelegate(_ delegate: HTLocationUpdatesDelegate?) {
        HTSDKDataManager.sharedInstance.locationUpdatesDelegate = delegate
    }
}
