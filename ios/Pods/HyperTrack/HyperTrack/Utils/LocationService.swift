//
//  LocationService.swift
//  MQTTExample
//
//  Created by Atul Manwar on 19/01/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import Foundation
import CoreLocation

public protocol LocationServiceDelegate: class {
    func updatedLocations(_ location: [CLLocation])
    func updatedHeading(_ location: CLHeading)
}

struct SdkConfig {
    let time: Double
    let distance: Double
    
    static let `default` = SdkConfig(time: 300, distance: 25)
    
    init(time: Double, distance: Double) {
        self.time = time
        self.distance = distance
    }
    
    init(_ dict: [String: Any]) {
        if let time = dict["t"] as? Double, let distance = dict["d"] as? Double {
            self.init(time: time, distance: distance)
        } else {
            self.init(time: 300, distance: 25)
        }
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "t": time,
            "d": distance
        ]
    }
}

extension SdkConfig: Equatable {
}

func == (lhs: SdkConfig, rhs: SdkConfig) -> Bool {
    return (lhs.time == rhs.time && lhs.distance == rhs.distance)
}

public class LocationService: NSObject {
    fileprivate let locationManager: CLLocationManager
    weak var delegate: LocationServiceDelegate?
    fileprivate var sdkConfig: SdkConfig = SdkConfig.default {
        didSet {
        }
    }
    
    fileprivate var isAppInForeground: Bool = true
    
    fileprivate var enableLocation: Bool = false {
        didSet {
            if enableLocation {
                locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
            } else {
                locationManager.stopUpdatingLocation()
                locationManager.stopUpdatingHeading()
            }
        }
    }
    
    public override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }
    
    public func addDelegate(_ delegate: LocationServiceDelegate) {
        
    }
}

extension LocationService {
    public func start() {
//        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
//        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.activityType = CLActivityType.automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.distanceFilter = sdkConfig.distance
        enableLocation = true
    }
    
    public func stop() {
        enableLocation = false
    }
    
    func applicationDidEnterForeground() {
        isAppInForeground = true
        handleDeferredLocationUpdates()
    }
    
    func applicationDidEnterBackground() {
        isAppInForeground = false
        handleDeferredLocationUpdates()
    }
}

extension LocationService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            enableLocation = true
        case .denied:
            break
        case .notDetermined:
            break
        case .restricted:
            break
        }
    }
    
    fileprivate func handleDeferredLocationUpdates() {
        if !isAppInForeground && CLLocationManager.deferredLocationUpdatesAvailable() {
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.allowDeferredLocationUpdates(untilTraveled: sdkConfig.distance, timeout: sdkConfig.time)
        } else {
            locationManager.distanceFilter = sdkConfig.distance
            locationManager.disallowDeferredLocationUpdates()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.updatedLocations(locations)
        handleDeferredLocationUpdates()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.updatedHeading(newHeading)
    }
}
