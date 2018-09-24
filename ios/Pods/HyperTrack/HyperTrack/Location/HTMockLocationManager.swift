//
//  HTMockLocationManager.swift
//  HyperTrack
//
//  Created by Arjun Attam on 04/06/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CoreLocation
import CocoaLumberjack

class MockLocationManager: NSObject, LocationManagerProtocol {
    var eventDelegate: HTEventsDelegate?
    
    var origin: CLLocationCoordinate2D?
    var destination: CLLocationCoordinate2D?
    var requestManager: RequestManager

    var mockTimer: Timer?
    var coordinates: [TimedCoordinates]?
    
    //To be used from the host app. Mock location manager won't send location updates.
    weak var locationUpdatesDelegate: HTLocationUpdatesDelegate?

    init(origin: CLLocationCoordinate2D?, destination: CLLocationCoordinate2D?){
        self.origin = origin
        self.destination = destination
        self.requestManager  = RequestManager()
        super.init()
    }
    
    weak var locationEventsDelegate: LocationEventsDelegate?
    
    func startTracking(completionHandler: ((_ error: HTError?) -> Void)?) {
      
        var originLatlng: String = ""
        
        if (origin != nil) {
            originLatlng = "\(origin?.latitude ?? 28.556446),\(origin?.longitude ?? 77.174095)"
        }else{
            if let location = HTSDKDataManager.sharedInstance.locationManager.getLastKnownLocation() {
                originLatlng = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
            } else {
                originLatlng = "28.556446,77.174095"
            }
        }
        
        var destinationLatlng: String? = nil
        
        if destination != nil {
            destinationLatlng = "\(destination?.latitude ?? 28.556446),\(destination?.longitude ?? 77.174095)"
        }
        
        self.requestManager.getSimulatePolyline(originLatlng: originLatlng, destinationLatLong: destinationLatlng) { (polyline, error) in
            if let error = error {
                completionHandler?(error)
                return
            }
            
            if let polyline = polyline {
                DDLogInfo("Get simulated polyline successful")
                // Mock location manager maintains a request manager
                // and converts these locations into events
                let decoded = timedCoordinatesFrom(polyline: polyline)
                self.startService(coordinates: decoded!)
            }
            completionHandler?(error)
        }
    }
    
    func stopTracking() {
        
    }
    
    func requestWhenInUseAuthorization() {
        
    }
    
    func requestAlwaysAuthorization() {
        
    }
    
    func requestAlwaysAuthorization(completionHandler: @escaping (Bool) -> Void) {
        
    }
    
    func getLocationFromLookUpId(lookUpId: String) -> HTLocation? {
        return  HTDatabaseService.sharedInstance.locationDBHelper?.getLocationFromLookUpId(lookUpId: lookUpId)
    }
    
    func getLastKnownLocation() -> CLLocation? {
        return nil
    }
    
    func getLastKnownHTLocation() -> HTLocation?{
        return nil
    }
    
    func startMonitoringForEntryAtPlace(place: HTPlace, radius: CLLocationDistance, identifier: String) {
        
    }
    
    func startMonitoringExitForLocation(location: CLLocation, identifier: String) {
        
    }
    
    func getCurrentLocation(completionHandler: @escaping (CLLocation?, HTError?) -> Void) {
        
    }
    
    func requestLocation() {
        
    }
    
    func updateLocationManager(filterDistance: CLLocationDistance, pausesLocationUpdatesAutomatically: Bool) {
        
  
    }

    func updateCoordinates(coordinates: [TimedCoordinates]) {
        Settings.setMockCoordinates(coordinates: coordinates)
        self.coordinates = coordinates
    }

    func startService(coordinates: [TimedCoordinates]) {
        self.updateCoordinates(coordinates: coordinates)
        self.scheduleNextTimer()
    }

    @objc func saveNextEvent() {
      
        if var coordinates = Settings.getMockCoordinates() {
            if coordinates.count > 0 {
                let first = coordinates.removeFirst()
                let location = CLLocation.init(coordinate: first.location, altitude: 0.0, horizontalAccuracy: 20.0, verticalAccuracy: 10.0, timestamp: first.timeStamp)
                let htLocation = HTLocation.init(clLocation: location, locationType: "point")
                htLocation.lookUpId = UUID().uuidString
                HTDatabaseService.sharedInstance.locationDBHelper?.insert(htLocation: htLocation)
                if let locationEventDelegate = self.locationEventsDelegate {
                    locationEventDelegate.locationManager(self, didUpdateLocations: [htLocation])
                }
                self.updateCoordinates(coordinates: coordinates)
                scheduleNextTimer()
            }
        }
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name(rawValue: HTConstants.HTLocationChangeNotification),
                object: nil,
                userInfo: nil)
    }

    func scheduleNextTimer() {
        // This method goes through self.coordinates and
        // keeps setting a timer on the basis of the timestamps
        // and saves the corresponding events
        if let coordinates = Settings.getMockCoordinates(), let first = coordinates.first {
            let timeToFire = first.timeStamp
            let timerInterval = timeToFire.timeIntervalSinceNow

            if timerInterval > 0 {
                // Set the timer
                self.mockTimer = Timer.scheduledTimer(timeInterval: timerInterval,
                                                      target: self,
                                                      selector: #selector(self.saveNextEvent),
                                                      userInfo: nil,
                                                      repeats: false)
            } else {
                // Just do what a timer would have done since
                // the timer interval is negative
                self.saveNextEvent()
            }
        }
    }

    func stopService() {
        if let timer = self.mockTimer {
            timer.invalidate()
        }
    }
    
    func didChangeActivityTo(activity: HTSDKActivity, fromActivity: HTSDKActivity?) {

    }
}
