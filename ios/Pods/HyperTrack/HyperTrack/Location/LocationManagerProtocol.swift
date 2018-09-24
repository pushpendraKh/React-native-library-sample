//
//  LocationManagerProtocol.swift
//  HyperTrack
//
//  Created by ravi on 11/27/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CoreLocation

protocol LocationManagerProtocol: class {
    //To be used by the host app
    var locationUpdatesDelegate: HTLocationUpdatesDelegate? { get set }

    var locationEventsDelegate: LocationEventsDelegate? { get set }
    var eventDelegate: HTEventsDelegate? { get set }

    func startTracking(completionHandler: ((_ error: HTError?) -> Void)?)
    
    func stopTracking()
    
    func requestWhenInUseAuthorization()
    
    func requestAlwaysAuthorization()
    
    func requestAlwaysAuthorization(completionHandler: @escaping (_ isAuthorized: Bool) -> Void)

    func getLocationFromLookUpId(lookUpId: String) -> HTLocation?
    
    func getLastKnownLocation() -> CLLocation?
    
    func getLastKnownHTLocation() -> HTLocation?

    func startMonitoringForEntryAtPlace(place: HTPlace, radius: CLLocationDistance, identifier: String)
    
    func startMonitoringExitForLocation(location: CLLocation, identifier: String)


    func getCurrentLocation(completionHandler: @escaping (_ currentLocation: CLLocation?, _ error: HTError?) -> Void)
    
    func requestLocation()

   func updateLocationManager(filterDistance: CLLocationDistance, pausesLocationUpdatesAutomatically: Bool)
    
    func didChangeActivityTo(activity: HTSDKActivity, fromActivity: HTSDKActivity?) 

}
