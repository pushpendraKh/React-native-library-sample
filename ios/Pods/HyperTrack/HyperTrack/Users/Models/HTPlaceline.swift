//
//  HTPlaceline.swift
//  HyperTrack
//
//  Created by Atul Manwar on 16/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

@objc public class HTPlaceline: NSObject, HTModelProtocol {
    public let id: String?
    public let groupId: String?
    public let uniqueId: String?
    public let name: String?
    public let phone: String?
    public let photo: String?
    public let availabilityStatus: String?
    public let vehicleType: String?
    public let isConnected: Bool?
    public let isTracking: Bool?
    public let location: HTGeoJSONLocation?
    public let display: Display?
    public let createdAt: Date?
    public let placeline: [HTActivity]
    public let activity: HTActivity?
    public let health: HTHealth?
    public let placelineDate: String?
    public let activitySummary: ActivitySummary?
    public let actions: [HTAction]
    
    public required init(dict: HTPayload) {
        id = (dict["id"] as? String)
        groupId = (dict["group_id"] as? String)
        uniqueId = (dict["unique_id"] as? String)
        name = (dict["name"] as? String)
        phone = (dict["phone"] as? String)
        photo = (dict["photo"] as? String)
        availabilityStatus = (dict["availability_status"] as? String)
        vehicleType = (dict["vehicle_type"] as? String)
        isConnected = (dict["is_connected"] as? Bool)
        isTracking = (dict["is_tracking"] as? Bool)
        createdAt = (dict["created_at"] as? String)?.dateFromISO8601
        placelineDate = (dict["placeline_date"] as? String)
        if let payload = (dict["location"] as? HTPayload) {
            location = HTGeoJSONLocation(dict: payload)
        } else {
            location = nil
        }
        if let array = (dict["placeline"] as? [Any]) {
            placeline = array.flatMap({ $0 as? HTPayload }).map({ HTActivity(dict: $0) })
        } else {
            placeline = []
        }
        if let payload = (dict["activity"] as? HTPayload) {
            activity = HTActivity(dict: payload)
        } else {
            activity = nil
        }
        if let payload = (dict["health"] as? HTPayload) {
            health = HTHealth(dict: payload)
        } else {
            health = nil
        }
        if let payload = (dict["activity_summary"] as? HTPayload) {
            activitySummary = ActivitySummary(dict: payload)
        } else {
            activitySummary = nil
        }
        if let array = (dict["actions"] as? [Any]) {
            actions = array.flatMap({ $0 as? HTPayload }).map({ HTAction(dict: $0) })
        } else {
            actions = []
        }
        if let payload = (dict["display"] as? HTPayload) {
            display = Display(dict: payload)
        } else {
            display = nil
        }
    }
    
    internal func toDict() -> [String: Any] {
        return [
            "id": id ?? "",
            "group_id": groupId ?? "",
            "unique_id": uniqueId ?? "",
            "name": name ?? "",
            "phone": phone ?? "",
            "photo": photo ?? "",
            "availability_status": availabilityStatus ?? "",
            "vehicle_type": vehicleType ?? "",
            "is_connected": isConnected ?? false,
            "is_tracking": isTracking ?? false,
            "created_at": createdAt?.iso8601 ?? "",
            "placeline_date": placelineDate ?? "",
            "location": location?.toDict() ?? [:],
            "activity": activity?.toDict() ?? [:],
            "health": health?.toDict() ?? [:],
            "activity_summary": activitySummary?.toDict() ?? [:],
            "display": display?.toDict() ?? [:],
        ]
    }
    
