//
//  HTGenericUtils.swift
//  Pods
//
//  Created by Ravi Jain on 7/27/17.
//
//

import UIKit
import CoreTelephony

class HTGenericUtils: NSObject {

    public static func getPlaceName (place: HTPlace?) -> String! {
        var destinationText = ""
        if let place = place {
            if place.name != "" {
                destinationText = (place.name)
            } else {
                if (place.address.components(separatedBy: ",").count) <= 2 {
                    destinationText = place.address
                } else {
                    destinationText = (place.address.components(separatedBy: ",").first)! + (place.address.components(separatedBy: ",")[1])
                }
                
            }
        }
        
        return destinationText
    }

    public static func checkIfContains(places: [HTPlace], inputPlace: HTPlace) -> Bool {
        for place in places {
            if place.location?.coordinates.first == inputPlace.location?.coordinates.first {
                if place.location?.coordinates.last == inputPlace.location?.coordinates.last {
                    return true
                }
            }
        }
        return false
    }

}
