//
//  HTAction.swift
//  SDKTest
//
//  Created by Atul Manwar on 21/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit
import CocoaLumberjack
import CoreLocation

public typealias HTPayload = [String: Any]

@objc public class HTAction: NSObject, HTModelProtocol {
    /********** Defined by you when creating action **********/
    /// Unique identifier for the action object, set by you. It can be based on your internal ID
    public let uniqueId: String
    
    /// Identifier provided by you to club and sequence actions; can be based on your internal ID
    public let collectionId: String
    
    /// Type of action, e.g., pickup, delivery, dropoff, visit, stopover, task
    public let type: String
    public var actionType: ActionType {
        return ActionType(rawValue: type)!
    }
    
    /// User object to which the action is assigned
    public let user: HTUser?
    
    //    /// Custom key-values pairs that may be useful context for your actions, specially in action visuals
    public let metadata: HTPayload
    
    /********** Set by hypertrack when action created **********/
    /// Unique identifier for the action object, created by HyperTrack
    public let id: String
    
    /// URL at which this action can be tracked. This URL can be shared with anyone. It uses the track API (https://docs.hypertrack.com/api/entities/actionv2.html#track-an-action)
    public let trackingUrl: String
    
    /********** Defined by you when completing or canceling action **********/
    /// Custom text to save metadata around completion or cancelation of action.
    /// It can be used to store text like success, failure, rescheduled.
    /// It is derived by hypertrack if you request hypertrack to automatically complete or cancel an action, and
    /// explains what triggerd it
    public let endedAnnotation: String
    
    /********** Defined by you when creating action **********/
    /// Flag that programs hypertrack to complete the action automatically if the user arrives at the expected_place.
    /// This is useful if you don't want to depend on user input to complete the action.
    // Default is false
    public let isAutocompleteAtExpectedPlace: Bool
    
    /// Flag that programs hypertrack to create and complete the action at the same time.
    /// This is useful if you want to just annotate a point in time and location.
    /// Default is false
    public let isAutocompleteAtCreation: Bool
    
    /// Time at which you want hypertrack to automatically cancel the action, if it has not been completed till then.
    /// This is useful for garbage collection in case the action is not completed by the user.
    /// Default is 24 hours from created_at
    public let scheduleAutoCancelAt: Date?
    
    /********** Derived by hypertrack **********/
    /// Current status of the action. See below for possible values
    public let status: String
    var actionStatus: ActionStatus {
        return ActionStatus(rawValue: status)!
    }
    
    /// Time till which the action properties have been updated.
    /// It is the time that hypertrack last heard from the device corresponding to this action.
    /// Once the status changes to started hypertrack strives to keep this time as close to current time,
    /// so that you can track actions in real-time
    public let updatedAt: Date?
    
    /// Time at which the action was created
    public let createdAt: Date?
    
    /// Time at which the action's status changed to started.
    /// If the action was created when there was no other pending action for that user, started_at would be same as created_at
    public let startedAt: Date?
    
    /// Time at which the action was completed or canceled.
    /// If the action status is completed then this is the time you completed the action,
    /// if it is autocompleted then this is the time hypertrack automatically completed the action and
    /// similarly for canceled and autocanceled
    public let endedAt: Date?
    
    /// Place where the action's status changed to started
    public let startedPlace: HTPlace?
    
    /// Place where the action was completed
    public let completedPlace: HTPlace?
    
    /// Distance traveled, in metres, between started_place and completed_place.
    /// For actions that haven't been completed yet, the distance is calculated till the current time
    public let distance: Int
    
    /// Route traveled by user with timestamps, in hypertrack's time aware polyline format.
    /// Use this to replay the route
    public let locationTimeSeries: String?
    
    /********** Expected movement properties **********/
    /********** Defined by you when creating action **********/
    /// Place where the action is expected to be completed.
    /// It is used to calculate eta of an action, and once the action is completed it is used to check
    /// if action was completed at a place different from where it was expected to be
    public let expectedPlace: HTPlace?
    
    /// Time by when the action is expected to be completed.
    /// It is used to calculate if an action is delayed
    public let expectedAt: Date?
    
