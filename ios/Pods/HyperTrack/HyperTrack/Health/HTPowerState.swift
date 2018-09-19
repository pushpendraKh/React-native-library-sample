//
//  HTPowerState.swift
//  HyperTrack
//
//  Created by ravi on 11/1/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

public enum HTBatteryState: String {
    case charging = "charging"
    case discharging = "discharging"
    case full = "full"
    case unknown = "unknown"
    case notCharging = "not_charging"
}

public enum HTPowerSourceTypes: String {
    case battery
    case ac
    case usb
    case wireless
}

class HTPowerState: HTHealthDataProtocol {
    
    let powerSource: String
    let batteryPercentage: Double
    let chargingState: String
    let isPowerSaver: Bool
    
    init(source: String, percentage: Double, charging: String, isPowerSaver: Bool) {
        self.powerSource = source
        self.batteryPercentage = percentage
        self.chargingState = charging
        self.isPowerSaver = isPowerSaver
    }
    
    func isEqual(_ data: HTPowerState) -> Bool{
        if self.powerSource != data.powerSource {
            return false
        }
        else if self.batteryPercentage != data.batteryPercentage{
            return false
        }
        else if self.chargingState != data.chargingState{
            return false
        }
        else if self.isPowerSaver != data.isPowerSaver{
            return false
        }
        
        return true
    }
    
    func toDict() -> [String: Any]{
        var dict = [String: Any]()
        dict["power_source"] = powerSource
        dict["battery_percentage"] = batteryPercentage
        dict["charging_state"] = chargingState
        dict["is_power_saver"] = isPowerSaver
        
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
        }
    }
    
    func isEqual(dataModel: HTHealthDataProtocol) -> Bool {
        if let model = HTPowerState.getModelFromJson(dataModel.getJsonData()) {
            return self.isEqual(model)
        }
        return false
    }
    
    
    public static func getModelFromJson(_ data: Data) -> HTPowerState? {
        do {
            let powerInfoDict = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let dict = powerInfoDict as? [String: Any] else {
                return nil
            }
            
            let source = dict["power_source"] as? String
            let percentage = dict["battery_percentage"] as? Double
            let charging = dict["charging_state"] as? String
            let isPowerSaverEnabled = dict["is_power_saver"] as? Bool
            
            let powerData = HTPowerState.init(source: source ?? "", percentage: percentage ?? 0.0, charging: charging ?? "charging", isPowerSaver: isPowerSaverEnabled ?? true)
            
            return powerData
        } catch {
            DDLogError("Error in getting location from json: " + error.localizedDescription)
        }
        return nil
    }
}
