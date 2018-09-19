//
//  HTActivityManager.swift
//  Pods
//
//  Created by Ravi Jain on 8/4/17.
//
//

import UIKit
import CoreMotion
import MapKit
import CocoaLumberjack

protocol HTActivityEventsDelegate: class {
    func didChangeActivityTo(activity: HTSDKActivity, fromActivity: HTSDKActivity?)
    func didUpdateActivity(activity: HTSDKActivity)
    func didStopTracking(activity: HTSDKActivity)
}

class HTActivityManager: NSObject {
    
    let activityQueueName = "HTActivityQueue"
    let driveSpeedThreshold = 6.0
    let driveAvSpeed = 4.0
    let sdkActiveCheckDuration = 300
    
    let motionManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    let activityAnalyzer = HTActivityAnalyzer()
    let sensorHelper = HTActivitySensorHelper()
    
    var currentActivity: HTSDKActivity?
    var recordedOSActivities = [HTSDKActivity]()
    var previousActivities = [HTSDKActivity]()
    
    var isTracking = false
    
    weak var activityEventDelegate: HTActivityEventsDelegate?
    
    override init() {
        super.init()
        self.initializeDB()
    }
    
    private func restartMotionUpdates() {
        if isTracking {
            self.stopMotionManager()
            self.startMotionManager()
        }
    }
    
    func initializeDB(){
        do {
            DDLogInfo("creating activities table")
            try HTDatabaseService.sharedInstance.activityDBHelper?.createTable()
        } catch  {
            DDLogError("not able to create table for activities")
        }
    }
    
    func startTracking(){
        isTracking = true
        if let previousActivities = self.getActivitiesFromDB(count: 50){
            self.previousActivities = previousActivities.reversed()
            if  self.previousActivities.count > 0 {
                currentActivity =  self.previousActivities.last
            }else{
                let sdkActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.stop, startTime: Date())
                onActivityConfirmation(newActivity: sdkActivity)
            }
        }
        
        self.onAppStarted()
        checkIfSDKIsActive()
        self.startMotionManager()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onAppForeground(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    func startMotionManager(){
        
        self.motionManager.startActivityUpdates(to: self.activityQueue) { activity in
            guard let cmActivity = activity else { return }
            self.onOSActivityUpdate(activity: cmActivity)
        }
    }
    
    func stopMotionManager(){
        self.motionManager.stopActivityUpdates()
    }
    
    func onAppForeground(_ notification: Notification) {
        self.checkForUnknownActivity()
        restartMotionUpdates()
    }
    
    func onAppBackground(_ notification: Notification) {
        self.checkIfSDKIsActive()
        restartMotionUpdates()
    }
    
    func stopTracking() {
        isTracking = false
        NotificationCenter.default.removeObserver(self)
        self.stopMotionManager()
        self.endCurrentActivity()
    }
    
    
    func checkIfSDKIsActive(){
        if let lastActiveTimeOfSDK = Settings.lastActiveTimeOfSDK {
            if  Date().timeIntervalSince1970 - lastActiveTimeOfSDK.timeIntervalSince1970  > Double((2 * sdkActiveCheckDuration)) {
                DDLogInfo("creating sdk inactive segment as sdk was inactive for more than 10 mins")
                let sdkInactiveActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.unknown, startTime: lastActiveTimeOfSDK.addingTimeInterval(TimeInterval(sdkActiveCheckDuration)))
                sdkInactiveActivity.unknownReason = HTUnknownActivityType.sdkInactive
                self.onActivityConfirmation(newActivity: sdkInactiveActivity)
            }
        }
        
        self.checkForUnknownActivity()
        Settings.lastActiveTimeOfSDK = Date()
        DispatchQueue.global(qos: .background).asyncAfter(deadline:.now() + .seconds(sdkActiveCheckDuration)) {
            Settings.lastActiveTimeOfSDK = Date()
            self.checkIfSDKIsActive()
        }
    }
    
    func motionAuthorizationStatus(_ completionHandler: @escaping (_ isAuthorized: Bool) -> Void) {
        let today: Date = Date()
        motionManager.queryActivityStarting(
        from: today, to: today, to: OperationQueue.main) { (_, error) in
            if (error != nil) {
                completionHandler(false)
            } else {
                completionHandler(true)
            }
        }
    }
    
