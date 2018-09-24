//
//  HTSDKDataManager
//  HyperTrack
//
//  Created by Ravi Jain on 11/11/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation
import CocoaLumberjack

class HTSDKDataManager: NSObject, HTActivityEventsDelegate, HTHealthEventsDelegate, LocationEventsDelegate {
    
    static let sharedInstance = HTSDKDataManager()
    var activityManager:  HTActivityManager
    var healthManager: HTHealthManager
    var locationManager: LocationManagerProtocol
    var haveStartedTracking = false
    
    weak var eventDelegate: HTEventsDelegate?
    
    override init() {
        self.activityManager = HTActivityManager()
        self.healthManager = HTHealthManager()
        self.locationManager = LocationManager()
        super.init()
        initializeDB()
    }
    
    //To be used from the host app
    weak var locationUpdatesDelegate: HTLocationUpdatesDelegate? = nil {
        didSet {
            locationManager.locationUpdatesDelegate = locationUpdatesDelegate
        }
    }
    
    private func initializeDB(){
        do {
            DDLogInfo("creating events table")
            try  HTDatabaseService.sharedInstance.eventsDBHelper?.createTable()
        } catch  {
            DDLogError("not able to create table for health data")
        }
    }
  
    func startTracking(byUser: Bool, completionHandler: ((_ error: HTError?) -> Void)?) {
        if (!haveStartedTracking){
            if !Settings.getTracking() {
                self.saveTrackingStarted(byUser: byUser)
                NotificationCenter.default.post(name: Notification.Name(rawValue: HTConstants.HTTrackingStartedNotification),
                                                object: nil,
                                                userInfo: nil)
            }
            
            self.activityManager.activityEventDelegate = self
            self.healthManager.healthEventDelegate = self
            self.locationManager.locationEventsDelegate = self
            
            self.activityManager.startTracking()
            self.healthManager.startTracking()
            self.locationManager.startTracking(completionHandler: completionHandler)
            
            self.haveStartedTracking = true
        }
      }
    
    func startMockTracking(origin: CLLocationCoordinate2D?, destination: CLLocationCoordinate2D?, completionHandler: ((_ error: HTError?) -> Void)?) {
        
        if !Settings.getMockTracking(){
            self.saveMockTrackingStarted()
        }
        
        self.locationManager =  MockLocationManager.init(origin: origin, destination: destination)
        
        self.activityManager.activityEventDelegate = self
        self.healthManager.healthEventDelegate = self
        self.locationManager.locationEventsDelegate = self
        
        self.activityManager.startTracking()
        self.healthManager.startTracking()
        self.locationManager.startTracking(completionHandler: completionHandler)
    }
    
    func stopTracking(byUser: Bool) {
        if Settings.getTracking() {
            self.activityManager.stopTracking()
            self.locationManager.stopTracking()
            self.healthManager.stopTracking()
            self.saveTrackingEnded(byUser: byUser)

        }
    }
    
    func stopMockTracking(){
        self.locationManager.stopTracking()
    }
    
    func getCurrentLocation(completionHandler: @escaping (_ currentLocation: CLLocation?,
        _ error: HTError?) -> Void) {
        self.locationManager.getCurrentLocation(completionHandler: completionHandler)
    }
    
    func getCurrentPowerState() -> HTPowerState? {
       return self.healthManager.currentPowerHealth
    }
    
    func getCurrentNetworkInfo() -> HTRadioState? {
        return self.healthManager.currentRadioHealth
    }
    
    func appDidStart(atTime: Date) {
    
    }
    
    func appDidTerminate(atTime: Date) {
        self.activityManager.onAppTerminated()
    }
    
    func deviceDidSwitchOff(startTime: Date, endTime: Date) {
        self.activityManager.deviceDidSwitchOff(startTime: startTime, endTime: endTime)
    }
    
    func onNetworkEnabled(connectionType: HTNetworkConnectionType) {
        
    }
    
    func onNetworkDisabled() {
        
    }
    
