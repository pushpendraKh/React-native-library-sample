//
//  HTCallout.swift
//  SDKTest
//
//  Created by Atul Manwar on 13/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit
import CoreLocation

@objc public class HTMapData: NSObject {
    let annotations: [HTAnnotationData]
    let polylines: [HTPolylineData]
//    let trailingPolyline: [HTTimeAwarePolyline]
    
    public init(annotations: [HTAnnotationData], polylines: [HTPolylineData]) {//, trailingPolyline: [HTTimeAwarePolyline]
        self.annotations = annotations
        self.polylines = polylines
//        self.trailingPolyline = trailingPolyline
        super.init()
    }
}

//@objc public class HTTimedCoordinate: NSObject {
//    var coordinate: CLLocationCoordinate2D
//    let timeStamp: Date
//
//    public init(coordinate: CLLocationCoordinate2D, timeStamp: Date) {
//        self.coordinate = coordinate
//        self.timeStamp = timeStamp
//        super.init()
//    }
//}

public enum HTPolylineType: Int {
    case dotted
    case filled
}

@objc public class HTTimeAwarePolyline: NSObject {
    let id: String
    let type: HTPolylineType
    let coordinates: [TimedCoordinates]
    
    init(id: String, type: HTPolylineType, coordinates: [TimedCoordinates]) {
        self.id = id
        self.type = type
        self.coordinates = coordinates
        super.init()
    }
    
    fileprivate func calculateBearing(_ coordinates: [TimedCoordinates]) -> [Double] {
        var directions: [Double] = []
        var last = CLLocationCoordinate2D.zero
        coordinates.forEach({
            directions.append( HTMapUtils.headingFrom(last, next: $0.location) )
            last = $0.location
        })
        return directions
    }
    
    init(id: String, type: HTPolylineType, polylineString: String) {
        self.id = id
        self.type = type
        self.coordinates = timedCoordinatesFrom(polyline: polylineString) ?? []
        super.init()
    }
    
    public func slice(_ maxSize: Int, date: Date) -> HTTimeAwarePolyline {
        return HTTimeAwarePolyline(id: id, type: type, coordinates: Array(coordinates.filter({ $0.timeStamp > date }).suffix(maxSize)))
    }
    
    func addCoordinate(_ coordinate: TimedCoordinates) -> HTTimeAwarePolyline {
        var coordinates = self.coordinates
        coordinates.append(coordinate)
        return HTTimeAwarePolyline(id: id, type: type, coordinates: coordinates)
    }
    
    public func toPolyline() -> HTPolylineData {
        return HTPolylineData(id: id, type: .filled, coordinates: coordinates.map({ $0.location }))
    }
}

@objc public class HTPolylineData: NSObject {
    public let id: String
    public let type: HTPolylineType
    public let coordinates: [CLLocationCoordinate2D]
    public let encodedRoute: String?
    
    public init(id: String, type: HTPolylineType, coordinates: [CLLocationCoordinate2D], encodedRoute: String? = nil) {
        self.id = id
        self.type = type
        self.coordinates = coordinates
        self.encodedRoute = encodedRoute
    }

    public func addCoordinate(_ coordinate: CLLocationCoordinate2D) -> HTPolylineData {
        var coordinates = self.coordinates
        coordinates.append(coordinate)
        return HTPolylineData(id: id, type: type, coordinates: coordinates)
    }
}

@objc public class HTAnnotationData: NSObject {
    public let id: String
    public let coordinate: CLLocationCoordinate2D
    public let metaData: MetaData
    public let callout: HTCallout?
    public let locationTimeSeries: HTTimeAwarePolyline?
    public let isCurrentUser: Bool
    
    public init(id: String, coordinate: CLLocationCoordinate2D, metaData: MetaData, callout: HTCallout?, isCurrentUser: Bool = false, locationTimeSeries: HTTimeAwarePolyline? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.metaData = metaData
        self.callout = callout
        self.isCurrentUser = isCurrentUser
        self.locationTimeSeries = locationTimeSeries
    }
    
    public class MetaData: NSObject {
        public let isPulsating: Bool
        public let type: HTAnnotationType
        public let activityType: HTActivity.ActivityType
        public let actionInfo: HTActionInfo?
        
        public init(isPulsating: Bool, type: HTAnnotationType, activityType: HTActivity.ActivityType? = nil, actionInfo: HTActionInfo?) {
            self.isPulsating = isPulsating
            self.type = type
            self.activityType = activityType ?? .none
            self.actionInfo = actionInfo
        }
    }
}

