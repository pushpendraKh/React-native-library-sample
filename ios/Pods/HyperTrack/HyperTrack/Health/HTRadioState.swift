//
//  HTRadioState.swift
//  HyperTrack
//
//  Created by ravi on 11/1/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

public enum HTNetworkConnectionType: String {
    case wifi = "wifi"
    case mobile2g = "2g"
    case mobile3g = "3g"
    case mobile4g = "4g"
    case unknownConnection = "none"
}

public enum HTNetworkState: String {
    case connected = "connected"
    case disconnected = "disconnected"
}


class HTRadioState: HTHealthDataProtocol {
    
    let networkConnectedKey = "networkConnectedKey"
    let networkDisconnectedKey = "networkDisconnectedKey"

    let networkOperator: String
    let networkState: HTNetworkState
    let networkType: String

    var networkConnectedAt: Date? {
        get {
            return HTUserDefaults.standard.object(forKey: networkConnectedKey) as? Date
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: networkConnectedKey)
            HTUserDefaults.standard.synchronize()
        }
    }
    
    var networkDisconnectedAt: Date? {
        get {
            return HTUserDefaults.standard.object(forKey: networkDisconnectedKey) as? Date
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: networkDisconnectedKey)
            HTUserDefaults.standard.synchronize()
        }
    }
    
    init(operatorName: String, state: HTNetworkState, network: String) {
        self.networkOperator = operatorName
        self.networkState = state
        self.networkType = network
    }
    
    func isEqual(_ data: HTRadioState) -> Bool{
        if self.networkOperator != data.networkOperator{
            return false
        }
        else if self.networkState != data.networkState{
            return false
        }
        else if self.networkType != data.networkType{
            return false
        }
        
        return true
    }
    
    
    func isEqual(dataModel: HTHealthDataProtocol) -> Bool {
        if let model = HTRadioState.getModelFromJson(dataModel.getJsonData()) {
            return self.isEqual(model)
        }
        return false
    }
    
    func toDict() -> [String: Any]{
        var dict = [String: Any]()
        dict["network_operator"] = networkOperator
        dict["network_state"] = networkState.rawValue
        dict["network_type"] = networkType
        dict["network_connected_at"] = networkConnectedAt?.iso8601
        dict["network_disconnected_at"] = networkDisconnectedAt?.iso8601 ?? NSNull()
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
    
    public static func getModelFromJson(_ data: Data) -> HTRadioState? {
        do {
            let radioInfoDict = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let dict = radioInfoDict as? [String: Any] else {
                return nil
            }
            
            let operatorName =  dict["network_operator"] as? String
            let state = dict["network_state"] as? String ?? HTNetworkState.connected.rawValue
            let network = dict["network_type"] as? String
            
            let radioData = HTRadioState.init(operatorName: operatorName ?? "", state: HTNetworkState(rawValue: state)!,  network: network ?? "")
            
            return radioData
        } catch {
            DDLogError("Error in getting location from json: " + error.localizedDescription)
        }
        return nil
    }
}
