//
//  HTActionParams.swift
//  HyperTrack
//
//  Created by Piyush on 08/06/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import MapKit
import CocoaLumberjack

/**
 Instances of HTActionParams are used to build actions: https://docs.hypertrack.com/api/entities/action.html
 */
@objc public class HTActionParams: NSObject {

    /**
     Identifier of user to whom the action is assigned. Use setUserId to set this.
     */
    public var userId: String?

    /**
     Identifier of place where the action is to be completed. Use setExpectedPlaceId to set this.
     */
    public var expectedPlaceId: String?

    /**
     Expected place where the action is to be completed. Use setExpectedPlace to set this.
     */
    public var expectedPlace: HTPlace?

    /**
     Type of the action. Use setType to set this.
     */
    public var type: String = "visit"

    /**
     Unique id (internal identifier) for the action. Use setUniqueId to set this.
     */
    public var uniqueId: String = ""

    /**
     Collection id (internal identifier) for the action. Use setCollectionId to set this.
     */
    public var collectionId: String = ""

    /**
     Set Unique id for the action as a unique Short Code (6-8 digit alphanumeric
     string) automatically generated for the Action's tracking url.
     */
    public var uniqueIdAsShortCode: Bool = false

    /**
     Expected time for the action. Use setExpectedAt to set this.
     */
    public var expectedAt: String?
    
    /**
     Rules to autocomplete action based on time or place.
     */
    public var autocompleteRule: HTPayload?
    
    /**
     Action will automatically cancel after those many hours if not completed prior. Use this to automatically clean up actions.
     Defaults to 24 hours after expected_at if available; else 24 hours after eta_at_creation
     if you had set expected_place; else 24 hours after created_at.
     */
    public var autocancelAfter: Int?
    
    /**
     Custom key-values pairs in your system that you want to associate with the action.
     */
    public var metadata: HTPayload?
    
    internal var currentLocation: HTLocation?
    
    /**
     Set user id for the action
     
     - Parameter userId: UUID identifier for the user
     */
    public func setUserId(userId: String) -> HTActionParams {
        self.userId = userId
        return self
    }

    /**
     Set expected place for the action
     
     - Parameter expectedPlace: Place object
     */
    public func setExpectedPlace(expectedPlace: HTPlace) -> HTActionParams {
        self.expectedPlace = expectedPlace
        return self
    }

    /**
     Set expected place for the action
     
     - Parameter expectedPlaceId: UUID identifier for the place
     */
    public func setExpectedPlaceId(expectedPlaceId: String) -> HTActionParams {
        self.expectedPlaceId = expectedPlaceId
        return self
    }

    /**
     Set type for the action
     
     - Parameter type: UUID identifier for the place
     */
    public func setType(type: String) -> HTActionParams {
        self.type = type
        return self
    }

    /**
     Set unique id for the action
     
     - Parameter uniqueId: unique id for the action
     */
    public func setUniqueId(uniqueId: String) -> HTActionParams {
        self.uniqueId = uniqueId
        return self
    }

    /**
     Set Unique id for the action as a unique Short Code (6-8 digit alphanumeric
     string) automatically generated for the Action's tracking url.
     */
    public func setUniqueIdAsShortCode() -> HTActionParams {
        self.uniqueIdAsShortCode = true
        return self
    }

    /**
     Set expected at for the action
     
     - Parameter expectedAt: expected timestamp as ISO datetime string
     */
    public func setExpectedAt(expectedAt: String) -> HTActionParams {
        self.expectedAt = expectedAt
        return self
    }

    public func setAutocompleteRule(rule: HTPayload) -> HTActionParams {
        self.autocompleteRule = rule
        return self
    }
    
    public func setAutocancelAfter(hours: Int) -> HTActionParams {
        self.autocancelAfter = hours
        return self
    }
    
    public func setMetaData(metadata: HTPayload) -> HTActionParams {
        self.metadata = metadata
        return self
    }
    
    internal func setCurrentLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> HTActionParams {
        let currentLocation = HTLocation(
            clLocation: CLLocation(latitude: latitude, longitude: longitude),
            locationType: "point")
        self.currentLocation = currentLocation
        return self
    }

    internal func setLocation(coordinates: CLLocationCoordinate2D) -> HTActionParams {
        let currentLocation = HTLocation(
            clLocation: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude),
            locationType: "point")
        self.currentLocation = currentLocation
        return self
    }

    internal func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "user_id": userId ?? HyperTrack.getUserId() ?? "",
            "type": type,
            "unique_id": uniqueId,
            "set_unique_id_as_short_code": uniqueIdAsShortCode,
            "current_location": currentLocation?.toDict() ?? [:],
            "collection_id": collectionId
            ]
        if let expectedPlaceId = expectedPlaceId, !expectedPlaceId.isEmpty {
            dict["expected_place_id"] = expectedPlaceId
        } else if let expectedPlace = expectedPlace {
            dict["expected_place"] = expectedPlace.toDict()
        }
        if let autocancelAfter = autocancelAfter {
            dict["autocancel_after"] = autocancelAfter
        }
        if let autocompleteRule = autocompleteRule {
            dict["autocomplete_rule"] = autocompleteRule
        }
        if let metadata = metadata {
            dict["metadata"] = metadata
        }
        if let expectedAt = expectedAt {
            dict["expected_at"] = expectedAt
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
}

extension HTActionParams {
    public convenience init(type: String) {
        self.init()
        self.type = type
        collectionId = UUID().uuidString
//        expectedAt = (Date() + 3600).iso8601
    }
    
    public static var `default`: HTActionParams {
        return HTActionParams(type: "visit")
    }
}