    /********** Derived by hypertrack **********/
    /// Current sub status of the action.
    /// Possible values are leaving_now, on_the_way, arriving, arrived and moving_away.
    /// It is an empty string if expected_place is not defined by the user.
    /// It is an empty string if the action status is created.
    /// It starts getting updated once the action status changes to started and
    /// keeps getting updated till status changes to completed or autocompleted or canceled or autocanceled
    public let arrivalStatus: String
    var arrivalStatusForAction: ArrivalStatus {
        return ArrivalStatus(rawValue: arrivalStatus)!
    }
    
    /// Current ETA.
    /// It is the time estimated to move from the current location of the user
    /// to the expected_place factoring for traffic
    public let eta: Date?
    
    /// ETA estimated at the time when action was created.
    /// It is the time estimated to move from current location of the user at created_at time to the expected_place.
    /// It is useful in comparing how the the eta changes from the time that the action was created
    public let etaAtCreation: Date?
    
    /// Distance in metres, of encodedPolylineToArrival
    public let distanceToArrival: Int
    
    public let display: Display?
    
    public let location: HTLocation?
    
    public let completedAt: Date?
    
    public let duration: Double?
    
    public let shortestDistance: Double?
    
    public let remainingDistance: Double?
    
    public let expectedRoute: String?
    
    public let route: String?
    
    public let completedAnnotation: HTPayload?
    
    public let health: HTHealth?
    
    public let activity: HTActivity?
    
    public required init(dict: HTPayload) {
        id = dict["id"] as? String ?? ""
        uniqueId = dict["unique_id"] as? String ?? ""
        collectionId = dict["collection_id"] as? String ?? ""
        if let payload = dict["user"] as? HTPayload {
            user = HTUser(dict: payload)
        } else {
            user = nil
        }
        metadata = dict["metadata"] as? HTPayload ?? [:]
        type = dict["type"] as? String ?? ""
        createdAt = (dict["created_at"] as? String)?.dateFromISO8601
        if let payload = dict["started_place"] as? HTPayload {
            startedPlace = HTPlace(dict: payload)
        } else {
            startedPlace = nil
        }
        startedAt = (dict["started_at"] as? String)?.dateFromISO8601
        if let payload = dict["expected_place"] as? HTPayload {
            expectedPlace = HTPlace(dict: payload)
        } else {
            expectedPlace = nil
        }
        expectedAt = (dict["expected_at"] as? String)?.dateFromISO8601
        if let payload = dict["completed_place"] as? HTPayload {
            completedPlace = HTPlace(dict: payload)
        } else {
            completedPlace = nil
        }
        if let payload = dict["location"] as? HTPayload {
            location = HTLocation(dict: payload)
        } else {
            location = nil
        }
        endedAt = (dict["ended_at"] as? String)?.dateFromISO8601
        scheduleAutoCancelAt = (dict["schedule_autocancel_at"] as? String)?.dateFromISO8601
        status = dict["status"] as? String ?? ""
        arrivalStatus = dict["arrival_status"] as? String ?? ""
        eta = (dict["eta"] as? String)?.dateFromISO8601
        etaAtCreation = (dict["eta_at_creation"] as? String)?.dateFromISO8601
        distanceToArrival = dict["distance_to_arrival"] as? Int ?? 0
        trackingUrl = dict["tracking_url"] as? String ?? ""
        distance = dict["distance"] as? Int ?? 0
        locationTimeSeries = dict["location_time_series"] as? String
        isAutocompleteAtExpectedPlace = dict["is_autocomplete_at_expected_place"] as? Bool ?? false
        isAutocompleteAtCreation = dict["is_autocomplete_at_creation"] as? Bool ?? false
        endedAnnotation = dict["ended_annotation"] as? String ?? ""
        updatedAt = (dict["updated_at"] as? String)?.dateFromISO8601
        completedAt = (dict["completed_at"] as? String)?.dateFromISO8601
        if let payload = dict["display"] as? HTPayload {
            display = Display(dict: payload)
        } else {
            display = nil
        }
        duration = (dict["duration"] as? Double)
        shortestDistance = (dict["shortest_distance"] as? Double)
        remainingDistance = (dict["remaining_distance"] as? Double)
        expectedRoute = (dict["expected_route"] as? String)
        route = (dict["route"] as? String)
        completedAnnotation = (dict["completed_annotation"] as? HTPayload)
        if let payload = dict["health"] as? HTPayload {
            health = HTHealth(dict: payload)
        } else {
            health = nil
        }
        if let payload = dict["activity"] as? HTPayload {
            activity = HTActivity(dict: payload)
        } else {
            activity = nil
        }
    }
    
