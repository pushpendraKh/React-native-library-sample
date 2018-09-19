//
//  HTSDKHealth.swift
//  HyperTrack
//
//  Created by ravi on 10/30/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit


public protocol  HTHealthDataProtocol: class {
    func getJsonData() -> Data
    func toDict() -> [String: Any]
    func isEqual(dataModel: HTHealthDataProtocol) -> Bool
}

public enum HTSDKHealthType: String {
    case deviceInfoChanged = "health.device_info.changed"
    case radioChanged = "health.radio.changed"
    case powerChanged = "health.power.changed"
    case locationConfigChanged = "health.location_config.changed"
}

public class HTSDKHealth: HTSegment {
    
    public let type: HTSDKHealthType
    public let healthData: HTHealthDataProtocol
    
    init(lookupId: String, type: HTSDKHealthType, healthData: HTHealthDataProtocol) {
        self.type = type
        self.healthData = healthData
        let recordedAt = Date()
        super.init(lookupId: lookupId, segmentType: HTSegmentType.health, recordedAt: recordedAt, startTime: recordedAt)
    }
    
    public static func getHealthData(data: Data, type: HTSDKHealthType) -> HTHealthDataProtocol?{
        switch type {
        case .deviceInfoChanged:
            return HTDeviceInfo.getModelFromJson(data)
        case .radioChanged:
            return HTRadioState.getModelFromJson(data)
        case .powerChanged:
            return HTPowerState.getModelFromJson(data)
        case .locationConfigChanged:
            return HTLocationConfigHealth.getModelFromJson(data)
         }
    }
    
    public func toDict() -> [String: Any]{
        return self.healthData.toDict()        
    }
}

