//
//  HTUser.swift
//  HyperTrack
//
//  Created by Atul Manwar on 06/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

@objc public class HTUser: NSObject, HTModelProtocol {
    /**
     Unique (uuid4) identifier for the user
     */
    public let id: String
    
    public let groupId: String?
    
    public let uniqueId: String?
    
    public let availabilityStatus: String?
    
    var userAvailabilityStatus: AvailabilityStatus {
        guard let status = availabilityStatus else {
            return .unknown
        }
        return AvailabilityStatus(rawValue: status)
    }
    
    public let vehicleType: String?
    
    public let lastOnlineAt: Date?
    
    public let createdAt: Date?
    
    public let modifiedAt: Date?
    
    public let segmentStatus: String?
    
    public let display: Display?
    
    public let isTracking: Bool
    
    /**
     Name of the user (optional)
     */
    public let name: String?
    
    /**
     Phone number for the user (optional)
     */
    public let phone: String?
    
    /**
     Photo url for the user (optional)
     */
    public let photo: String?
    
    /**
     Last heartbeat timestamp for the user (read-only)
     */
    public let lastHeartbeatAt: Date?
    
    /**
     Last location for the user (read-only)
     */
    public let lastLocation: HTLocation?
    
    /**
     Last battery level for the user (read-only)
     */
    public let lastBattery: Int?
    
    /**
     Last internet connection status of user
     */
    public let isConnected: Bool
    
    /**
     Last location availability status
     */
    public let locationStatus: String?
    
    required public init(dict: HTPayload) {
        id = (dict["id"] as? String) ?? ""
        groupId = (dict["group_id"] as? String)
        uniqueId = (dict["unique_id"] as? String)
        name = (dict["name"] as? String)
        phone = (dict["phone"] as? String)
        photo = (dict["photo"] as? String)
        availabilityStatus = (dict["availability_status"] as? String)
        vehicleType = (dict["vehicle_type"] as? String)
        isConnected = (dict["is_connected"] as? Bool) ?? false
        if let payload = dict["last_location"] as? HTPayload {
            lastLocation = HTLocation(dict: payload)
        } else {
            lastLocation = nil
        }
        lastHeartbeatAt = (dict["last_heartbeat_at"] as? String)?.dateFromISO8601
        lastOnlineAt = (dict["last_online_at"] as? String)?.dateFromISO8601
        lastBattery = (dict["last_battery"] as? Int)
        locationStatus = (dict["location_status"] as? String)
        segmentStatus = (dict["segment_status"] as? String)
        if let payload = dict["display"] as? HTPayload {
            display = Display(dict: payload)
        } else {
            display = nil
        }
        createdAt = (dict["created_at"] as? String)?.dateFromISO8601
        modifiedAt = (dict["modified_at"] as? String)?.dateFromISO8601
        isTracking = (dict["is_tracking"] as? Bool) ?? false
    }
    
    public enum AvailabilityStatus {
        case online
        case offline
        case unknown
        case other(String)
        
        init(rawValue: String) {
            switch rawValue {
            case "online":
                self = .online
            case "offline":
                self = .offline
            case "unknown":
                self = .unknown
            default:
                self = .other(rawValue)
            }
        }
    }
    
    public class Display: NSObject {
        public let lastUpdatedText: String?
        public let warningSinceText: String?
        public let battery: Int?
        public let statusText: String?
        public let isWarning: Bool
        
        init(dict: HTPayload) {
            lastUpdatedText = (dict["last_updated_text"] as? String)
            warningSinceText = (dict["warning_since_text"] as? String)
            battery = (dict["battery"] as? Int)
            statusText = (dict["status_text"] as? String)
            isWarning = (dict["is_warning"] as? Bool) ?? false
        }
    }
    
    internal func toDict() -> HTPayload {
        let dict = [
            "id": id,
            "name": name ?? "",
            "phone": phone ?? "",
            "photo": photo ?? ""
            ] as [String:Any]
        return dict
    }
    
    public func toJson() -> String? {
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
    
    internal static func fromJson(text: String) -> HTUser? {
        if let data = text.data(using: .utf8) {
            do {
                let userDict = try JSONSerialization.jsonObject(with: data, options: [])
                guard let dict = userDict as? [String : Any] else {
                    return nil
                }
                return HTUser(dict: dict)
            } catch {
                DDLogError("Error in getting user from json: " + error.localizedDescription)
            }
        }
        return nil
    }
}