    internal func toDict() -> [String: Any] {
        return [
            "id": id,
            "unique_id": uniqueId,
            "collection_id": collectionId,
            "user": user?.toDict() ?? [:],
            "metadata": metadata,
            "type": type,
            "created_at": createdAt?.iso8601 ?? "",
            "started_place": startedPlace?.toDict() ?? [:],
            "started_at": startedAt?.iso8601 ?? "",
            "expected_place": expectedPlace?.toDict() ?? [:],
            "expected_at": expectedAt?.iso8601 ?? "",
            "completed_place": completedPlace?.toDict() ?? [:],
            "location": location?.toDict() ?? [:],
            "ended_at": endedAt?.iso8601 ?? "",
            "schedule_autocancel_at": scheduleAutoCancelAt?.iso8601 ?? "",
            "status": status,
            "arrival_status": arrivalStatus,
            "eta": eta?.iso8601 ?? "",
            "eta_at_creation": etaAtCreation?.iso8601 ?? "",
            "distance_to_arrival": distanceToArrival,
            "tracking_url": trackingUrl,
            "distance": distance,
            "location_time_series": locationTimeSeries ?? "",
            "is_autocomplete_at_expected_place": isAutocompleteAtExpectedPlace,
            "is_autocomplete_at_creation": isAutocompleteAtCreation,
            "ended_annotation": endedAnnotation,
            "updated_at": updatedAt?.iso8601 ?? "",
            "completed_at": completedAt?.iso8601 ?? "",
            "display": display?.toDict() ?? [:],
            "duration": duration ?? 0,
            "shortest_distance": shortestDistance ?? 0,
            "remaining_distance": remainingDistance ?? 0,
            "expected_route": expectedRoute ?? "",
            "route": route ?? "",
            "completed_annotation": completedAnnotation ?? [:],
            "health": health?.toDict() ?? [:],
            "activity": activity?.toDict() ?? [:],
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
    
    public enum ActionType {
        case pickup
        case delivery
        case dropoff
        case visit
        case stopover
        case task
        case other(String)
        
        init?(rawValue: String) {
            switch rawValue {
            case "pickup":
                self = .pickup
            case "delivery":
                self = .delivery
            case "dropoff":
                self = .dropoff
            case "visit":
                self = .visit
            case "stopover":
                self = .stopover
            case "task":
                self = .task
            default:
                self = .other(rawValue)
            }
        }
    }
    
    public enum ActionStatus {
        case created
        case started
        case completed
        case autocompleted
        case canceled
        case autocanceled
        case other(String)
        
        init?(rawValue: String) {
            switch rawValue {
            case "created":
                self = .created
            case "started":
                self = .started
            case "completed":
                self = .completed
            case "autocompleted":
                self = .autocompleted
            case "canceled":
                self = .canceled
            case "autocanceled":
                self = .autocanceled
            default:
                self = .other(rawValue)
            }
        }
        
        public var isCompleted: Bool {
            switch self {
            case .started:
                fallthrough
            case .created:
                fallthrough
            case .other(_):
                return false
            default:
                return true
            }
        }
    }
    
    public enum ArrivalStatus {
        case leavingNow
        case onTheWay
        case arriving
        case arrived
        case movingAway
        case other(String)
        
        init?(rawValue: String) {
            switch rawValue {
            case "leaving_now":
                self = .leavingNow
            case "on_the_way":
                self = .onTheWay
            case "arriving":
                self = .arriving
            case "arrived":
                self = .arrived
            case "moving_away":
                self = .movingAway
            default:
                self = .other(rawValue)
            }
        }
    }
    
    public class Display: NSObject {
        public let durationElapsed: Double
        
        /// The unit in which the distance values should be displayed.
        /// Possible values are mi (if the user is moving in USA) and km (elsewhere in the world)
        public let distanceUnit: String
        
        public var distanceUnitType: DistanceUnit {
            return DistanceUnit(unit: distanceUnit)
        }
        
        /// The status that should be shown on a tracking experience.
        /// Its a well formatted string derived using the status property of action, arrival_status of action,
        /// is_tracking property of user, current activity type of user, location_status of user and network_status of user
        public let statusText: String
        
        /// This is set to true if the eta if greater than the expected_at.
        /// In all other cases including when no expected_at is defined for the action, it is false
        public let isDelayed: Bool
        
        /// URL of the logo of your account.
        /// If specified, the logo is displayed on the live tracking experience.
        /// You can upload your logo in dashboard settings- TODO
        public let accountLogo: String?
        
        public enum DistanceUnit: Int {
            case km = 0
            case mi
            
            init(unit: String) {
                switch unit {
                case "km":
                    self = .km
                default:
                    self = .mi
                }
            }
        }
        
        init(dict: HTPayload) {
            durationElapsed = (dict["duration_elapsed"] as? Double) ?? 0
            distanceUnit = (dict["distance_unit"] as? String) ?? ""
            statusText = (dict["status_text"] as? String) ?? ""
            isDelayed = (dict["is_delayed"] as? Bool) ?? false
            accountLogo = (dict["account_logo"] as? String)
        }
        
        func toDict() -> [String: Any] {
            return [
                "duration_elapsed": durationElapsed,
                "distance_unit": distanceUnit,
                "status_text": statusText,
                "is_delayed": isDelayed,
                "account_logo": accountLogo ?? ""
            ]
        }
    }
    
}

public class HTTrackResponse: NSObject, HTModelProtocol {
    public let count: Int
    public let next: String
    public let previous: String
    public let actions: [HTTrackAction]
    
    public required init(dict: HTPayload) {
        count = (dict["count"] as? Int) ?? 0
        next = (dict["next"] as? String) ?? ""
        previous = (dict["previous"] as? String) ?? ""
        guard let actionsDictArray = dict["results"] as? [Any] else {
            actions = []
            return
        }
        actions = actionsDictArray.flatMap({ $0 as? HTPayload }).map({ HTTrackAction(dict: $0) })
    }
    
    convenience init?(data: Data?) {
        guard let dict = data?.toDict() else {
            return nil
        }
        self.init(dict: dict)
    }
}

public class HTAnnotationDataAdapter {
    static func getAnnotationData(_ id: String, place: HTPlace, metaData: HTAnnotationData.MetaData, callout: HTCallout? = nil, isCurrentUser: Bool = false, locationTimeSeries: HTTimeAwarePolyline?) -> HTAnnotationData? {
        guard let lat = place.location?.coordinates.last, let lng = place.location?.coordinates.first else { return nil }
        return HTAnnotationData(id: id, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), metaData: metaData, callout: callout, isCurrentUser: isCurrentUser, locationTimeSeries: locationTimeSeries)
    }
    
    static func getAnnotationData(_ id: String, coordinate: CLLocationCoordinate2D, metaData: HTAnnotationData.MetaData, callout: HTCallout? = nil, isCurrentUser: Bool = false, locationTimeSeries: HTTimeAwarePolyline?) -> HTAnnotationData {
        return HTAnnotationData(id: id, coordinate: coordinate, metaData: metaData, callout: callout, isCurrentUser: isCurrentUser, locationTimeSeries: locationTimeSeries)
    }
    
    static func getAnnotationData(_ id: String, location: HTLocation, metaData: HTAnnotationData.MetaData, callout: HTCallout? = nil, isCurrentUser: Bool = false, locationTimeSeries: HTTimeAwarePolyline?) -> HTAnnotationData? {
        guard let lat = location.location.coordinates.last, let lng = location.location.coordinates.first else { return nil }
        return HTAnnotationData(id: id, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng), metaData: metaData, callout: callout, isCurrentUser: isCurrentUser, locationTimeSeries: locationTimeSeries)
    }
    
