//
//  HTSDKControlsService.swift
//  HyperTrack
//
//  Created by ravi on 12/12/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

class HTSDKControlsService: NSObject {
    
    static let sharedInstance = HTSDKControlsService()
    
    let currentControlKey = "currentControlKey"
    let maxTTL = 24.0 * 60.0 * 60.0
    
    let requestManager: RequestManager
    var currentSDKControls: HTSDKControls? = nil
    var currentServerSDKControls: HTSDKControls? = nil

    var ttlTimer: Timer
    
    override init() {
        self.requestManager = RequestManager()
        self.ttlTimer = Timer()
        super.init()
    }
    
    func setUpControls(){
        if let currentControls = self.getCurrentSavedSDKControls() {
            currentSDKControls = currentControls
        }
        else {
            currentSDKControls = HTSDKControls.getDefaultControls()
        }
        self.registerForNotifications()
        self.refreshTTLTimerOfSDKControls(controls: currentSDKControls!)
        let controls = getAggressiveSDKControls()
        controls.isForced = true
        controls.ttl = 1 * 60
        onNewSDKControls(newControls: controls)
        self.reEvaluateSDKControls()
    }
    
    func registerForNotifications(){
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reEvaluateSDKControls),
                                               name: NSNotification.Name(rawValue: HTConstants.HTPowerStateChangedNotification), object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reEvaluateSDKControls),
                                               name: NSNotification.Name(rawValue: HTConstants.HTNetworkStateChangedNotification), object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reEvaluateSDKControls),
                                               name: NSNotification.Name(rawValue: HTConstants.HTNetworkStateChangedNotification), object: nil)
        
    }
    

    func getCurrentSavedSDKControls() -> HTSDKControls?{
        if let data  = HTUserDefaults.standard.data(forKey: currentControlKey){
            if let sdkControls = HTSDKControls.fromJson(data: data){
                return sdkControls
            }
        }
        return nil
    }
    
    func getTransmissionControls() -> HTTransmissionControls? {
        return currentSDKControls?.getTransmissionControls()
    }
    
    func getSDKControlsFromServer() {
        guard let userId = HTUserService.sharedInstance.userId else { return }
        
        self.requestManager.getSDKControls(userId: userId) { (controls, error) in
            if error == nil {
                if let controls = controls {
                    DDLogInfo("SDKControls from server for user: \(userId ) updated to batch_duration: \(controls.toDict().description)")
                    controls.isFromServer = true
                    self.currentServerSDKControls = controls
                    self.processSDKControls(controls: controls)
                }
            }
        }
    }
    
    func processSDKControls(controls: HTSDKControls) {
        // Process controls
        if let runCommand = controls.runCommand {
            
            if runCommand == .goOffline {
                // Stop tracking from the backend
                if HypertrackService.sharedInstance.isTracking {
                    HyperTrack.pauseTracking()
                }
                return
            } else if runCommand == .goActive {
                // check if actions are present
                HTUserService.sharedInstance.startCheckingForPendingActions()
            } else if runCommand == .goOnline {
                // nothing to do as controls will handle
            }
        }
        
        onNewSDKControls(newControls: controls)
    }
    
    func onSDKControlsChange(newSDKControls: HTSDKControls){
        DDLogInfo("onSDKControlsChange : \(newSDKControls.toDict().description) ")
        self.resetSDKControls()
        self.saveControls(controls: newSDKControls)
        self.notifySDKControlsConsumers()
        HTSDKDataManager.sharedInstance.locationManager.updateLocationManager(filterDistance: Double(newSDKControls.minimumDisplacement!), pausesLocationUpdatesAutomatically: false)
    }
    
    func onNewSDKControls(newControls: HTSDKControls, force: Bool = false){
        
        if force == true{
            if let serverControls = self.currentServerSDKControls {
                if serverControls.recordedAt.timeIntervalSince1970 + (serverControls.ttl ?? HTSDKControls.minimumTTL) > Date().timeIntervalSince1970 {
                    DDLogInfo("using server controls as it's ttl is not yet expired")
                    onSDKControlsChange(newSDKControls: serverControls)
                    return
                }
            }
            else{
                if let currentSDKControls = self.currentSDKControls {
                    if currentSDKControls.isForced == true {
                        DDLogInfo("using current sdk controls as it is forced")
                        return
                    }
                }
                
                onSDKControlsChange(newSDKControls: newControls)
            }
            return
        }
        
        if let currentSDKControls = self.currentSDKControls {
            if currentSDKControls.getTransmissionControls().batchDuration > newControls.getTransmissionControls().batchDuration{
                onSDKControlsChange(newSDKControls: newControls)
            }
        }else{
            onSDKControlsChange(newSDKControls: newControls)
        }
    }
    
    
    func saveControls(controls: HTSDKControls) {
        let dict = controls.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            HTUserDefaults.standard.set(jsonData, forKey: currentControlKey)
            HTUserDefaults.standard.synchronize()
            self.currentSDKControls = controls
        }
        catch{
            DDLogError("error while saving sdk controls \(controls.toDict().description)")
        }
    }
   
    func refreshTTLTimerOfSDKControls(controls: HTSDKControls) {
        if let ttl = controls.ttl {
            if ttl > 0 {
                //Handle ttl and set a timer that will
                // reset to defaults
                self.ttlTimer.invalidate()
                self.ttlTimer = Timer.scheduledTimer(timeInterval: Double(ttl),
                                                  target: self,
                                                  selector: #selector(self.onTTLExpiry),
                                                  userInfo: nil,
                                                  repeats: false)
            }
        }
    }
    
    func notifySDKControlsConsumers() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: HTConstants.HTSDKControlsRefreshedNotification),
                object: nil,
                userInfo: nil)
    }
    
    func onServerNotification(){
        self.getSDKControlsFromServer()
        self.flushCachedData()
    }
    
    func onTTLExpiry(){
        self.reEvaluateSDKControls()
    }
    
    func reEvaluateSDKControls(){
       
        var canGoAggressive = false
        if let currentPowerState = HTSDKDataManager.sharedInstance.getCurrentPowerState(){
            // charging
            if currentPowerState.chargingState == HTBatteryState.charging.rawValue {
                // battery % > 30
                if currentPowerState.batteryPercentage > 30.0 {
                    canGoAggressive = true
                }
            }else if currentPowerState.chargingState == HTBatteryState.full.rawValue {
                // full
                canGoAggressive = true
            }else {
                
                if let currentNetworkState = HTSDKDataManager.sharedInstance.getCurrentNetworkInfo(){
                    if currentNetworkState.networkState == HTNetworkState.connected {
                        if currentNetworkState.networkType == HTNetworkConnectionType.wifi.rawValue {
                            if currentPowerState.batteryPercentage > 60.0{
                                canGoAggressive = true
                            }
                        }else if currentPowerState.batteryPercentage  > 80.0 {
                            canGoAggressive = true
                        }
                    }
                }
            }
        }
        
        if canGoAggressive{
            let controls = getAggressiveSDKControls()
            onNewSDKControls(newControls: controls)
        }else{
            //switch to passive mode
            onNewSDKControls(newControls: HTSDKControls.getDefaultControls(), force: true)
        }
    }
    
    @objc func resetSDKControls() {
        DDLogInfo("Resetting sdk controls")
        HTUserDefaults.standard.removeObject(forKey: currentControlKey)
        HTUserDefaults.standard.synchronize()
    }
    
    func flushCachedData() {
        HTTransmissionService.sharedInstance.postEvents()
    }
    
    func onTimer(){
        HTTransmissionService.sharedInstance.postEvents()
    }
    
    func getAggressiveSDKControls() -> HTSDKControls{
        let controls =  HTSDKControls.init(userId: HTUserService.sharedInstance.userId, runCommand: HTSDKControlsRunCommand.goActive.rawValue , ttl: maxTTL, minimumDuration: 5.0, minimumDisplacement: 5.0, batchDuration: 5.0)
        return controls
    }
}