    public func toJson() -> String? {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString
        } catch let error {
            DDLogError("Error serializing object to JSON: " + error.localizedDescription)
            return nil
        }
    }
    
    public func toJsonData() -> Data? {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            return jsonData
        } catch let error {
            DDLogError("Error serializing object to JSON: " + error.localizedDescription)
            return nil
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
        
        internal func toDict() -> [String: Any] {
            return [
                "last_updated_text": lastUpdatedText ?? "",
                "warning_since_text": warningSinceText ?? "",
                "battery": battery ?? 0,
                "status_text": statusText ?? "",
                "is_warning": isWarning,
            ]
        }
    }

    public class ActivitySummary {
        public let distanceByActivity: ActivityInfo?
        public let stepsByActivity: ActivityInfo?
        public let durationByActivity: ActivityInfo?
        var viewModel: [SummaryViewModel]?
        
        init(dict: HTPayload) {
            if let payload = dict["distance_by_activity"] as? HTPayload {
                distanceByActivity = ActivityInfo(dict: payload)
            } else {
                distanceByActivity = nil
            }
            if let payload = dict["steps_by_activity"] as? HTPayload {
                stepsByActivity = ActivityInfo(dict: payload)
            } else {
                stepsByActivity = nil
            }
            if let payload = dict["duration_by_activity"] as? HTPayload {
                durationByActivity = ActivityInfo(dict: payload)
            } else {
                durationByActivity = nil
            }
            var viewModel: [SummaryViewModel] = []
            viewModel.append(SummaryViewModel(image: getImageByActivity("walk"), type: "walk", description: "\(Int(stepsByActivity?.total ?? 0)) steps"))
            viewModel.append(SummaryViewModel(image: getImageByActivity("drive"), type: "drive", description: HTSpaceTimeUtil.instance.getReadableDistance(distanceByActivity?.drive ?? 0, roundedTo: 1)))
//            viewModel.append(SummaryViewModel(image: getImageByActivity("cycle"), type: "cycle", description: HTSpaceTimeUtil.instance.getReadableDistance(distanceByActivity?.cycle ?? 0, roundedTo: 1)))
            self.viewModel = viewModel
        }
        
        internal func toDict() -> [String: Any] {
            return [
                "distance_by_activity": distanceByActivity?.toDict() ?? [:],
                "steps_by_activity": stepsByActivity?.toDict() ?? [:],
                "duration_by_activity": durationByActivity?.toDict() ?? [:],
            ]
        }
        
        fileprivate func getImageByActivity(_ activityType: String) -> UIImage? {
            switch activityType {
            case "drive":
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.summaryDrive)
            case "cycle":
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.summaryCycle)
            case "walk":
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.summaryWalk)
            case "run":
                return UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.Placeline.summaryWalk)
            default:
                return nil
            }
        }
        
        public class ActivityInfo {
            public let total: Double
            public let stop: Double
            public let walk: Double
            public let drive: Double
            public let run: Double
            public let cycle: Double
            
            init(dict: HTPayload) {
                self.total = (dict["total"] as? Double) ?? 0
                self.stop = (dict["stop"] as? Double) ?? 0
                self.walk = (dict["walk"] as? Double) ?? 0
                self.drive = (dict["drive"] as? Double) ?? 0
                self.run = (dict["run"] as? Double) ?? 0
                self.cycle = (dict["cycle"] as? Double) ?? 0
            }
            
            internal func toDict() -> [String: Any] {
                return [
                    "total": total,
                    "stop": stop,
                    "walk": walk,
                    "drive": drive,
                    "run": run,
                    "cycle": cycle,
                ]
            }
        }
        
        class SummaryViewModel {
            public let image: UIImage?
            public let descriptionString: String
            public let type: String
            
            init(image: UIImage?, type: String, description: String) {
                self.image = image
                self.descriptionString = description
                self.type = type
            }
        }
    }
    
    class DisplayData {
        let values: [Any]
        
        init(activities: [HTActivity]) {
            var values: [Any] = []
            var lastActivity: HTActivity?
            activities.enumerated().forEach { (index, activity) in
                //last activity
                if activities.count == 1 && activity.activityType != .stop {
                    return
                }
                if index == activities.count - 1 && activity.activityType != .stop {
                    if let _ = values.last as? ActivityInfo, let lastActivity = lastActivity {
                        values.append(Header(activity: lastActivity))
                    }
                    values.append(ActivityInfo(activity: activity))
                    values.append(Header(activity: activity))
                } else if activity.activityType == .stop {
                    if lastActivity?.activityType == .stop, let last = values.removeLast() as? Header {
                        if let smallerDate = HTSpaceTimeUtil.instance.compareAndGetDate(lastActivity?.startedAt, second: activity.startedAt, smaller: true) {
                            last.startTime = smallerDate.toString(dateFormat: Locale.timeFormat)
                        } else if let largerDate = HTSpaceTimeUtil.instance.compareAndGetDate(lastActivity?.endedAt, second: activity.endedAt, smaller: false) {
                            last.endTime = largerDate.toString(dateFormat: Locale.timeFormat)
                        }
                        values.append(last)
                    } else {
                        values.append(Header(activity: activity))
                    }
                } else if lastActivity?.activityType == .stop {
                    values.append(ActivityInfo(activity: activity))
                } else {
                    values.append(Header(activity: activity))
                    values.append(ActivityInfo(activity: activity))
                }
                lastActivity = activity
            }
            self.values = values
        }
        
        enum DisplayDataType: Int {
            case header = 0
            case activity
        }
        
        class ActivityInfo {
            let id: String
            let type: DisplayDataType
            let descriptionText: String
            let activityType: HTActivity.ActivityType
            let moreInfoAvailable: Bool
            
            init(activity: HTActivity) {
                self.id = activity.id
                self.type = .activity
                self.descriptionText = (activity.activityType != .stop) ? activity.summary : ""
                self.activityType = activity.activityType
                self.moreInfoAvailable = (activity.route != nil && activity.route != "")
            }
            
            init(id: String, descriptionText: String, activityType: HTActivity.ActivityType, moreInfoAvailable: Bool) {
                self.id = id
                self.type = .activity
                self.descriptionText = descriptionText
                self.activityType = activityType
                self.moreInfoAvailable = moreInfoAvailable
            }
        }
        
        class Header {
            let type: DisplayDataType
            var startTime: String
            var endTime: String
            let title: String
            
            init(activity: HTActivity) {
                self.type = .activity
                self.startTime = ((activity.activityType == .stop) ? activity.startedAt?.toString(dateFormat: Locale.timeFormat) ?? "" : "")
                self.endTime = activity.endedAt?.toString(dateFormat: Locale.timeFormat) ?? ""
                self.title = activity.place?.getPlaceDisplayName() ?? "No address available"
            }
            
            init(startTime: String, endTime: String, title: String) {
                self.type = .header
                self.startTime = startTime
                self.endTime = endTime
                self.title = title
            }
        }
    }
}


