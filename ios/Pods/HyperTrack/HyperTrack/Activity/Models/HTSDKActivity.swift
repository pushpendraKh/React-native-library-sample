//
//  HTActivity.swift
//  Pods
//
//  Created by ravi on 9/3/17.
//
//

import UIKit
import CoreMotion
import CocoaLumberjack

public enum HTActivityType: String {
    case walk
    case run
    case cycle
    case drive
    case stop
    case unknown
    case moving
}

public enum HTUnknownActivityType: String {
    case locationDisabled = "location_disabled"
    case locationPermissionDenied = "location_permission_denied"
    case activityPermissionDenied = "activity_permission_denied"
    case deviceOff = "device_off"
    case sdkInactive = "sdk_inactive"
}

@objc public class HTSDKActivity: HTSegment {

    public var type: HTActivityType
    public var stepDistance: Int = 0
    public var stepCount: Int = 0
    public var experimentId: String?
    public var confidence: Double = 0.0
    public var unknownReason: HTUnknownActivityType?
    
    public init(lookUpId: String, type: HTActivityType, startTime: Date){
        self.type = type;
        super.init(lookupId: lookUpId, segmentType: HTSegmentType.activity,recordedAt: Date(), startTime: startTime)
        self.startTime = startTime
    }
    
    func isHigherPriorityUknknownActivityFrom(sdkActivity: HTSDKActivity) -> Bool{
        let priorityOrder = [HTUnknownActivityType.locationDisabled,
                             HTUnknownActivityType.locationPermissionDenied,
                             HTUnknownActivityType.activityPermissionDenied,
                             HTUnknownActivityType.deviceOff,
                             HTUnknownActivityType.sdkInactive]
        
        if sdkActivity.type != HTActivityType.unknown {
            return false
        }
        
        if self.type != HTActivityType.unknown{
            return true
        }
        
        if self.unknownReason != nil && sdkActivity.unknownReason != nil {
            let indexOfFirstUnknownReason = priorityOrder.index(of: self.unknownReason!)
            let indexOfSecondUnknownReason = priorityOrder.index(of: sdkActivity.unknownReason!)
            if indexOfFirstUnknownReason! > indexOfSecondUnknownReason! {
                return false
            }else{
                return true
            }
        }
        
        return false
    }
    
    func getJsonForExtraData() -> Data {
        var dict = [String: Any]()
        dict["step_distance"] = stepDistance
        dict["step_count"] = stepCount
        dict["experiment_id"] = experimentId
        dict["confidence"] = confidence
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            return jsonData
        } catch {
            DDLogError("Error serializing object to JSON: " + error.localizedDescription)
            return Data()
        }
    }
    
    func setJsonDataToModel(data: Data){
        do {
            let extraInfoDict = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let dict = extraInfoDict as? [String: Any] else {
                return
            }
            
            self.stepCount =  dict["step_count"] as? Int ?? 0
            self.stepDistance = dict["step_distance"] as? Int ?? 0
            self.experimentId = dict["experiment_id"] as? String
            self.confidence = dict["confidence"] as! Double
            
            return
        } catch {
            DDLogError("Error in getting location from json: " + error.localizedDescription)
        }
        return 
    }
    
    func isTypeSame(activity: HTSDKActivity) -> Bool{
        
        if self.sessionId != activity.sessionId{
            return false
        }
        
        if self.type == activity.type{
            if self.type == HTActivityType.unknown {
                if self.unknownReason == activity.unknownReason{
                    return true
                }
            }
            else{
                return true
            }
        }
        return false
    }
    
    public static func getSDKActivityFromOSActivity(osActivity: CMMotionActivity) -> HTSDKActivity{
        let sdkActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: getActivityType(activity: osActivity), startTime: Date())
        sdkActivity.confidence = getConfidence(activity: osActivity)
        return sdkActivity
    }
    
    public static func getActivityType(activity: CMMotionActivity) -> HTActivityType {
        /*
         *  CMMotionActivity
         *
         *  Discussion:
         *    An estimate of the user's activity based on the motion of the device.
         *
         *    The activity is exposed as a set of properties, the properties are not
         *    mutually exclusive.
         *
         *    For example, if you're in a car stopped at a stop sign the state might
         *    look like:
         *       stationary = YES, walking = NO, running = NO, automotive = YES
         *
         *    Or a moving vehicle,
         *       stationary = NO, walking = NO, running = NO, automotive = YES
         *
         *    Or the device could be in motion but not walking or in a vehicle.
         *       stationary = NO, walking = NO, running = NO, automotive = NO.
         *    Note in this case all of the properties are NO.
         *
         */

        if activity.walking {
            return HTActivityType.walk
        } else if activity.running {
            return HTActivityType.run
        } else if activity.automotive {
            return HTActivityType.drive
        } else if activity.cycling {
            return HTActivityType.cycle
        } else if activity.stationary {
            return HTActivityType.stop
        } else if activity.unknown {
            return HTActivityType.unknown
        } else {
            return HTActivityType.moving
        }
    }
    
    public static func getConfidence(activity: CMMotionActivity) -> Double {
        if activity.confidence.rawValue == 0 {
            return 0.33
        } else if activity.confidence.rawValue == 50 {
            return 0.66
        } else if activity.confidence.rawValue == 100 {
            return 0.99
        }

        return 0.33
    }
    
    public func toDict() -> [String: Any]{
        let dict = [
            "type": self.type.rawValue,
            "unknown_reason": self.unknownReason?.rawValue ?? "",
            "confidence": self.confidence,
            "started_at": self.startTime.iso8601,
            "ended_at": self.endTime?.iso8601 ?? NSNull.init(),
            "step_distance": self.stepDistance,
            "step_count": self.stepCount,
            "lookup_id": self.lookupId
            ] as [String: Any]
        return dict
    }
    
    func isMovingActivity() -> Bool{
        var isMoving = true
        if self.type == HTActivityType.stop || self.type == HTActivityType.unknown{
            isMoving = false
        }
        return isMoving
    }
    
    public func toHTActivity() -> HTActivity {
        let dict: HTPayload = [
            "id": self.lookupId,
            "type": self.type.rawValue,
            "activity": self.unknownReason?.rawValue ?? "",
            "started_at": self.startTime.iso8601,
            "ended_at": self.endTime?.iso8601 ?? "",
            "unknown_reason": unknownReason?.rawValue ?? ""
        ]
        return HTActivity(dict: dict)
    }
}
