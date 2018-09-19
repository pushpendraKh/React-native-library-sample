//
//  HTPlace.swift
//  HyperTrack
//
//  Created by Atul Manwar on 26/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import CocoaLumberjack
import CoreLocation

/**
 Instances of HTPlace represent the place entity: https://docs.hypertrack.com/api/entities/place.html
 */
@objc public class HTPlace: NSObject, HTModelProtocol {
    /**
     Unique (uuid4) identifier for the place
     */
    public let id: String
    
    /**
     Name of the place
     */
    public let name: String
    
    /**
     Location coordinates of the place
     */
    public let location: HTGeoJSONLocation?
    
    /**
     Address string of the place
     */
    public let address: String
    
    /**
     Locality string of the place
     */
    public let locality: String
    
    /**
     Landmark of the place
     */
    public let landmark: String
    
    /**
     Zip code of the place
     */
    public let zipCode: String
    
    /**
     City of the place
     */
    public let city: String
    
    /**
     State of the place
     */
    public let state: String
    
    /**
     Country of the place
     */
    public let country: String
    
    public let displayText: String
    
    public let uniqueId: String
    
    public required init(dict: [String: Any]) {
        id = (dict["id"] as? String) ?? ""
        name = (dict["name"] as? String) ?? ""
        if let dict = (dict["location"] as? [String: Any]) {
            location = HTGeoJSONLocation.fromDict(dict: dict)
        } else {
            location = nil
        }
        address = (dict["address"] as? String) ?? ""
        locality = (dict["locality"] as? String) ?? ""
        landmark = (dict["landmark"] as? String) ?? ""
        zipCode = (dict["zip_code"] as? String) ?? ""
        city = (dict["city"] as? String) ?? ""
        state = (dict["state"] as? String) ?? ""
        country = (dict["country"] as? String) ?? ""
        uniqueId = (dict["unique_id"] as? String) ?? ""
        displayText = (dict["display_text"] as? String) ?? ""
    }
    
    internal func toDict() -> [String: Any] {
        let dict = [
            "id": id,
            "name": name,
            "location": location?.toDict() ?? [:],
            "address": address,
            "landmark": landmark,
            "zip_code": zipCode,
            "city": city,
            "locality": locality,
            "state": state,
            "country": country,
            "displayText": displayText
            ] as [String: Any]
        return dict
    }
    
    func getPlaceDisplayName() -> String? {
        return !displayText.isEmpty ? displayText : nil //!address.isEmpty ? address : (!displayText.isEmpty ? displayText : (!name.isEmpty ? name : nil))
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
    
    internal static func fromJson(text: String) -> HTPlace? {
        if let data = text.data(using: .utf8) {
            do {
                let userDict = try JSONSerialization.jsonObject(with: data, options: [])
                guard let dict = userDict as? [String: Any] else {
                    return nil
                }
                return HTPlace(dict: dict)
            } catch {
                DDLogError("Error in getting place from json: " + error.localizedDescription)
            }
        }
        return nil
    }
    
    static func multiPlacesFromJson(data: Data?) -> [HTPlace]? {
        do {
            let jsonDict = try JSONSerialization.jsonObject(with: data!, options: [])
            guard let dict = jsonDict as? [String: Any] else {
                return nil
            }
            guard let results = dict["results"] as? [Any] else {
                return []
            }
            return results.flatMap({ $0 as? [String: Any] }).flatMap({ HTPlace(dict: $0) })
        } catch {
            DDLogError("Error in getting actions from json: " + error.localizedDescription)
            return nil
        }
    }
    
    public func getIdentifier() -> String {
        if !id.isEmpty {
            return id
        } else if let coordinates = self.location?.toCoordinate2d() {
            return coordinates.latitude.description + coordinates.longitude.description
        } else {
            return ""
        }
    }
    
}

extension HTPlace {
    var displayName: String {
        return (!name.isEmpty ? name : (!address.isEmpty ? address : (!locality.isEmpty ? locality : "")))
    }
}

@objc public class HTPlaceBuilder: NSObject {
    fileprivate var dict: HTPayload = [:]
    
    public override init() {
        super.init()
    }
    
    public func build() -> HTPlace {
        return HTPlace(dict: dict)
    }
    
    public func setId(_ id: String) -> HTPlaceBuilder {
        dict["id"] = id
        return self
    }
    
    public func setName(_ name: String) -> HTPlaceBuilder {
        dict["name"] = name
        return self
    }
    
    public func setLocation(_ coordinates: CLLocationCoordinate2D) -> HTPlaceBuilder {
        dict["location"] = HTGeoJSONLocation(type: "Point", coordinates: coordinates).toDict()
        return self
    }
    
    public func setAddress(_ address: String) -> HTPlaceBuilder {
        dict["address"] = address
        return self
    }
    
    public func setLandmark(_ landmark: String) -> HTPlaceBuilder {
        dict["landmark"] = landmark
        return self
    }
    
    public func setUniqueId(_ uniqueId: String) -> HTPlaceBuilder {
        dict["unique_id"] = uniqueId
        return self
    }
    
    public func setZipCode(_ zipCode: String) -> HTPlaceBuilder {
        dict["zip_code"] = zipCode
        return self
    }
    
    public func setCity(_ city: String) -> HTPlaceBuilder {
        dict["city"] = city
        return self
    }
    
    public func setState(_ state: String) -> HTPlaceBuilder {
        dict["state"] = state
        return self
    }
    
    public func setCountry(_ country: String) -> HTPlaceBuilder {
        dict["country"] = country
        return self
    }
}