    func deviceInfoChanged(sdkHealth: HTSDKHealth) {
        addHealthEvent(sdkHealth: sdkHealth)
    }
    
    func devicePowerChanged(sdkHealth: HTSDKHealth) {
        addHealthEvent(sdkHealth: sdkHealth)
        NotificationCenter.default.post(name: Notification.Name(rawValue: HTConstants.HTPowerStateChangedNotification),
                                        object: nil,
                                        userInfo: nil)
    }
    
    func locationConfigChanged(sdkHealth: HTSDKHealth) {
        addHealthEvent(sdkHealth: sdkHealth)
    }
    
    func networkConfigChanged(sdkHealth: HTSDKHealth) {
        addHealthEvent(sdkHealth: sdkHealth)
        NotificationCenter.default.post(name: Notification.Name(rawValue: HTConstants.HTNetworkStateChangedNotification),
                                        object: nil,
                                        userInfo: nil)
    }
    
    func addHealthEvent(sdkHealth: HTSDKHealth){
        if let activity = self.activityManager.getActivityAt(recordedAt: sdkHealth.recordedAt){
            let event = HTEventUtils.getSDKEventFrom(health: sdkHealth, activityLookUpId: activity.lookupId)
          
            HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
            if let eventDelegate = self.eventDelegate {
                eventDelegate.didReceiveEvent(event)
            }
        }else{
            let event = HTEventUtils.getSDKEventFrom(health: sdkHealth, activityLookUpId: "")
            HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
            if let eventDelegate = self.eventDelegate {
                eventDelegate.didReceiveEvent(event)
            }
            DDLogError("no activity at recorded at \(sdkHealth.recordedAt.iso8601)")
        }
    }
    
    func locationManager(_ manager: LocationManagerProtocol, didEnterRegion region: CLRegion) {
    }
    
    func locationManager(_ manager: LocationManagerProtocol, didExitRegion region: CLRegion) {

    }
    
    func locationManager(_ manager: LocationManagerProtocol, didUpdateLocations locations: [HTLocation]) {
        for location in locations {
            if let activity = self.activityManager.getActivityAt(recordedAt: location.recordedAt){
                let event = HTEventUtils.getSDKEventFrom(location: location, activityLookUpId: activity.lookupId)
                HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
                if let eventDelegate = self.eventDelegate {
                    eventDelegate.didReceiveEvent(event)
                }
            }
        }
        
        if locations.count > 0 {
            Settings.setLastKnownLocation(location: locations.last!)
        }

        self.activityManager.locationManager(manager, didUpdateLocations: locations)
    }
    
    
    
    func locationManager(_ manager: LocationManagerProtocol,
                         didVisit visit: CLVisit) {
        
    }
    
    func locationManager(_ manager: LocationManagerProtocol,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        self.activityManager.locationManager(manager, didChangeAuthorization: status)
        self.healthManager.locationManager(manager, didChangeAuthorization: status)
    }
    
    func didChangeActivityTo(activity: HTSDKActivity, fromActivity: HTSDKActivity?) {

        if let oldActivity = fromActivity {
            let event = HTEventUtils.getSDKEventFrom(activity: oldActivity, type: .activityEnded)
            HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
            if let eventDelegate = self.eventDelegate {
                eventDelegate.didReceiveEvent(event)
            }
        }

        let event = HTEventUtils.getSDKEventFrom(activity: activity, type: .activityStarted)
        if let htLocation = self.locationManager.getLastKnownHTLocation(){
            if htLocation.clLocation.timestamp.timeIntervalSince1970 > (Date().timeIntervalSince1970 - 300) {
                event.locationLookUpId = htLocation.lookUpId ?? ""
            }
        }
        
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
        
        self.locationManager.didChangeActivityTo(activity: activity, fromActivity: fromActivity)
    }
    
    func didUpdateActivity(activity: HTSDKActivity){
        let event = HTEventUtils.getSDKEventFrom(activity: activity, type: .activityUpdated)
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
    }
    
