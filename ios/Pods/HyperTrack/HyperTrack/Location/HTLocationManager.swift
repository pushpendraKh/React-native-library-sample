//
//  HTLocationManager.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 21/02/17.
//  Copyright © 2017 HyperTrack, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import CoreMotion
import CocoaLumberjack

@objc public protocol HTLocationUpdatesDelegate: class {
    func didUpdateLocations(_ locations: [CLLocation])
}

protocol LocationEventsDelegate : class {
    func locationManager(_ manager: LocationManagerProtocol, didEnterRegion region: CLRegion)
    func locationManager(_ manager: LocationManagerProtocol, didExitRegion region: CLRegion)
    func locationManager(_ manager: LocationManagerProtocol, didUpdateLocations locations: [HTLocation])
    func locationManager(_ manager: LocationManagerProtocol,
                         didVisit visit: CLVisit)
    func locationManager(_ manager: LocationManagerProtocol,
                         didChangeAuthorization status: CLAuthorizationStatus)
}

enum LocationInRegion: String {
    case belongsToRegion = "belongsToRegion"
    case belongsOutsideRegion =  "belongsOutsideRegion"
    case cannotDetermine = "cannotDetermine"
}

class LocationManager: NSObject, LocationManagerProtocol  {
    // Constants
    private let kFilterDistance: Double = 50
    private let kHeartbeat: TimeInterval = 10
    // Managers
    private let locationManager = CLLocationManager()

    // State variables
    private var isHeartbeatSetup: Bool = false

    var locationPermissionCompletionHandler : ((_ isAuthorized: Bool) -> Void)?
   
    weak var locationEventsDelegate: LocationEventsDelegate?
    weak var eventDelegate: HTEventsDelegate?

    //To be used from the host app
    weak var locationUpdatesDelegate: HTLocationUpdatesDelegate?
    
    var isTracking: Bool {
        get {
            return Settings.getTracking()
        }

        set {
            Settings.setTracking(isTracking: newValue)
        }
    }

    override init() {
        super.init()
        self.initializeDB()
        locationManager.distanceFilter = kFilterDistance
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
        locationManager.activityType = CLActivityType.automotiveNavigation
    }
    
    func initializeDB(){
        do {
            DDLogInfo("creating locations table")
            try HTDatabaseService.sharedInstance.locationDBHelper?.createTable()
        } catch  {
            DDLogError("not able to create table for locatvars")
        }
    }
    
