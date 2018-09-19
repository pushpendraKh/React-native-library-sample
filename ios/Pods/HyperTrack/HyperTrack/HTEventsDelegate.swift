//
//  HTEventsDelegate.swift
//  Pods
//
//  Created by Ravi Jain on 7/26/17.
//
//

import UIKit
import MapKit
import CoreLocation

@objc public protocol HTEventsDelegate {

    /**
     Set this method to receive events on the delegate
     
     - Parameter event: The event that occurred
     */
    func didReceiveEvent(_ event: HyperTrackEvent)
    /**
     Set this method to receive errors on the delegate
     
     - Parameter error: The error that occurred
     */
    func didFailWithError(_ error: HTError)

    /**
     Implement this delegate method to get location status update for tracked action
     */
    @objc optional func locationStatusChangedFor(action: HTAction, isEnabled: Bool)

    /**
     Implement this delegate method to get network status update for tracked action
     */
    @objc optional func networkStatusChangedFor(action: HTAction, isConnected: Bool)

    /**
     Implement this delegate method to get action status update for tracked action like completed,assigned
     */
    @objc optional func actionStatusChanged(forAction: HTAction, toStatus: String?)

    /**
     Implement this delegate method to get a callback when action details are refreshed
     */
    @objc optional func didRefreshData(forAction: HTAction)

    /**
     Implement this delegate method to get a callback when action details are refreshed for a collection id
     */
    @objc optional func didRefreshData(forCollectionId: String, actions: [HTAction]?)

    @objc optional func didEnterMonitoredRegion(region: CLRegion)

    @objc optional func didShowSummary(forAction: HTAction)


}