    static func mapActionsToUserAnnotations(_ actions: [HTTrackAction], currentUserId: String? = nil) -> [HTAnnotationData] {
        return actions.flatMap { (action) -> HTAnnotationData? in
            let isCurrentUser = (currentUserId != nil && action.user?.id != "" && currentUserId == action.user?.id)
            return mapActionToUserAnnotation(action, isCurrentUser: isCurrentUser)
        }
    }
    
    static func mapActionToUserAnnotation(_ action: HTTrackAction, isCurrentUser: Bool) -> HTAnnotationData? {
        if let coordinate = action.location?.geojson?.coordinates {
            if let lat = coordinate.last, let lng = coordinate.first {
                return mapActionToUserAnnotation(action, coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lng), isCurrentUser: isCurrentUser)
            }
        }
//        if let locationTimeSeries = HTPolylineAdapter.getSingleTimeAwarePolylineData(action.user?.id, locationTimeSeries: action.locationTimeSeries, isCurrentUser: isCurrentUser), let coordinates = locationTimeSeries.coordinates.last?.location  {
//            let annotationType: HTAnnotationType = (action.activity?.activityType == HTActivity.ActivityType.unknown || action.user?.display?.isWarning == true) ? .error : (isCurrentUser ? .currentUser : .user)
//            let metaData = HTAnnotationData.MetaData(isPulsating: isCurrentUser, type: annotationType, activityType: action.activity?.activityType ?? .none, actionInfo: HTActionInfo(actionStatus: action.status))
//            let callout = HTCallout(action, metaData: HTCallout.MetaData(axis: .vertical, type: annotationType, moreInfoAvailable: true))
//            return HTAnnotationData(id: action.user?.id ?? "", coordinate: coordinates, metaData: metaData, callout: callout, isCurrentUser: isCurrentUser, locationTimeSeries: locationTimeSeries)
//        }
        return nil
    }
    
    static func mapActionToUserAnnotation(_ action: HTTrackAction, coordinates: CLLocationCoordinate2D, isCurrentUser: Bool) -> HTAnnotationData {
        let annotationType: HTAnnotationType = (action.activity?.activityType == HTActivity.ActivityType.unknown || action.user?.display?.isWarning == true) ? .error : (isCurrentUser ? .currentUser : .user)
        return HTAnnotationDataAdapter.getAnnotationData(action.user?.id ?? "", coordinate: coordinates, metaData: HTAnnotationData.MetaData(isPulsating: isCurrentUser, type: annotationType, activityType: action.activity?.activityType ?? .none, actionInfo: HTActionInfo(actionStatus: action.status)), callout: HTCallout(action, metaData: HTCallout.MetaData(axis: .vertical, type: annotationType, moreInfoAvailable: true)), isCurrentUser: isCurrentUser, locationTimeSeries: HTPolylineAdapter.getSingleTimeAwarePolylineData(action.user?.id, locationTimeSeries: action.locationTimeSeries, isCurrentUser: isCurrentUser))
    }

    
    static func getExpectedPlaceAnnotations(_ action: [HTTrackAction]) -> [HTAnnotationData] {
        return action.flatMap({ getExpectedPlaceAnnotation($0) })
    }
    
    static func getExpectedPlaceAnnotation(_ action: HTTrackAction) -> HTAnnotationData? {
        let place: HTPlace? = (action.actionStatus.isCompleted ? action.completedPlace : action.expectedPlace) ?? action.expectedPlace
        if let expectedPlace = place {
            let displayName = expectedPlace.getPlaceDisplayName() ?? "No address"
            var description = displayName
            var moreDetails = ""
            var title = ""
            if let eta = action.eta {
                description = HTSpaceTimeUtil.instance.difference(date: eta)
                moreDetails = displayName
                title = "ETA"
            }
            let callout = HTCallout(metaData: HTCallout.MetaData(axis: .vertical, type: .destination, moreInfoAvailable: true), components: [HTCallout.Data.InfoText(title: title , description: description, moreDetails: moreDetails)])
            return HTAnnotationDataAdapter.getAnnotationData((action.expectedPlace?.id != nil && action.expectedPlace?.id != "") ? (action.expectedPlace?.id ?? "") : (!action.id.isEmpty ? action.id : "\(expectedPlace.location?.coordinates.description ?? "")"), place: expectedPlace, metaData: HTAnnotationData.MetaData(isPulsating: false, type: .destination, activityType: .none, actionInfo: HTActionInfo(actionStatus: action.status)), callout: callout, isCurrentUser: false, locationTimeSeries: nil)
        } else {
            return nil
        }
    }
    
    static func getStatusInfo(_ action: HTAction) -> (title: String, type: HTActivity.ActivityType) {
        if action.user?.display?.isWarning == true {
            return (title: "Offline \(action.user?.display?.warningSinceText ?? "")", type: .unknown)
        } else {
            let etaDisplayString = action.actionStatus.isCompleted ? "Completed" : ((action.eta != nil) ?  "\(HTSpaceTimeUtil.instance.difference(date: action.eta!)) away" : "")
            var titleArray: [String] = []
            titleArray.append(etaDisplayString)
            let addressText = action.activity?.place?.getPlaceDisplayName() ?? ""
            if !addressText.isEmpty {
                titleArray.append("On \(addressText)")
            } else {
                titleArray.append(action.user?.display?.statusText ?? "")
            }
            let title = titleArray.filter({ !$0.isEmpty }).joined(separator: " | ")
            return (title: (title.isEmpty ? "NA" : title), type: action.activity?.activityType ?? .none)
        }
    }
}

