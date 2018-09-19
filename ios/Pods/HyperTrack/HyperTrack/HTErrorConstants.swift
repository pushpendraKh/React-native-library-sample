//
//  HTErrorConstants.swift
//  HyperTrack
//
//  Created by ravi on 11/26/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit

/**
 The HyperTrack Error type enum.
 */
public enum HTErrorType: String {
    /**
     Error for key not set
     */
    case publishableKeyError = "A publishable key has not been set"
    
    /**
     Error for user id not set
     */
    case userIdError = "A userId has not been set"
    
    /**
     Error for location permissions
     */
    case locationPermissionsError = "Location permissions are not enabled"
    
    /**
     Error for location enabled
     */
    case locationDisabledError = "Location services are not available"
    
    /**
     Invalid location error
     */
    case invalidLocationError = "Error fetching a valid Location"
    
    /**
     Error while fetching ETA
     */
    case invalidETAError = "Error while fetching eta. Please try again."
    
    /**
     Error for malformed json
     */
    case jsonError = "The server returned malformed json"
    
    /**
     Error for server errors
     */
    case serverError = "An error occurred communicating with the server"
    
    /**
     Error for invalid parameters
     */
    case invalidParamsError = "Invalid parameters supplied"
    
    /**
     Unknown error
     */
    case unknownError = "An unknown error occurred"
    
    /**
     Authorization error
     */
    case authorizationFailedError = "Authorization Failed"
    
}

/**
 The HyperTrack Error type enum.
 */
@objc public enum HTErrorCode: NSInteger {
    /**
     Error for key not set
     */
    case publishableKeyError = 100
    
    /**
     Error for user id not set
     */
    case userIdError = 102
    
    /**
     Error for location permissions
     */
    case locationPermissionsError = 104
    
    /**
     Error for location enabled
     */
    case locationDisabledError = 105
    
    /**
     Invalid location error
     */
    case invalidLocationError = 121
    
    /**
     Error while fetching ETA
     */
    case invalidETAError = 123
    
    /**
     Error for invalid parameters
     */
    case invalidParamsError = 131
    
    /**
     Error for malformed json
     */
    case jsonError = 142
    
    /**
     Error for server errors
     */
    case serverError = 141
    
    /**
     Unknown error
     */
    case unknownError = 151
    
    /**
     Authorization error
     */
    case authorizationFailedError = 403
    
}