    func startTracking(completionHandler: ((_ error: HTError?) -> Void)?){
        
        self.locationManager.startMonitoringVisits()
        self.locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(onAppTerminate(_:)), name: Notification.Name.UIApplicationWillTerminate, object: nil)
       
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = false
        } else {
            // Fallback on earlier versions
        }
        
        self.allowBackgroundLocationUpdates()
    }
    
    func stopTracking() {
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.stopMonitoringVisits()
        self.locationManager.stopUpdatingLocation()
        NotificationCenter.default.removeObserver(self)
    }

    func allowBackgroundLocationUpdates() {
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            // Fallback on earlier versions
        }
    }

    func requestLocation() {
        if #available(iOS 9.0, *) {
            self.locationManager.requestLocation()
        } else {
            // Fallback on earlier versions
        }
    }
    
    func getCurrentLocation(completionHandler: @escaping (_ currentLocation: CLLocation?,
        _ error: HTError?) -> Void) {
        // Check location authorization status
        let authStatus: CLAuthorizationStatus = HyperTrack.locationAuthorizationStatus()
        if (authStatus != .authorizedAlways && authStatus != .authorizedWhenInUse) {
            let htError = HTError(HTErrorType.locationPermissionsError)
            DDLogError("Error while getCurrentLocation: \(htError.errorMessage)")
            completionHandler(nil, htError)
            return
        }
        
        // Check location services status
        if (!HyperTrack.locationServicesEnabled()) {
            let htError = HTError(HTErrorType.locationDisabledError)
            DDLogError("Error while getCurrentLocation: \(htError.errorMessage)")
            completionHandler(nil, htError)
            return
        }
        
        // Fetch current location from LocationManager
        let currentLocation = self.getLastKnownLocation()
        if (currentLocation == nil) {
            let htError = HTError(HTErrorType.invalidLocationError)
            DDLogError("Error while getCurrentLocation: \(htError.errorMessage)")
            completionHandler(nil, htError)
            
        } else {
            completionHandler(currentLocation, nil)
        }
    }

    func updateLocationManager(filterDistance: CLLocationDistance, pausesLocationUpdatesAutomatically: Bool = false) {
        locationManager.distanceFilter = filterDistance
        locationManager.pausesLocationUpdatesAutomatically = pausesLocationUpdatesAutomatically
        if false == pausesLocationUpdatesAutomatically {
            startTracking(completionHandler: nil)
        }
    }

    func getLastKnownLocation() -> CLLocation? {
        return self.locationManager.location
    }
    
    func getLastKnownHTLocation() -> HTLocation?{
        if let location = self.locationManager.location{
            let htLocation = HTLocation.init(clLocation: location, locationType: "point")
            htLocation.lookUpId = UUID().uuidString
            HTDatabaseService.sharedInstance.locationDBHelper?.insert(htLocation: htLocation)
            return htLocation
        }
       return nil
    }

    func getLastKnownHeading() -> CLHeading? {
        return self.locationManager.heading
    }

    func setRegularLocationManager() {
        self.updateLocationManager(filterDistance: kFilterDistance)
    }

    func onAppTerminate(_ notification: Notification) {
        self.locationManager.startUpdatingLocation()
    }

   func setupHeartbeatMonitoring() {
        isHeartbeatSetup = true
        DispatchQueue.main.asyncAfter(deadline: .now() + kHeartbeat, execute: {
            self.isHeartbeatSetup = false
            if #available(iOS 9.0, *) {
                self.locationManager.requestLocation()
            }
        })
    }

    func requestWhenInUseAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        self.locationManager.requestAlwaysAuthorization()
    }

    func requestAlwaysAuthorization(completionHandler: @escaping (_ isAuthorized: Bool) -> Void) {
        locationPermissionCompletionHandler  = completionHandler
        self.locationManager.requestAlwaysAuthorization()
    }

    func doesLocationBelongToRegion(stopLocation: HTLocation, radius: Int, identifier: String) -> LocationInRegion {
        let clLocation = stopLocation.clLocation
        let monitoringRegion = CLCircularRegion(center: clLocation.coordinate, radius: CLLocationDistance(radius), identifier: identifier)
        if let location = self.getLastKnownLocation() {
            if location.timestamp.timeIntervalSince1970 > (Date().timeIntervalSince1970 - 120) {
                if location.horizontalAccuracy < 100 {
                    if monitoringRegion.contains(location.coordinate) {
                        DDLogInfo("user coordinate is in monitoringRegion" + location.description)
                        return LocationInRegion.belongsToRegion
                    } else {
                        return LocationInRegion.belongsOutsideRegion
                    }
                } else {
                    DDLogInfo("user coordinate is not accurate so not considering for geofenceing")
                }
            } else {
                DDLogInfo("user coordinate is very old so not using for geofencing requesting location")
            }
        } else {
            DDLogInfo("user coordinate does not belong to monitoringRegion" + stopLocation.description)
        }
        self.requestLocation()
        return LocationInRegion.cannotDetermine
    }

    func startMonitoringForEntryAtPlace(place: HTPlace, radius: CLLocationDistance, identifier: String) {
        if let placeLocation = place.location {
            let circularRegion = CLCircularRegion(center: placeLocation.toCoordinate2d(), radius: CLLocationDistance(radius), identifier: identifier)

            if let location = self.getLastKnownLocation() {
                if location.timestamp.timeIntervalSince1970 > (Date().timeIntervalSince1970 - 120) {
                    if location.horizontalAccuracy < 100 {
                        if circularRegion.contains(location.coordinate) {
                            if let eventDelegate = self.eventDelegate {
                                eventDelegate.didEnterMonitoredRegion?(region: circularRegion)
                            }
                            return
                        }
                    }
                }
            }

            var clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
            if clampedRadius < 100 {
                clampedRadius = 100
            }

            DDLogInfo("starting monitoring for region having identifier : " + identifier  + " radius : " + clampedRadius.description)
            let monitoringRegion = CLCircularRegion(center: (placeLocation.toCoordinate2d()), radius: clampedRadius, identifier: identifier)
            DDLogInfo("startMonitorForPlace having identifier: \(identifier ) ")
            monitoringRegion.notifyOnEntry = true
            monitoringRegion.notifyOnExit = false

            locationManager.startMonitoring(for: monitoringRegion)
            self.requestLocation()
        }
    }

    func startMonitoringExitForLocation(location: CLLocation, identifier: String) {
        DDLogInfo("startMonitoringExitForLocation having identifier: \(identifier) ")
        let monitoringRegion = CLCircularRegion(center: location.coordinate, radius: 50, identifier: identifier)
        monitoringRegion.notifyOnExit = true
        monitoringRegion.notifyOnEntry = false
        locationManager.startMonitoring(for: monitoringRegion)
        self.requestLocation()
    }

    func getLocationIdentifier(location: CLLocation) -> String {
        return location.coordinate.latitude.description + location.coordinate.longitude.description
    }
    
    func checkForGeofence(clLocation: CLLocation){
        if clLocation.timestamp.timeIntervalSince1970 > (Date().timeIntervalSince1970 - 600) {
            if clLocation.horizontalAccuracy <= 100 {
                for monitoringRegion in locationManager.monitoredRegions {
                    if let circularRegion = monitoringRegion as? CLCircularRegion {
                        if circularRegion.contains(clLocation.coordinate) {
                            if circularRegion.notifyOnEntry {
                                DDLogInfo("entered region due to a location update , identifier : " + monitoringRegion.identifier)
                                if let locationEventDelegate = self.locationEventsDelegate {
                                    locationEventDelegate.locationManager(self, didEnterRegion: circularRegion)
                                }
                                
                                if let eventDelegate = self.eventDelegate {
                                    eventDelegate.didEnterMonitoredRegion?(region: circularRegion)
                                }
                                
                                locationManager.stopMonitoring(for: monitoringRegion)
                            }
                        } else if circularRegion.notifyOnExit {
                            DDLogInfo("exited region due to a location update , identifier : " + monitoringRegion.identifier)
                            if let locationEventDelegate = self.locationEventsDelegate {
                                locationEventDelegate.locationManager(self, didExitRegion: monitoringRegion)
                            }
                            
                            locationManager.stopMonitoring(for: monitoringRegion)
                            
                        }
                        
                    }
                }
            }
        }
    }
    
    public func getLocationFromLookUpId(lookUpId: String) -> HTLocation?{
        return  HTDatabaseService.sharedInstance.locationDBHelper?.getLocationFromLookUpId(lookUpId: lookUpId)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        if let locationEventDelegate = self.locationEventsDelegate {
            locationEventDelegate.locationManager(self, didChangeAuthorization: status)
        }

        DDLogInfo("Did change authorization: \(status)")
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: HTConstants.HTLocationPermissionChangeNotification),
                object: nil,
                userInfo: nil)
        if locationPermissionCompletionHandler != nil {
            if status == .authorizedAlways {
                locationPermissionCompletionHandler!(true)
                locationPermissionCompletionHandler = nil
            } else if status != .notDetermined {
                locationPermissionCompletionHandler!(false)
                locationPermissionCompletionHandler = nil
            }
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didVisit visit: CLVisit) {

        if !Settings.getTracking() {
            return
        }

        if let locationEventDelegate = self.locationEventsDelegate {
            locationEventDelegate.locationManager(self, didVisit: visit)
        }

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: HTConstants.HTLocationChangeNotification),
                object: nil,
                userInfo: nil)
    }

    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        DDLogInfo("Did pause location updates")
    }

    func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        DDLogInfo("Did resume location updates")
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {

       
        if !Settings.getTracking() {
            return
        }
        
        var htLocations = [HTLocation]()
        
        for location in locations {
            let htLocation = HTLocation.init(clLocation: location, locationType: "point")
            htLocation.lookUpId = UUID().uuidString
            HTDatabaseService.sharedInstance.locationDBHelper?.insert(htLocation: htLocation)
            htLocations.append(htLocation)
        }

        if let locationEventDelegate = self.locationEventsDelegate {
            locationEventDelegate.locationManager(self, didUpdateLocations: htLocations)
        }

        if let clLocation = locations.last {
            checkForGeofence(clLocation: clLocation)
        }

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: HTConstants.HTLocationChangeNotification),
                object: nil,
                userInfo: nil)
        locationUpdatesDelegate?.didUpdateLocations(locations)
    }
    

    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        DDLogError("Did fail with error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 { return }
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: HTConstants.HTLocationHeadingChangeNotification),
                object: nil,
                userInfo: ["heading": newHeading])

    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DDLogInfo(" location manager didEnterRegion " + region.identifier)
        if let locationEventDelegate = self.locationEventsDelegate {
            locationEventDelegate.locationManager(self, didEnterRegion: region)
        }

        if let eventDelegate = self.eventDelegate {
            eventDelegate.didEnterMonitoredRegion?(region: region)
        }

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: HTConstants.HTMonitoredRegionEntered),
                object: nil,
                userInfo: ["region": region])
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DDLogInfo(" location manager didExitRegion " + region.identifier)

        if let locationEventDelegate = self.locationEventsDelegate {
            locationEventDelegate.locationManager(self, didExitRegion: region)
        }

        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: HTConstants.HTMonitoredRegionExited),
                object: nil,
                userInfo: ["region": region])
    }

    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if region != nil {
            DDLogInfo(" location manager monitoringDidFailFor " + (region?.identifier)!)
        }
    }
    
    func didChangeActivityTo(activity: HTSDKActivity, fromActivity: HTSDKActivity?) {
        
    }
    
}