public class HTMapDataAdapter {
    static func getMapData(_ actions: [HTTrackAction]) -> HTMapData {
        var polylines: [HTPolylineData] = []
        var annotations: [HTAnnotationData] = []
        actions.forEach { (action) in
            let isCurrentUser = HTUserService.sharedInstance.isCurrentUser(userId: action.user?.id)
            if let polyline = HTPolylineAdapter.getPolylineFromDecodedString(action.route, type: .filled, action: action, shouldAddCurrentLocation: isCurrentUser) {
                polylines.append(polyline)
            }
            if let polyline = HTPolylineAdapter.getPolylineFromDecodedString(action.expectedRoute, type: .dotted, action: action, shouldAddCurrentLocation: false) {
                polylines.append(polyline)
            }
            if let annotation = HTAnnotationDataAdapter.mapActionToUserAnnotation(action, isCurrentUser: isCurrentUser) {
                annotations.append(annotation)
            }
        }
        if let first = actions.first, let expectedPlaceAnnotation = HTAnnotationDataAdapter.getExpectedPlaceAnnotation(first) {
            annotations.append(expectedPlaceAnnotation)
        }
        return HTMapData(annotations: annotations, polylines: polylines)
    }
}

public class HTPolylineAdapter {
    static func getPolylineFromDecodedString(_ encoded: String?, type: HTPolylineType, action: HTAction, shouldAddCurrentLocation: Bool) -> HTPolylineData? {
        if let route = encoded {
            if let decoded = PolylineUtils.decodePolyline(route) {
                return HTPolylineData(id: action.id, type: type, coordinates: decoded, encodedRoute: route)
//                    if shouldAddCurrentLocation, let currentLocation = HyperTrack.getCurrentLocation() {
//                        return polyline.addCoordinate(currentLocation.coordinate)
//                    } else {
//                        return polyline
//                    }
            }
        }
        return nil
    }