    func didStopTracking(activity: HTSDKActivity){
        let event = HTEventUtils.getSDKEventFrom(activity: activity, type: .activityEnded)
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
    }
    
    func getActivitiesToUpload() -> [HTSDKActivity]{
        return self.activityManager.getActivitiesSince(lastRecordedDate: Date())
    }
    
    func saveActionCompletedEvent(actionId: String){
        guard let userId = HTUserService.sharedInstance.userId else { return }
        
        let event = HyperTrackEvent.init(userId: userId, sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: Date(), eventType: HyperTrackEventType.actionCompleted, activityLookUpId: "", locationLookUpId: "", healthLookUpId: "", data: ["action_id": actionId])
        
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
    }
    
    func saveActionCompletedEvent(uniqueId: String){
        guard let userId = HTUserService.sharedInstance.userId else { return }
        
        let event = HyperTrackEvent.init(userId: userId, sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: Date(), eventType: HyperTrackEventType.actionCompleted, activityLookUpId: "", locationLookUpId: "", healthLookUpId: "", data: ["unique_id": uniqueId])
        
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
    }

    func saveTrackingStarted(byUser: Bool) {
        guard let userId = HTUserService.sharedInstance.userId else { return }
        Settings.lastSessionId = Settings.sessionId
        Settings.sessionId = UUID().uuidString
        Settings.setTracking(isTracking: true)
        Settings.trackingStartedAt = Date()
        let device = UIDevice.current
        let deviceId = device.identifierForVendor?.uuidString
        Settings.deviceId = deviceId ?? ""
        
        let event = HyperTrackEvent.init(userId: userId, sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: Date(), eventType: HyperTrackEventType.trackingStarted , activityLookUpId: "", locationLookUpId: "", healthLookUpId: "", data: ["auto": !byUser, "last_session_id": Settings.lastSessionId])
        
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
    }
    
    func saveMockTrackingStarted(){
        guard let userId = HTUserService.sharedInstance.userId else { return }
        Settings.lastSessionId = Settings.sessionId
        Settings.sessionId = UUID().uuidString
        Settings.setMockTracking(isTracking: true)
        Settings.trackingStartedAt = Date()
        let device = UIDevice.current
        let deviceId = device.identifierForVendor?.uuidString
        Settings.deviceId = deviceId ?? ""
        
        let event = HyperTrackEvent.init(userId: userId, sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: Date(), eventType: HyperTrackEventType.trackingStarted , activityLookUpId: "", locationLookUpId: "", healthLookUpId: "", data: ["is_mock":true, "last_session_id": Settings.lastSessionId])
        
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
    }
    
    
    func saveMockTrackingEnded(){
        guard let userId = HTUserService.sharedInstance.userId else { return }
        
        let event = HyperTrackEvent.init(userId: userId, sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: Date(), eventType: HyperTrackEventType.trackingEnded , activityLookUpId: "", locationLookUpId: "", healthLookUpId: "", data: ["is_mock":true])
        
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
       
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
        
        Settings.sessionId = ""
        Settings.setMockTracking(isTracking: false)
        Settings.trackingStartedAt = nil
    }
    
    func saveTrackingEnded(byUser: Bool) {
        guard let userId = HTUserService.sharedInstance.userId else { return }

        let event = HyperTrackEvent.init(userId: userId, sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: Date(), eventType: HyperTrackEventType.trackingEnded , activityLookUpId: "", locationLookUpId: "", healthLookUpId: "", data: ["auto": !byUser, "last_session_id": Settings.lastSessionId])
        
        HTDatabaseService.sharedInstance.eventsDBHelper?.insert(event: event)
        
        if let eventDelegate = self.eventDelegate {
            eventDelegate.didReceiveEvent(event)
        }
        
        Settings.sessionId = ""
        Settings.setTracking(isTracking: false)
        Settings.trackingStartedAt = nil
    }
    
    func getEvents() -> [HyperTrackEvent]?{
        return (HTDatabaseService.sharedInstance.eventsDBHelper?.getEvents())
    }
}
