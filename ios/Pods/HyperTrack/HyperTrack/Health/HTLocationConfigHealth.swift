//
//  HTLocationConfigHealth.swift
//  HyperTrack
//
//  Created by ravi on 11/1/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

class HTLocationConfigHealth: HTHealthDataProtocol {

    let hasLocationPermission: Bool
    let isLocationEnabled: Bool
    let isMockLocationEnabled: Bool
    let locationAccuracy = "high"
    
    init(hasPermission: Bool, isEnabled: Bool, isMockEnabled: Bool) {
        self.hasLocationPermission = hasPermission
        self.isLocationEnabled = isEnabled
        self.isMockLocationEnabled = isMockEnabled
    }
    
    func isEqual(_ data: HTLocationConfigHealth) -> Bool{
        if self.hasLocationPermission != data.hasLocationPermission {
            return false
        }else if self.isLocationEnabled != data.isLocationEnabled {
            return false
        }else if self.isMockLocationEnabled != data.isMockLocationEnabled {
            return false
        }else if self.locationAccuracy != data.locationAccuracy {
            return false
        }
        return true
    }
    
    func isEqual(dataModel: HTHealthDataProtocol) -> Bool {
        if let model = HTLocationConfigHealth.getModelFromJson(dataModel.getJsonData()) {
            return self.isEqual(model)
        }
        return false
    }

    func toDict() -> [String: Any]{
        var dict = [String: Any]()
        dict["has_location_permission"] = hasLocationPermission
        dict["is_location_enabled"] = isLocationEnabled
        dict["is_mock_location_enabled"] = isMockLocationEnabled
        dict["location_accuracy"] = locationAccuracy
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
    
    public static func getModelFromJson(_ data: Data) -> HTLocationConfigHealth? {
        do {
            let locationConfigChangeDict = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let dict = locationConfigChangeDict as? [String: Any] else {
                return nil
            }
            
            let hasPermission = dict["has_location_permission"] as? Bool
            let isEnabled = dict["is_location_enabled"] as? Bool
            let isMockEnabled = dict["is_mock_location_enabled"] as? Bool
            
            let locationConfigData = HTLocationConfigHealth.init(hasPermission: hasPermission ?? true, isEnabled: isEnabled ?? true, isMockEnabled: isMockEnabled ?? false)
            
            return locationConfigData
        } catch {
            DDLogError("Error in getting location from json: " + error.localizedDescription)
        }
        return nil
    }
}
