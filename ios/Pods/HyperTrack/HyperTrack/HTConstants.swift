//
//  HTConstants.swift
//  Pods
//
//  Created by Ravi Jain on 04/06/17.
//
//

import UIKit

public struct HTConstants {
  
    enum UseCases: Int {
        case singleUserSingleAction = 0
        case singleUserMultipleAction = 1
        case multipleUserMultipleAction = 2
        case multipleUserMultipleActionSamePlace = 3
    }

   static let HTLocationPermissionChangeNotification = "LocationPermissionChangeNotification"
   static let HTUserIdCreatedNotification = "UserIdCreatedNotification"
   static let HTTrackingStartedForLookUpId = "HTTrackingStartedForLookUpId"
   static let HTTrackingStopedForAction = "HTTrackingStoppedForAction"
   static let HTTrackingStopedForLookUpId = "HTTrackingStoppedForLookUpId"
   public static let HTLocationChangeNotification = "HTLocationChangeNotification"
   static let HTLocationHeadingChangeNotification = "HTLocationHeadingChangeNotification"
   static let HTMonitoredRegionEntered = "HTMonitoredRegionEntered"
   static let HTMonitoredRegionExited = "HTMonitoredRegionExited"
   static let HTSDKControlsRefreshedNotification = "HTSDKControlsRefreshedNotification"
   static let HTPowerStateChangedNotification = "HTPowerStateChangedNotification"
   static let HTNetworkStateChangedNotification = "HTNetworkStateChangedNotification"
   static let HTTrackingStartedNotification = "HTTrackingStartedNotification"

    public struct ImageNames {
        struct AddressResult {
            static let current = "v2addressResultCurrent"
            static let new = "v2addressResultNew"
            static let recent = "v2addressResultRecent"
        }
        struct Placeline {
            static let summaryCycle = "v2placelineSummaryCycle"
            static let summaryDrive = "v2placelineSummaryDrive"
            static let summaryWalk = "v2placelineSummaryWalk"
            static let summaryPlaces = "v2placelineSummaryPlaces"
            static let drive = "v2placelineDrive"
            static let cycle = "v2placelineCycle"
            static let walk = "v2placelineWalk"
            static let offline = "v2markerOfflineSmall"
        }
        struct Marker {
            static let cycle = "v2markerCycle"
            static let destination = "v2markerDestination"
            static let drive = "v2markerDrive"
            static let offline = "v2markerOffline"
            static let stop = "v2markerStop"
            static let walk = "v2markerWalk"
        }
        static let battery = "v2battery"
        static let calendar = "v2calendar"
        static let call = "v2call"
        static let checkmark = "v2checkmark"
        static let close = "v2close"
        static let cross = "v2cross"
        static let edit = "v2edit"
        static let errorIcon = "v2errorIcon"
        static let leftArrowButton = "v2leftArrowButton"
        static let rightArrow = "v2rightArrow"
        static let rightArrowButton = "v2rightArrowButton"
        static let selectOnMap = "v2selectOnMap"
        static let share = "v2share"
        static let backButton = "v2backButton"
        public static let crossButton = "v2crossButton"
        static let recenterButton = "v2recenterButton"
        static let settings = "v2Settings"
        static let floatingIcon = "v2selectOnMapFloatingIcon"
    }
}