@objc public class HTActionInfo: NSObject {
    public let actionStatus: String
    
    public init(actionStatus: String) {
        self.actionStatus = actionStatus
        super.init()
    }
}

@objc public enum HTAnnotationType: Int {
    case user
    case currentUser
    case destination
    case error
    case none
}

public class HTCallout: NSObject {
    public let metaData: MetaData
    public let components: [HTBasicComponentProtocol]
    
    public init?(_ action: HTTrackAction, metaData: MetaData) {
        var components: [HTBasicComponentProtocol] = []
        let addressText = action.place?.getPlaceDisplayName() ?? action.activity?.place?.getPlaceDisplayName() ?? ""
        if action.user?.display?.isWarning == true {
            components.append(HTCallout.Data.CaptionText(title: "Offline \(action.user?.display?.warningSinceText ?? "")"))
            let errorDisplayText = !addressText.isEmpty ? addressText : (action.user?.display?.warningSinceText ?? "")
            if !errorDisplayText.isEmpty {
                components.append(HTCallout.Data.InfoText(title: "LAST SEEN", description: errorDisplayText, moreDetails: ""))
            }
            if let battery = action.health?.batteryPercentage, battery < 10 {
                components.append(HTCallout.Data.InfoText(title: "POSSIBLE REASON", description: "Low battery", moreDetails: ""))
                components.append(HTCallout.Data.IconText(title: "\(battery)%", image: UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.battery)))
            } else {
                components.append(HTCallout.Data.InfoText(title: "POSSIBLE REASON", description: "Device off", moreDetails: ""))
            }
        } else {
            components.append(HTCallout.Data.InfoText(title: action.user?.display?.statusText ?? action.activity?.activityType.getActivityDisplayName() ?? "", description: addressText, moreDetails: ""))
            var infoArray: [HTBasicComponentProtocol] = []
            if let speed = action.location?.speed, speed > 0 {
                infoArray.append(HTCallout.Data.InfoText(title: "SPEED", description: "\(speed)", moreDetails: ""))
            } else {
                let duration = ((action.activity?.duration ?? 0.0) > 0.0) ? HTSpaceTimeUtil.instance.getReadableDate(action.activity?.duration ?? 0.0) : "-"
                infoArray.append(HTCallout.Data.InfoText(title: "FOR", description: duration, moreDetails: ""))
            }
            if let battery = action.health?.batteryPercentage {
                infoArray.append(HTCallout.Data.IconText(title: "\(battery)%", image: UIImage.getImageFromHTBundle(named:
                    HTConstants.ImageNames.battery), axis: .vertical))
            }
            if infoArray.count > 0 {
                components.append(HTCallout.Data.InfoArray(values: infoArray))
            }
        }
        self.metaData = metaData
        self.components = components
    }
    
    public init(metaData: MetaData, components: [HTBasicComponentProtocol]) {
        self.metaData = metaData
        self.components = components
    }
    
    public class MetaData {
        let axis: UILayoutConstraintAxis
        let type: HTAnnotationType
        let moreInfoAvailable: Bool
        static var `default`: MetaData {
            return MetaData(axis: .vertical, type: .currentUser, moreInfoAvailable: false)
        }
        
        init(axis: UILayoutConstraintAxis, type: HTAnnotationType, moreInfoAvailable: Bool) {
            self.axis = axis
            self.type = type
            self.moreInfoAvailable = moreInfoAvailable
        }
    }
    public class Data {
        public class InfoText: HTBasicComponentProtocol {
            let title: String
            let description: String
            let moreDetails: String
            
            var identifier: String {
                return "htInfoext"
            }
            
            init(title: String, description: String, moreDetails: String) {
                self.title = description.isEmpty ? "" : title
                self.description = description.isEmpty ? title : description
                self.moreDetails = moreDetails
            }
        }
        public class CaptionText: HTBasicComponentProtocol {
            let title: String

            var identifier: String {
                return "htCaptionText"
            }
            
            init(title: String) {
                self.title = title
            }
        }
        public class IconText: HTBasicComponentProtocol {
            let image: UIImage?
            let title: String
            let axis: UILayoutConstraintAxis
            
            var identifier: String {
                return "htIconText\(axis)"
            }
            
            init(title: String, image: UIImage?, axis: UILayoutConstraintAxis = .horizontal) {
                self.title = title
                self.image = image
                self.axis = axis
            }
        }
        public class InfoArray: HTBasicComponentProtocol {
            let values: [HTBasicComponentProtocol]
            
            init(values: [HTBasicComponentProtocol]) {
                self.values = values
            }
        }
    }
}

