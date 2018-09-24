//
//  HTEventUtils.swift
//  HyperTrack
//
//  Created by ravi on 11/14/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

class HTEventUtils: NSObject {

    public static func getSDKEventFrom(location: HTLocation, activityLookUpId: String) -> HyperTrackEvent{
        
        let event  = HyperTrackEvent.init(userId: HTUserService.sharedInstance.userId ?? "", sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: location.recordedAt, eventType: .locationChanged, activityLookUpId: activityLookUpId, locationLookUpId: location.lookUpId!, healthLookUpId:"")
    
        return event
    }
    
    public static func getSDKEventFrom(health: HTSDKHealth, activityLookUpId: String) -> HyperTrackEvent{
        
        let eventType = HTEventUtils.getEventTypeFromHealthType(healthType: health.type)
        let event  = HyperTrackEvent.init(userId: HTUserService.sharedInstance.userId ?? "", sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: health.recordedAt, eventType: eventType, activityLookUpId: activityLookUpId, locationLookUpId: "", healthLookUpId:health.lookupId)
        
        return event
    }
    
    public static func getSDKEventFrom(activity: HTSDKActivity, type: HyperTrackEventType) -> HyperTrackEvent{

        let event  = HyperTrackEvent.init(userId: HTUserService.sharedInstance.userId ?? "", sessionId: Settings.sessionId, deviceId: Settings.deviceId, recordedAt: activity.recordedAt, eventType: type, activityLookUpId: activity.lookupId, locationLookUpId: "", healthLookUpId:"")
        
        return event
    }
   
    public static func getEventTypeFromHealthType(healthType: HTSDKHealthType) -> HyperTrackEventType{
        
        switch healthType {
        case .deviceInfoChanged:
            return HyperTrackEventType.infoChanged
        case .radioChanged:
            return HyperTrackEventType.radioChanged
        case .powerChanged:
            return HyperTrackEventType.powerChanged
        case .locationConfigChanged:
            return HyperTrackEventType.locationConfigChanged
       }
    }
    
}