    static func getPolylineData(_ actions: [HTTrackAction]) -> [HTPolylineData] {
        var polylines: [HTPolylineData] = []
        actions.forEach { (action) in
            if !action.actionStatus.isCompleted {
                if let polyline = HTPolylineAdapter.getPolylineFromDecodedString(action.route, type: .filled, action: action, shouldAddCurrentLocation: false) {
                    polylines.append(polyline)
                }
                if let polyline = HTPolylineAdapter.getPolylineFromDecodedString(action.expectedRoute, type: .dotted, action: action, shouldAddCurrentLocation: false) {
                    polylines.append(polyline)
                }
            }
        }
        return polylines
    }
    
    static fileprivate func getSingleTimeAwarePolylineData(_ id: String?, locationTimeSeries: String?, isCurrentUser: Bool) -> HTTimeAwarePolyline? {
        guard let value = locationTimeSeries, let id = id else { return nil }
        let polyline = HTTimeAwarePolyline(id: id, type: .filled, polylineString: value)
        if isCurrentUser, let currentLocation = HyperTrack.getCurrentLocation() {
            return polyline.addCoordinate(TimedCoordinates(location: currentLocation.coordinate, timeStamp: currentLocation.timestamp, bearing: currentLocation.course))
        } else {
            return polyline
        }
    }
}

@objc public class HTTrackAction: HTAction {
    public let place: HTPlace?
    
    public required init(dict: HTPayload) {
        if let payload = dict["place"] as? HTPayload {
            place = HTPlace(dict: payload)
        } else {
            place = nil
        }
        super.init(dict: dict)
    }
}
