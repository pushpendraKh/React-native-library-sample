//
//  HTActivity.swift
//  HyperTrack
//
//  Created by Atul Manwar on 09/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public class HTActivity: NSObject {
    public let id: String
    public let userId: String
    public let lookupId: String?
    public let type: String
    var activityType: ActivityType {
        return ActivityType(string: type)
    }
    public let unknownReason: String?
    public let startedAt: Date?
    public let endedAt: Date?
    public let duration: Double?
    public let distance: Double?
    public let place: HTPlace?
    public let route: String?
    public let locationTimeSeries: String?
    public let stepCount: Int?
    public let stepDistance: String?
    public let createdAt: Date?
    public let modifiedAt: Date?
    
    public init(dict: HTPayload) {
        id = (dict["id"] as? String) ?? ""
        userId = (dict["user_id"] as? String) ?? ""
        lookupId = (dict["lookup_id"] as? String)
        type = (dict["type"] as? String) ?? "unknown"
        unknownReason = (dict["unknown_reason"] as? String)
        startedAt = (dict["started_at"] as? String)?.dateFromISO8601
        endedAt = (dict["ended_at"] as? String)?.dateFromISO8601
        duration = (dict["duration"] as? Double)
        distance = (dict["distance"] as? Double)
        if let payload = dict["place"] as? HTPayload {
            place = HTPlace(dict: payload)
        } else {
            place = nil
        }
        route = (dict["route"] as? String)
        locationTimeSeries = (dict["location_time_series"] as? String)
        stepCount = (dict["step_count"] as? Int)
        stepDistance = (dict["step_distance"] as? String)
        createdAt = (dict["created_at"] as? String)?.dateFromISO8601
        modifiedAt = (dict["modified_at"] as? String)?.dateFromISO8601
    }
    
    func toDict() -> [String: Any] {
        return [
            "id": id ?? "",
            "user_id": userId ?? "",
            "lookup_id": lookupId ?? "",
            "type": type ?? "",
            "unknown_reason": unknownReason ?? "",
            "started_at": startedAt?.iso8601 ?? "",
            "ended_at": endedAt?.iso8601 ?? "",
            "duration": duration ?? 0,
            "distance": distance ?? 0,
            "place": place?.toDict ?? [:],
            "route": route ?? "",
            "location_time_series": locationTimeSeries ?? "",
            "step_count": stepCount ?? 0,
            "step_distance": stepDistance ?? 0,
            "created_at": createdAt?.iso8601 ?? "",
            "modified_at": modifiedAt?.iso8601 ?? "",
        ]
    }

    var summary: String {
        switch activityType {
        case .stop:
            return ""
        case .walk:
            return "\(HTSpaceTimeUtil.instance.getReadableDistance(distance ?? 0, roundedTo: 1)) | \(HTSpaceTimeUtil.instance.getReadableDate(duration ?? 0))\((stepCount ?? 0) > 0 ? " | \(stepCount ?? 0) steps" : "")"
        default:
            return "\(HTSpaceTimeUtil.instance.getReadableDistance(distance ?? 0, roundedTo: 1)) | \(HTSpaceTimeUtil.instance.getReadableDate(duration ?? 0))"
        }
    }
    
    public enum ActivityType: Int {
        case walk = 0
        case cycle
        case drive
        case stop
        case unknown
        case run
        case none
        
        init(string: String) {
            switch string {
            case "walk":
                self = .walk
            case "cycle":
                self = .cycle
            case "run":
                self = .run
            case "stop":
                self = .stop
            case "drive":
                self = .drive
            default:
                self = .unknown
            }
        }
        
        func getPlacelineImage() -> UIImage? {
            switch self {
            case .cycle:
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.cycle)
            case .walk: fallthrough
            case .run:
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.walk)
            case .drive:
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.drive)
            case .unknown:
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.offline)
            default:
                return nil
            }
        }
        
        public func getMarkerImage() -> UIImage? {
            switch self {
            case .cycle:
                return HTProvider.style.markerImages.cycle
            case .walk: fallthrough
            case .run:
                return HTProvider.style.markerImages.walk
            case .drive:
                return HTProvider.style.markerImages.drive
            case .unknown:
                return HTProvider.style.markerImages.offline
            default:
                return HTProvider.style.markerImages.stop
            }
        }
        
        func getName() -> String {
            switch self {
            case .walk:
                return "WALK"
            case .run:
                return "RUN"
            case .drive:
                return "DRIVE"
            case .stop:
                return "STOP"
            case .cycle:
                return "CYCLE"
            default:
                return "OFFLINE"
            }
        }
        
        func getActivityDisplayName() -> String {
            switch self {
            case .walk:
                return "WALKING"
            case .run:
                return "RUNNING"
            case .drive:
                return "DRIVING"
            case .stop:
                return "STOPPED"
            case .cycle:
                return "RIDING"
            default:
                return "LAST SEEN"
            }
        }
    }
}

public class HTHealth: NSObject {
    public let batteryStatus: String?
    public let locationStatus: String?
    public let batteryPercentage: Int?
    public let networkStatus: String?
    
    public init(dict: HTPayload) {
        batteryPercentage = (dict["battery_percentage"] as? Int)
        locationStatus = (dict["location_status"] as? String)
        batteryStatus = (dict["battery_status"] as? String)
        networkStatus = (dict["network_status"] as? String)
    }
    
    func toDict() -> [String: Any] {
        return [
            "battery_percentage": batteryPercentage ?? 0,
            "location_status": locationStatus ?? "",
            "battery_status": batteryStatus ?? "",
            "network_status": networkStatus ?? "",
        ]
    }
}
