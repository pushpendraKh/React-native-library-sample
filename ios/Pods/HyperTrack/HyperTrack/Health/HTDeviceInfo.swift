//
//  HTDeviceInfo.swift
//  HyperTrack
//
//  Created by ravi on 11/1/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

class HTDeviceInfo: HTHealthDataProtocol {
    
    let deviceId: String
    let appVersion: String
    let appPackageName: String
    let sdkVersion: String
    let timeZone: String
    let osName: String
    let osVersion: String
    let deviceModel: String
    let deviceManufacturer: String
    
    init(deviceId: String,
         appVersion: String,
         appPackageName: String,
         sdkVersion: String,
         timeZone: String,
         osName: String,
         osVersion: String,
         model: String,
         manufacturer: String) {
        self.deviceId = deviceId
        self.appVersion = appVersion
        self.appPackageName  = appPackageName
        self.sdkVersion = sdkVersion
        self.timeZone = timeZone
        self.osName = osName
        self.osVersion = osVersion
        self.deviceModel = model
        self.deviceManufacturer = manufacturer
    }
    
    
    func toDict() -> [String: Any]{
        var dict = [String: Any]()
        dict["device_id"] = deviceId
        dict["app_version"] = appVersion
        dict["app_package_name"] = appPackageName
        dict["sdk_version"] = sdkVersion
        dict["time_zone"] = timeZone
        dict["os_name"] = osName
        dict["os_version"] = osVersion
        dict["device_model"] = deviceModel
        dict["device_manufacturer"] = deviceManufacturer
        return dict
    }
    
    func getJsonData() -> Data {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            return jsonData
        } catch {
            DDLogError("Error serializing object to JSON: " + error.localizedDescription)
            return Data()
        }    }
    
    
    
    func isEqual(dataModel: HTHealthDataProtocol) -> Bool {
        if let model = HTDeviceInfo.getModelFromJson(dataModel.getJsonData()) {
            return self.isEqual(model)
        }
        return false
    }
    
    func isEqual(_ infoData: HTDeviceInfo) -> Bool {
        
        if self.deviceId != infoData.deviceId{
            return false
        }else if self.appVersion != infoData.appVersion {
            return false
        }
        else if self.appPackageName != infoData.appPackageName {
            return false
        }
        else if self.sdkVersion != infoData.sdkVersion {
            return false
        }
        else if self.timeZone != infoData.timeZone {
            return false
        }
        else if self.osName != infoData.osName {
            return false
        }
        else if self.osVersion != infoData.osVersion {
            return false
        }
        else if self.deviceModel != infoData.deviceModel {
            return false
        }
        else if self.deviceManufacturer != infoData.deviceManufacturer {
            return false
        }
        return true
    }
    
    public static func getModelFromJson(_ data: Data) -> HTDeviceInfo? {
        do {
            let devcieInfoDict = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let dict = devcieInfoDict as? [String: String] else {
                return nil
            }
            
            let deviceId = dict["device_id"]
            let sdkVersion = dict["sdk_version"]
            let timeZone = dict["time_zone"]
            let osName =  dict["os_name"]
            let osVersion = dict["os_version"]
            let model = dict["device_model"]
            let manufacturer = "apple"
            let appVersion = dict["app_version"]
            let appPackageName = dict["app_package_name"]
            
            let deviceData = HTDeviceInfo.init(deviceId: deviceId ?? "", appVersion: appVersion ?? "", appPackageName: appPackageName ?? "", sdkVersion: sdkVersion ?? "", timeZone: timeZone ?? "", osName: osName ?? "", osVersion: osVersion ?? "", model: model ?? "", manufacturer: manufacturer)
            
            return deviceData
        } catch {
            DDLogError("Error in getting location from json: " + error.localizedDescription)
        }
        return nil
    }

    public static func getDeviceData() -> HTDeviceInfo {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString
        let sdkVersion = Settings.sdkVersion
        let timeZone = TimeZone.current.identifier
        let osName =  UIDevice.current.systemName
        let osVersion = UIDevice.current.systemVersion
        let model = UIDevice.current.model
        let manufacturer = "apple"
        var appVersion = ""
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
        
        let appPackageName = Bundle.main.bundleIdentifier ?? ""
        
        let deviceData = HTDeviceInfo.init(deviceId: deviceId ?? UUID().uuidString, appVersion: appVersion, appPackageName: appPackageName, sdkVersion: sdkVersion, timeZone: timeZone, osName: osName, osVersion: osVersion, model: model, manufacturer: manufacturer)
        
        return deviceData
    }

}