    func checkForUnknownActivity(){
        if !CLLocationManager.locationServicesEnabled() {
            let locationDisabledActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.unknown, startTime: Date())
            locationDisabledActivity.unknownReason = HTUnknownActivityType.locationDisabled
            self.onActivityConfirmation(newActivity: locationDisabledActivity)
        }
        else if (CLLocationManager.authorizationStatus()  == .denied) || (CLLocationManager.authorizationStatus() == .notDetermined) {
            let locationDeniedActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.unknown, startTime: Date())
            locationDeniedActivity.unknownReason = HTUnknownActivityType.locationPermissionDenied
            self.onActivityConfirmation(newActivity: locationDeniedActivity)
        }
        else {
            self.motionAuthorizationStatus({ (hasPermissions) in
                if !hasPermissions {
                    let motionDisabledActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.unknown, startTime: Date())
                    motionDisabledActivity.unknownReason = HTUnknownActivityType.activityPermissionDenied
                    self.onActivityConfirmation(newActivity: motionDisabledActivity)
                }
            })
        }
    }
    
    
    func getCurrentActivity() -> HTSDKActivity? {
        return currentActivity
    }
    
    func getActivitiesFromDB(count: Int) -> [HTSDKActivity]?{
        return (HTDatabaseService.sharedInstance.activityDBHelper?.getPreviousActivities(count))
    }
    
    func requestMotionAuthorization() {
        self.motionManager.startActivityUpdates(to: OperationQueue(), withHandler: { (_) in
        })
        self.motionManager.stopActivityUpdates()
    }
    
    lazy var activityQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = self.activityQueueName
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    func onOSActivityUpdate(activity: CMMotionActivity){
        let sdkActivity = HTSDKActivity.getSDKActivityFromOSActivity(osActivity: activity)
        
        if sdkActivity.type == HTActivityType.unknown{
            return
        }
        
        // special handling of moving activity when old activity is walk ,run ,drive
        if let currentActivity = self.currentActivity {
            if sdkActivity.type == HTActivityType.moving && currentActivity.isMovingActivity()  {
                DDLogInfo("changing moving activity to \(currentActivity.type.rawValue)")
                sdkActivity.type = currentActivity.type
            }
        }
        
        if sdkActivity.type == HTActivityType.moving{
            // do not process moving activity
            return
        }
        
        recordedOSActivities.append(sdkActivity)
        
        if sdkActivity.type != currentActivity?.type{
            DispatchQueue.main.async {
                self.confirmIfActivityChanged(sdkActivity: sdkActivity)
            }
        }
    }
    
    
    
    func confirmIfActivityChanged(sdkActivity: HTSDKActivity){
        
        if let activity = activityAnalyzer.confirmFromContinousSegments(recordedActivities: self.recordedOSActivities, activityType: sdkActivity.type){
            DDLogInfo("confirmFromContinousSegments \(activity.type.rawValue) to \(activity.type.rawValue) having lookupid = \(activity.lookupId) description = \(activity.toDict().description)" )
            self.onActivityConfirmation(newActivity: activity)
        }
        else if let activity = activityAnalyzer.checkForMaxWeightActivity(activity: sdkActivity, recordedActivities: self.recordedOSActivities) {
            DDLogInfo("getMaxWeightActivity \(activity.type.rawValue) to \(activity.type.rawValue) having lookupid = \(sdkActivity.lookupId) description = \(activity.toDict().description)" )
            if sdkActivity.type == activity.type{
                self.onActivityConfirmation(newActivity: activity)
            }
        }
        else if sdkActivity.type == HTActivityType.drive {
            sensorHelper.confirmDriveUsingSensors(resultHandler: { (newActivity) in
                if let activity = newActivity{
                    DDLogInfo("confirmFromSensors: DRIVE \(activity.type.rawValue) to \(activity.type.rawValue) having lookupid = \(activity.lookupId) description = \(activity.toDict().description)" )
                    self.onActivityConfirmation(newActivity: activity)
                }
            })
        }
        else if sdkActivity.type == HTActivityType.walk || sdkActivity.type == HTActivityType.stop {
            if  currentActivity != nil && currentActivity?.type == HTActivityType.drive{
                
            }
            else{
                sensorHelper.confirmWalkOrStopUsingSensors(resultHandler: { (newActivity) in
                    if let activity = newActivity{
                            if activity.type != HTActivityType.unknown{
                                if let currentActivity = self.currentActivity {
                                    if currentActivity.type == HTActivityType.drive{
                                        
                                    }else{
                                        DDLogInfo("confirmFromSensors: walk \(activity.type.rawValue) to \(activity.type.rawValue) having lookupid = \(activity.lookupId) description = \(activity.toDict().description)" )
                                        self.onActivityConfirmation(newActivity: activity)
                                    }
                                }else{
                                    DDLogInfo("confirmFromSensors: stop/walk \(activity.type.rawValue) to \(activity.type.rawValue) having lookupid = \(activity.lookupId) description = \(activity.toDict().description)" )
                                    self.onActivityConfirmation(newActivity: activity)
                                }
                            }
                    }
                })
            }
            
        }
    }
    
    
    /*
     current -> normal  new -> unknown
     activity should change to unknown
     should change it directly
     
     current -> unknown  new -> normal
     first check wether unknown activity is still present
     if yes then let it continue
     if no then change the activity
     
     current -> normal  new -> normal
     directly change to new
     
     current -> unknown new -> unknown
     check the priority and then change it to unknown if the new unknown has higher priority
     */
    func onActivityConfirmation(newActivity: HTSDKActivity){
        DDLogInfo("changing activity from \(newActivity.type.rawValue) to \(newActivity.type.rawValue) having lookupid = \(newActivity.lookupId) description = \(newActivity.toDict().description)" )
        
        if let currentActivity = self.currentActivity{
            
            if currentActivity.sessionId != newActivity.sessionId {
                self.changeActivityTo(sdkActivity: newActivity)
            }
            
            if currentActivity.type != HTActivityType.unknown &&  newActivity.type == HTActivityType.unknown{
                self.changeActivityTo(sdkActivity: newActivity)
            }
            else if currentActivity.type == HTActivityType.unknown && newActivity.type != HTActivityType.unknown{
                self.isUnknownActivityStillRunning(activity: currentActivity, { (isRunning) in
                    if !isRunning {
                        self.changeActivityTo(sdkActivity: newActivity)
                    }
                })
            }
            else if currentActivity.type == HTActivityType.unknown && newActivity.type == HTActivityType.unknown{
                if currentActivity.unknownReason != newActivity.unknownReason {
                    if newActivity.isHigherPriorityUknknownActivityFrom(sdkActivity: currentActivity){
                        self.changeActivityTo(sdkActivity: newActivity)
                    }
                }
            }
            else if currentActivity.type != HTActivityType.unknown && newActivity.type != HTActivityType.unknown{
                if newActivity.type != currentActivity.type{
                    self.changeActivityTo(sdkActivity: newActivity)
                }
            }
        }else{
            self.changeActivityTo(sdkActivity: newActivity)
        }
    }
    
    func isUnknownActivityStillRunning(activity: HTSDKActivity,_ completionHandler: @escaping (_ isRunning: Bool) -> Void) {
        if activity.unknownReason == HTUnknownActivityType.locationDisabled{
            if !CLLocationManager.locationServicesEnabled() {
                completionHandler(true)
                return
            }
        }
        else if activity.unknownReason == HTUnknownActivityType.locationPermissionDenied{
            if (CLLocationManager.authorizationStatus()  == .denied) || (CLLocationManager.authorizationStatus() == .notDetermined) {
                completionHandler(true)
                return
            }
        }
        else if activity.unknownReason == HTUnknownActivityType.activityPermissionDenied{
            self.motionAuthorizationStatus({ (hasPermission) in
                completionHandler(!hasPermission)
                return
            })
        }
        else if activity.unknownReason == HTUnknownActivityType.deviceOff {
            completionHandler(false)
            return
        }
        else if activity.unknownReason == HTUnknownActivityType.sdkInactive {
            completionHandler(false)
            return
        }
        
        completionHandler(false)
        return
    }
    
    func changeActivityTo(sdkActivity: HTSDKActivity){
        let serialQueue = DispatchQueue(label: "queuename")
        serialQueue.sync {
            DDLogInfo("changing activity from \(currentActivity?.type.rawValue ?? "") to \(sdkActivity.type.rawValue) having lookupid = \(sdkActivity.lookupId) description = \(sdkActivity.toDict().description)" )
            if let activity = currentActivity {
                if activity.isTypeSame(activity: sdkActivity){
                    DDLogInfo("new activity same as old, so not changing the activity")
                    return
                }
                
                activity.endTime = Date()
                activity.recordedAt = activity.endTime!
                
                HTDatabaseService.sharedInstance.activityDBHelper?.update(activity: activity)
                if activity.type == HTActivityType.stop || activity.type == HTActivityType.walk{
                    addStepsData(activity: activity)
                }
            }
            
            sdkActivity.startTime = Date()
            sdkActivity.recordedAt = sdkActivity.startTime
            HTDatabaseService.sharedInstance.activityDBHelper?.insert(activity: sdkActivity)
            if let activityEventDelegate = self.activityEventDelegate {
                activityEventDelegate.didChangeActivityTo(activity: sdkActivity, fromActivity: currentActivity)
            }
            currentActivity = sdkActivity
        }
    }
    
    
    func addStepsData(activity: HTSDKActivity){
        self.pedometer.queryPedometerData(from: activity.startTime, to: activity.endTime!, withHandler: { (pedometerData, error) in
            if let error = error{
                DDLogError("unable to fetch steps data \(error.localizedDescription)")
                return
            }else if let pedometerData = pedometerData{
                activity.stepCount  = pedometerData.numberOfSteps.intValue
                activity.stepDistance = (pedometerData.distance?.intValue) ?? 0
                activity.recordedAt = Date()
                HTDatabaseService.sharedInstance.activityDBHelper?.updateSteps(activity: activity)
                
                if let activityEventDelegate = self.activityEventDelegate {
                    activityEventDelegate.didUpdateActivity(activity: activity)
                }
            }
        })

    }
    
    func endCurrentActivity(){
        DDLogInfo("ending current activity  \(currentActivity?.type.rawValue ?? "") having lookupid = \(currentActivity?.lookupId ?? "")")
        if let activity = currentActivity {
            activity.endTime = Date()
            activity.recordedAt = Date()
            HTDatabaseService.sharedInstance.activityDBHelper?.update(activity: activity)
            if let activityEventDelegate = self.activityEventDelegate {
                activityEventDelegate.didStopTracking(activity: activity)
            }
        }
    }
    
    func onAppStarted(){
        
        
    }
    
    func onAppTerminated(){
        let sdkActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.unknown, startTime: Date())
        sdkActivity.unknownReason = HTUnknownActivityType.sdkInactive
        onActivityConfirmation(newActivity: sdkActivity)
    }
    
    func deviceDidSwitchOff(startTime: Date, endTime: Date) {
        
    }
    
    func locationManager(_ manager: LocationManagerProtocol, didUpdateLocations locations: [HTLocation]) {
        
        analyzeLocations(locations: locations)
    }
    
    func canRecordOSActivities(){
        
    }
    
    func locationManager(_ manager: LocationManagerProtocol,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        
        if !CLLocationManager.locationServicesEnabled() {
            let locationDisabledActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.unknown, startTime: Date())
            locationDisabledActivity.unknownReason = HTUnknownActivityType.locationDisabled
            self.onActivityConfirmation(newActivity: locationDisabledActivity)
        }else if (CLLocationManager.authorizationStatus() == .denied) || (CLLocationManager.authorizationStatus() == .notDetermined) {
            let locationDisabledActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.unknown, startTime: Date())
            locationDisabledActivity.unknownReason = HTUnknownActivityType.locationPermissionDenied
            self.onActivityConfirmation(newActivity: locationDisabledActivity)
        }else if (CLLocationManager.authorizationStatus() == .authorizedAlways){
            
        }
    }
    
    func analyzeLocations(locations: [HTLocation]) {
        if let location = locations.last?.clLocation {
            if location.timestamp.timeIntervalSince1970 > (Date().timeIntervalSince1970 - 120) {
                if location.speed > driveSpeedThreshold {
                    if HTActivityType.drive != currentActivity?.type {
                        let htSDKActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.drive, startTime: location.timestamp)
                        DDLogInfo("activity won by speed from location, activity : \(htSDKActivity.type)")
                        self.onActivityConfirmation(newActivity: htSDKActivity)
                    }
                }
            }
        }
    }
    
    func getActivitiesSince(lastRecordedDate: Date) -> [HTSDKActivity]{
        return [HTSDKActivity]()
    }
    
    func getActivityAt(recordedAt: Date) -> HTSDKActivity?{
        return HTDatabaseService.sharedInstance.activityDBHelper?.getActivityAtDate(date:recordedAt)
    }
    
    func getActivityFromLookUpId(lookUpId: String) -> HTSDKActivity?{
        return HTDatabaseService.sharedInstance.activityDBHelper?.getActivityFromLookUpId(lookUpId: lookUpId)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidEnterBackground,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: .UIApplicationDidBecomeActive,
                                                  object: nil)
    }
}
