//
//  HTEvents.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 21/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack

/**
 The HyperTrackEvent type enum. Represents all the different types of events possible.
 */
public enum HyperTrackEventType: String {
    
    
    /**
     Event type for start tracking
     */
    case trackingStarted = "tracking.resumed"
    
    /**
     Event type for end tracking
     */
    case trackingEnded = "tracking.paused"
    
    /**
     Event type for location changed
     */
    case locationChanged = "location.changed"
    
    /**
     Event type for activity started
     */
    case activityStarted = "activity.started"
    
    /**
     Event type for activity ended
     */
    case activityEnded = "activity.ended"
    
    /**
     Event type for activity updated
     */
    case activityUpdated = "activity.updated"
    
    /**
     Event type for device power status changed
     */
    case powerChanged  = "health.power.changed"

    /**
     Event type for device radio status changed
     */
    case radioChanged = "health.radio.changed"

    /**
     Event type for device location configuration changed
     */
    case locationConfigChanged = "health.location.changed"

    /**
     Event type for device info changed
     */
    case infoChanged = "health.info.changed"
    
     /**
     Event type for action completed
     */
    case actionCompleted = "action.completed"
}

/**
 The HyperTrackEvent object that represents events as they happen in the lifetime of a tracking session
 */
@objc public class HyperTrackEvent: NSObject {

    /**
     Unique (uuid4) identifier for the event
     */
    public var id: Int64?

    /**
     Id of user for the event
     */
    public let userId: String
    
    /**
     Id of session for the event
     */
    public let sessionId: String
    
    /**
     Id of device for the event
     */
    public let deviceId: String
    
    /**
     Timestamp when the event was recorded
     */
    public var recordedAt: Date
    
    /**
     Type of the event
     */
    public let eventType: HyperTrackEventType
    
    
    /**
     activityLookUpId
     */
    public let activityLookUpId: String
    
    /**
     locationLookUpId
     */
    public var locationLookUpId: String
    
    
    /**
     healthLookUpId
     */
    public let healthLookUpId: String
    
    /**
     Metadata for the event
     */
    public var data: [String: Any]

    init(userId: String,
         sessionId: String,
         deviceId: String,
         recordedAt: Date,
         eventType: HyperTrackEventType,
         activityLookUpId: String,
         locationLookUpId: String,
         healthLookUpId: String,
         data: [String: Any] = [String: Any]()) {
        self.id = nil
        self.userId = userId
        self.deviceId = deviceId
        self.sessionId = sessionId
        self.recordedAt = recordedAt
        self.eventType = eventType
        self.activityLookUpId = activityLookUpId
        self.healthLookUpId = healthLookUpId
        self.locationLookUpId = locationLookUpId
        self.data = data
    }
    
    public func getActivity() -> HTSDKActivity? {
        if self.activityLookUpId != "" {
            return HTSDKDataManager.sharedInstance.activityManager.getActivityFromLookUpId(lookUpId: self.activityLookUpId)
        }
        return nil
    }
    
    public func getLocation() -> HTLocation? {
        if self.locationLookUpId != "" {
            return HTSDKDataManager.sharedInstance.locationManager.getLocationFromLookUpId(lookUpId: self.locationLookUpId)
        }
        return nil
    }
    
    public func getHealth() -> HTSDKHealth? {
        if self.healthLookUpId != ""{
            return HTSDKDataManager.sharedInstance.healthManager.getHealthForLookUpId(lookupId: self.healthLookUpId)
        }
        return nil
    }

    internal func toDict() -> [String: Any] {
        let dict = [
            "user_id": self.userId,
            "session_id": self.sessionId,
            "device_id": self.deviceId,
            "activity_lookupid": self.activityLookUpId,
            "location_lookupid": self.locationLookUpId,
            "health_lookupid": self.healthLookUpId,
            "recorded_at": self.recordedAt.iso8601,
            "type": self.eventType.rawValue,
            "data": self.data
            ] as [String: Any]
        return dict
    }
    
    internal func toServerParams() -> [String: Any] {
        var dict = [
            "user_id": self.userId,
            "session_id": self.sessionId,
            "device_id": self.deviceId,
            "recorded_at": self.recordedAt.iso8601,
            "type": self.eventType.rawValue,
            "data": self.data
            ] as [String: Any]
        
        if let activity = self.getActivity(){
            dict["activity"] = activity.toDict()
        }
        
        if let location = self.getLocation(){
            dict["location"] =  location.toDict()
        }
        
        if let health = self.getHealth(){
            dict["health"] =  health.toDict()
        }

        return dict
    }


    internal func toJson() -> String? {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString
        } catch {
            DDLogError("Error serializing object to JSON: " + error.localizedDescription)
            return nil
        }
    }

    internal static func fromDict(dict: [String: Any]) -> HyperTrackEvent? {
        guard let userId = dict["user_id"] as? String,
            let recordedAt = dict["recorded_at"] as? String,
            let eventType = dict["type"] as? String
        else {
                return nil
        }

        guard let recordedAtDate = recordedAt.dateFromISO8601 else {
            return nil
        }
        
        let activityLookUpID = dict["activity_lookupid"] as? String ?? ""
        let locationLookUpId = dict["location_lookupid"] as? String ?? ""
        let healthLookUpId = dict["health_lookupid"] as? String ?? ""
        let deviceID = dict["device_id"] as? String ?? ""
        let sessionID = dict["session_id"] as? String ?? ""
        
        let event = HyperTrackEvent(userId: userId, sessionId: sessionID, deviceId: deviceID, recordedAt: recordedAtDate, eventType: HyperTrackEventType(rawValue: eventType)!, activityLookUpId: activityLookUpID, locationLookUpId: locationLookUpId, healthLookUpId: healthLookUpId)
        return event

    }

    internal static func fromJson(text: String) -> HyperTrackEvent? {
        if let data = text.data(using: .utf8) {
            do {
                let eventDict = try JSONSerialization.jsonObject(with: data, options: [])

                guard let dict = eventDict as? [String: Any] else {
                    return nil
                }

                return self.fromDict(dict: dict)
            } catch {
                DDLogError("Error in getting event from json: " + error.localizedDescription)
            }
        }
        return nil
    }

}


extension Date {
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    static let iso8601Second: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssz"
        return formatter
    }()
    
    var iso8601: String {
        return Date.iso8601Formatter.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        
        if let date =  Date.iso8601Formatter.date(from: self) {
            return date
        } else {
            if let date = Date.iso8601Second.date(from: self) {
                return date
            }
        }
        
        return nil
        
    }
}

extension Locale {
    static let timeFormat: String = {
        let value = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:NSLocale.current) ?? ""
        if value.isEmpty || value.contains("a") {
            return "h:mm a"
        } else {
            return "HH:mm"
        }
    }()
}
