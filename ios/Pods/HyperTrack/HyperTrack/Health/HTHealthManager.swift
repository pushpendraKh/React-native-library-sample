//
//  HTHealthManager.swift
//  HyperTrack
//
//  Created by ravi on 10/26/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack
import CoreLocation
import Alamofire
import CoreTelephony

protocol HTHealthEventsDelegate: class {
    func appDidStart(atTime: Date)
    func appDidTerminate(atTime: Date)
    func deviceDidSwitchOff(startTime: Date, endTime:Date)
    func onNetworkEnabled(connectionType: HTNetworkConnectionType)
    func onNetworkDisabled()
    
    func deviceInfoChanged(sdkHealth: HTSDKHealth)
    func devicePowerChanged(sdkHealth: HTSDKHealth)
    func locationConfigChanged(sdkHealth: HTSDKHealth)
    func networkConfigChanged(sdkHealth: HTSDKHealth)
}

class HTHealthManager: NSObject {

    let requestManager =  RequestManager()
    weak var healthEventDelegate: HTHealthEventsDelegate? = nil
    let reachabilityManager = Alamofire.NetworkReachabilityManager(host: "www.google.com")
    let lastUpTimeKey = "lastUpTimeKey"
    
    init(delegate: HTHealthEventsDelegate? = nil) {
        super.init()
        self.initializeDB()
        self.healthEventDelegate = delegate
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    
    func initializeDB(){
        do {
            DDLogInfo("creating health table")
            try HTDatabaseService.sharedInstance.healthDBHelper?.createTable()
        } catch  {
            DDLogError("not able to create table for health data")
        }
    }
    var currentPowerHealth: HTPowerState? {
        get {
            return self.getLastKnownInfo(infoType: .powerChanged) as? HTPowerState
        }
        set {
            if let newData = newValue{
                self.saveLastKnownInfo(infoType: .powerChanged, model: newData)
            }
        }
    }
    
    var currentDeviceInfo: HTDeviceInfo? {
        get {
            return self.getLastKnownInfo(infoType: .deviceInfoChanged) as? HTDeviceInfo
        }
        set {
            if let newData = newValue{
                self.saveLastKnownInfo(infoType: .deviceInfoChanged, model: newData)
            }
        }
    }
    
    
    var currentLocationConfig: HTLocationConfigHealth? {
        get {
            return self.getLastKnownInfo(infoType: .locationConfigChanged) as? HTLocationConfigHealth
        }
        set {
            if let newData = newValue{
                self.saveLastKnownInfo(infoType: .locationConfigChanged, model: newData)
            }
        }
    }
    
    var currentRadioHealth: HTRadioState? {
        get {
            return self.getLastKnownInfo(infoType: .radioChanged) as? HTRadioState
        }
        set {
            if let newData = newValue{
                self.saveLastKnownInfo(infoType: .radioChanged, model: newData)
            }
        }
    }
    
    func startTracking(){
        self.registerForDeviceHealthNotifications()
        self.startNetworkReachabilityObserver()

        self.checkDeviceInfoData()
        self.onPowerStateChange()
        self.onLocationConfigChange()
    }
    
    func stopTracking(){
        NotificationCenter.default.removeObserver(self)
    }
    
    func registerForDeviceHealthNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(onBatteryLevelChange(_:)), name: .UIDeviceBatteryLevelDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppTerminate(_:)), name: Notification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppStarted(_:)), name: Notification.Name.UIApplicationDidFinishLaunching, object: nil)
        
        if #available(iOS 9.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(onPowerSaverModeChange(_:)), name: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil)
        }
    }
    
    func startNetworkReachabilityObserver() {
        reachabilityManager?.listener = { status in
            self.onNetworkReachabilityChange(status: status)
        }
        
        reachabilityManager?.startListening()
        onNetworkReachabilityChange(status: (reachabilityManager?.networkReachabilityStatus)!)
    }
    
    func onNetworkReachabilityChange(status: NetworkReachabilityManager.NetworkReachabilityStatus){
        
        var isConnected = false
        switch status {
        case .notReachable:
            DDLogInfo("The network is not reachable")
            isConnected = false
            break
        case .unknown :
            DDLogInfo("It is unknown whether the network is reachable")
            isConnected = false
            break
        case .reachable(NetworkReachabilityManager.ConnectionType.ethernetOrWiFi):
            DDLogInfo("The network is reachable over the WiFi connection")
            isConnected = true
            break
        case .reachable(NetworkReachabilityManager.ConnectionType.wwan):
            isConnected = true
            break
        }
        
        var networkType = self.getNetworkType()

        if let isReachableViaWiFi = reachabilityManager?.isReachableOnEthernetOrWiFi {
            if isReachableViaWiFi {
                networkType = HTNetworkConnectionType.wifi
            }
        }
        let state = isConnected ? HTNetworkState.connected : HTNetworkState.disconnected
        
        let operatorName =  CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName ?? "unknown"
        let networkData = HTRadioState.init(operatorName: operatorName, state: state, network: networkType.rawValue)
        if let currentRecordedHealth = self.currentRadioHealth {
            if !networkData.isEqual(dataModel: currentRecordedHealth){
                if networkData.networkState != currentRecordedHealth.networkState{
                    if networkData.networkState == HTNetworkState.connected{
                        networkData.networkConnectedAt = Date()
                    }else{
                       networkData.networkDisconnectedAt = Date()
                    }
                }
                self.currentRadioHealth = networkData
                saveNetworkChangeHealthSegment(networkData: networkData)
            }
        }else{
            if networkData.networkState == HTNetworkState.connected{
                networkData.networkConnectedAt = Date()
            }else{
                networkData.networkDisconnectedAt = Date()
            }
            self.currentRadioHealth = networkData
            saveNetworkChangeHealthSegment(networkData: networkData)
        }
        
        self.currentRadioHealth = networkData
    }
    
    func onBatteryLevelChange(_ notification: Notification) {
       onPowerStateChange()
    }
    
    func onPowerSaverModeChange(_ notification: Notification) {
        onPowerStateChange()
    }
    
    func onPowerStateChange(){
        let chargingStatus  = getChargingStatus(batteryState: currentBatteryState())
        var powerSaverState  = false
        
        if #available(iOS 9.0, *) {
            powerSaverState = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        
        let source = HTPowerSourceTypes.usb
        let powerChangeData = HTPowerState.init(source: source.rawValue, percentage:currentBatteryLevel(), charging: chargingStatus.rawValue, isPowerSaver: powerSaverState)
        
        if let currentRecordedHealth = self.currentPowerHealth {
            if !powerChangeData.isEqual(dataModel: currentRecordedHealth){
                self.currentPowerHealth = powerChangeData
                savePowerChangeHealthSegment(powerState: powerChangeData)
            }
        }else{
            self.currentPowerHealth = powerChangeData
            savePowerChangeHealthSegment(powerState: powerChangeData)
        }
        
        self.currentPowerHealth = powerChangeData
    }
    
    func onLocationConfigChange(){
        var isEnabled = false
        var hasPermission = false
        
        if CLLocationManager.locationServicesEnabled() {
            isEnabled = true
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                DDLogDebug("No access")
            case .authorizedAlways, .authorizedWhenInUse:
                hasPermission = true
                DDLogDebug("Access")
            }
        } else {
            DDLogInfo("Location services are not enabled")
        }
        
        let locationData =  HTLocationConfigHealth.init(hasPermission: hasPermission, isEnabled: isEnabled, isMockEnabled: false)
        
        if let currentRecordedHealth = self.currentLocationConfig {
            if !locationData.isEqual(dataModel: currentRecordedHealth){
                saveLocationConfigSegment(locationData: locationData)
            }
        }else{
            saveLocationConfigSegment(locationData: locationData)
        }
        
        self.currentLocationConfig = locationData
    }
    
    func onAppStarted(_ notification: Notification) {
        if let healthEventDelegate = self.healthEventDelegate{
            healthEventDelegate.appDidStart(atTime: Date())
        }
    }
    
    func onAppTerminate(_ notification: Notification) {
        if let healthEventDelegate = self.healthEventDelegate{
            healthEventDelegate.appDidTerminate(atTime: Date())
        }
    }
    
    func checkDeviceInfoData(){
        let newData = HTDeviceInfo.getDeviceData()
        if let previousData = HTUserDefaults.standard.data(forKey: HTSDKHealthType.deviceInfoChanged.rawValue) {
            if let infoData = HTDeviceInfo.getModelFromJson(previousData){
                if !newData.isEqual(infoData) {
                    saveDeviceInfoChangeSegment(data: newData)
                }
            }else{
                saveDeviceInfoChangeSegment(data: newData)
            }
        }else{
            saveDeviceInfoChangeSegment(data: newData)
        }
        
        self.currentDeviceInfo = newData
    }
   
    func locationManager(_ manager: LocationManagerProtocol,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        onLocationConfigChange()
    }
    func saveDeviceInfoChangeSegment(data: HTDeviceInfo) {
        
        HTUserDefaults.standard.set(data.getJsonData(), forKey: HTSDKHealthType.deviceInfoChanged.rawValue)
        HTUserDefaults.standard.synchronize()
        
        let healthSegment = HTSDKHealth.init(lookupId: UUID().uuidString, type: .deviceInfoChanged, healthData: data)
        healthSegment.startTime = healthSegment.recordedAt
        healthSegment.endTime = healthSegment.recordedAt
        
        HTDatabaseService.sharedInstance.healthDBHelper?.insert(health: healthSegment)
        
        if let healthEventDelegate = self.healthEventDelegate{
            healthEventDelegate.deviceInfoChanged(sdkHealth: healthSegment)
        }
    }
    
   func currentBatteryLevel() -> Double{
        return Double(UIDevice.current.batteryLevel * 100.0)
    }
    
    func currentBatteryState() -> UIDeviceBatteryState {
        return UIDevice.current.batteryState
    }
    
    func saveNetworkChangeHealthSegment(networkData: HTRadioState) {

        DDLogInfo("device.radio.changed :" + networkData.toDict().description)
        let healthSegment = HTSDKHealth.init(lookupId: UUID().uuidString, type: .radioChanged, healthData: networkData)
        healthSegment.startTime = healthSegment.recordedAt
        healthSegment.endTime = healthSegment.recordedAt
        
        HTDatabaseService.sharedInstance.healthDBHelper?.insert(health: healthSegment)
        if let healthEventDelegate = self.healthEventDelegate{
            healthEventDelegate.networkConfigChanged(sdkHealth: healthSegment)
        }
    }
    
    func savePowerChangeHealthSegment(powerState: HTPowerState){
        DDLogInfo("battery status : " + powerState.toDict().description )
       let healthSegment = HTSDKHealth.init(lookupId: UUID().uuidString, type: .powerChanged, healthData: powerState)
        healthSegment.startTime = healthSegment.recordedAt
        healthSegment.endTime = healthSegment.recordedAt
        
        HTDatabaseService.sharedInstance.healthDBHelper?.insert(health: healthSegment)
        
        if let healthEventDelegate = self.healthEventDelegate{
            healthEventDelegate.devicePowerChanged(sdkHealth: healthSegment)
        }
    }
    
    func saveLocationConfigSegment(locationData: HTLocationConfigHealth) {
        let healthSegment = HTSDKHealth.init(lookupId: UUID().uuidString, type: .locationConfigChanged, healthData: locationData)
        healthSegment.startTime = healthSegment.recordedAt
        healthSegment.endTime = healthSegment.recordedAt
        
        HTDatabaseService.sharedInstance.healthDBHelper?.insert(health: healthSegment)
        
        if let healthEventDelegate = self.healthEventDelegate{
            healthEventDelegate.locationConfigChanged(sdkHealth: healthSegment)
        }
    }
    
    func getChargingStatus(batteryState: UIDeviceBatteryState) -> HTBatteryState{
        switch batteryState {
        case .charging:
            return HTBatteryState.charging
        case .unplugged:
            return HTBatteryState.discharging
        case .full:
            return HTBatteryState.full
        case .unknown:
            return HTBatteryState.unknown
       }
    }
    
    func getNetworkType() -> HTNetworkConnectionType{
        let telefonyInfo = CTTelephonyNetworkInfo()
        if let radioAccessTechnology = telefonyInfo.currentRadioAccessTechnology{
            switch radioAccessTechnology{
            case CTRadioAccessTechnologyLTE: return HTNetworkConnectionType.mobile4g
            case CTRadioAccessTechnologyWCDMA: return HTNetworkConnectionType.mobile3g
            case CTRadioAccessTechnologyEdge: return HTNetworkConnectionType.mobile2g
            case CTRadioAccessTechnologyGPRS: return HTNetworkConnectionType.mobile2g
            case CTRadioAccessTechnologyeHRPD: return HTNetworkConnectionType.mobile3g
            case CTRadioAccessTechnologyHSDPA: return HTNetworkConnectionType.mobile3g
            default: return HTNetworkConnectionType.unknownConnection
            }
        }
        return HTNetworkConnectionType.unknownConnection
    }
    
    func getLastKnownInfo(infoType: HTSDKHealthType) -> HTHealthDataProtocol? {
        if let data = HTUserDefaults.standard.data(forKey: infoType.rawValue){
            if let infoData = HTSDKHealth.getHealthData(data: data, type: infoType){
                return infoData
            }
        }
        return nil
    }
    
    func saveLastKnownInfo(infoType: HTSDKHealthType, model: HTHealthDataProtocol ) {
        HTUserDefaults.standard.set(model.getJsonData(), forKey: infoType.rawValue)
        HTUserDefaults.standard.synchronize()
    }
    
    func didInfoChangedFor(infoType: HTSDKHealthType, newValue: HTHealthDataProtocol) -> Bool {
        var didChange = true
        let lastKnownInfo = getLastKnownInfo(infoType: infoType)
        if (lastKnownInfo?.isEqual(dataModel: newValue))! {
            didChange = false
        }
        return didChange
    }
    
    func getHealthForLookUpId(lookupId: String) -> HTSDKHealth? {
        return HTDatabaseService.sharedInstance.healthDBHelper?.getHealthForLookUpId(lookupId: lookupId)
    }

    
    func didDeviceRestart() -> Bool{
        if let timeInterval = getLastSavedSystemUpTime() {
            if timeInterval > getLastSystemUpTime() {
                return true
            }
        }
        return false
    }
    
    func saveUpTime(upTime: TimeInterval){
        HTUserDefaults.standard.set(upTime, forKey: lastUpTimeKey)
    }
 
    func getLastSavedSystemUpTime() -> TimeInterval? {
       return HTUserDefaults.standard.double(forKey:lastUpTimeKey)
    }
    
    func getLastSystemUpTime() -> TimeInterval{
        return ProcessInfo.processInfo.systemUptime
    }
    
    

}
