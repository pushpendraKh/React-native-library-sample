//
//  HTUserPreferences.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 23/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack

class Settings {
   private static let publishableKeyString = "HyperTrackPublishableKey"

   private static let mockTrackingString = "HyperTrackIsMockTracking"

   private static let lastKnownLocationString = "HyperTrackLastKnownLocation"
   private static let minimumDurationString = "HyperTrackMinimumDuration"
   private static let minimumDisplacementString = "HyperTrackMinimumDisplacement"
   private static let batchDurationString = "HyperTrackBatchDuration"

   private static let mockCoordinatesString = "HyperTrackMockCoordinates"
   private static let savedPlacesString = "HyperTrackSavedPlaces"

   private static let trackingString = "HyperTrackIsTracking"
   private static let htSessionId = "HyperTrackSessionId"
    private static let htLastSessionId = "HyperTrackLastSessionId"
   private static let htDeviceId = "HyperTrackDeviceId"
   private static let htTrackingStartedDate = "HyperTrackTrackingStartedDate"
   private static let lastActiveTimeOfSDKKeyString = "lastActiveTimeOfSDK"

    static func getBundle() -> Bundle? {
        let bundleRoot = Bundle(for: HyperTrack.self)
        return Bundle(path: "\(bundleRoot.bundlePath)/HyperTrack.bundle")
    }

    static var sdkVersion: String {
        get {
            if let bundle = Settings.getBundle() {
                let dictionary = bundle.infoDictionary!
                if let version = dictionary["CFBundleShortVersionString"] as? String {
                    return version
                }
            }
            return ""
        }
    }
    
    static var lastSessionId: String {
        get {
            return HTUserDefaults.standard.string(forKey: htLastSessionId) ?? ""
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: htLastSessionId)
            HTUserDefaults.standard.synchronize()
        }
    }

    static var sessionId: String {
        get {
            return HTUserDefaults.standard.string(forKey: htSessionId) ?? ""
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: htSessionId)
            HTUserDefaults.standard.synchronize()
        }
    }
    
    
    static var deviceId: String {
        get {
            return HTUserDefaults.standard.string(forKey: htDeviceId) ?? ""
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: htDeviceId)
            HTUserDefaults.standard.synchronize()
        }
    }
    
    
    static var lastActiveTimeOfSDK: Date? {
        get {
            return HTUserDefaults.standard.object(forKey: lastActiveTimeOfSDKKeyString) as? Date
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: lastActiveTimeOfSDKKeyString)
            HTUserDefaults.standard.synchronize()
        }
    }
    

    static func setPublishableKey(publishableKey: String) {
        HTUserDefaults.standard.set(publishableKey, forKey: publishableKeyString)
        HTUserDefaults.standard.synchronize()
    }

    static func getPublishableKey() -> String? {
        return HTUserDefaults.standard.string(forKey: publishableKeyString)
    }

    static func setTracking(isTracking: Bool) {
        HTUserDefaults.standard.set(isTracking, forKey: trackingString)
        HTUserDefaults.standard.synchronize()
    }

    static func getTracking() -> Bool {
        return HTUserDefaults.standard.bool(forKey: trackingString)
    }

    static func setMockTracking(isTracking: Bool) {
        HTUserDefaults.standard.set(isTracking, forKey: mockTrackingString)
        HTUserDefaults.standard.synchronize()
    }

    static func getMockTracking() -> Bool {
        return HTUserDefaults.standard.bool(forKey: mockTrackingString)
    }

    static func setLastKnownLocation(location: HTLocation) {
        let locationJSON = location.toJson()
        HTUserDefaults.standard.set(locationJSON, forKey: lastKnownLocationString)
        HTUserDefaults.standard.synchronize()
    }

    static func getLastKnownLocation() -> HTLocation? {
        guard let locationString = HTUserDefaults.standard.string(forKey: lastKnownLocationString) else { return nil}
        let htLocation = HTLocation.fromJson(text: locationString)
        return htLocation
    }
    
    static func setMockCoordinates(coordinates: [TimedCoordinates]) {
        HTUserDefaults.standard.set(timedCoordinatesToStringArray(coordinates: coordinates), forKey: mockCoordinatesString)
    }

    static func getMockCoordinates() -> [TimedCoordinates]? {
        if let object = HTUserDefaults.standard.string(forKey: mockCoordinatesString) {
            return timedCoordinatesFromStringArray(coordinatesString: object)
        }
        return nil
    }

    static func addPlaceToSavedPlaces(place: HTPlace) {
        var savedPlaces = getAllSavedPlaces()
        if savedPlaces != nil {
            if(!HTGenericUtils.checkIfContains(places: savedPlaces!, inputPlace: place)) {
                savedPlaces?.append(place)
            } else {
                var frequency = HTUserDefaults.standard.integer(forKey: place.getIdentifier())
                frequency +=  1
                HTUserDefaults.standard.set(frequency, forKey: place.getIdentifier())
                HTUserDefaults.standard.synchronize()
            }
        } else {
            savedPlaces = [place]
        }

        var savedPlacesDictArray = [[String: Any]]()
        for htPlace in savedPlaces! {
            let htPlaceDict = htPlace.toDict()
            savedPlacesDictArray.append(htPlaceDict)

        }

        var jsonDict = [String: Any]()
        jsonDict["results"] = savedPlacesDictArray

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: JSONSerialization.WritingOptions.prettyPrinted)
            HTUserDefaults.standard.set(jsonData, forKey: savedPlacesString)
            HTUserDefaults.standard.synchronize()
        } catch {
            DDLogError("Error in getting actions from json: " + error.localizedDescription)
        }
    }

    static func getAllSavedPlaces() -> [HTPlace]? {
        if let jsonData = HTUserDefaults.standard.data(forKey: savedPlacesString) {
            var htPlaces = HTPlace.multiPlacesFromJson(data: jsonData)
            htPlaces = htPlaces?.reversed()
            var placeToFrequencyMap = [HTPlace: Int]()
            for place in htPlaces! {
                let frequency = HTUserDefaults.standard.integer(forKey: place.getIdentifier())
                placeToFrequencyMap[place] = frequency
            }

            let sortedKeys = Array(placeToFrequencyMap.keys).sorted(by: {placeToFrequencyMap[$1]! < placeToFrequencyMap[$0]!})
            return sortedKeys
        }
        return []
    }
    
    
    static var trackingStartedAt: Date? {
        get {
            return HTUserDefaults.standard.object(forKey: htTrackingStartedDate) as? Date
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: htTrackingStartedDate)
            HTUserDefaults.standard.synchronize()
        }
    }
    
    static func deleteAllValues(){
        HTUserDefaults.standard.deleteAllValues()
    }
    
    static func deleteRegisteredToken(){
    
    }

}
