//
//  HTDelegate.swift
//  HyperTrack
//
//  Created by Tapan Pandita on 02/03/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CocoaLumberjack

/**
 The HyperTrack Error object. Contains an error type.
 */
@objc public class HTError: NSObject, Error {

    /**
     Enum for various error types
     */
    public let type: HTErrorType

    @objc public let errorCode: HTErrorCode
    @objc public var errorMessage: String
    @objc public let displayErrorMessage: String

    init(_ type: HTErrorType) {
        self.type = type
        self.errorCode = HTError.getErrorCode(type)
        self.errorMessage = HTError.getErrorMessage(type)
        self.displayErrorMessage = HTError.getErrorMessage(type)
    }

    init(_ type: HTErrorType, responseData: Data?) {
        self.type = type
        self.errorCode = HTError.getErrorCode(type)
        self.errorMessage = HTError.getErrorMessage(type)
        self.displayErrorMessage = HTError.getErrorMessage(type)
        if let data = responseData {
            if let errorMessage =  String(data: data, encoding: .utf8) {
                self.errorMessage = errorMessage
            }
        }
    }
    
    static var `default`: HTError {
        return HTError(.unknownError)
    }

    internal func toDict() -> [String: Any] {
        let dict = [
            "code": self.errorCode.rawValue ?? 0,
            "message": self.errorMessage ?? ""
            ] as [String: Any]
        return dict
    }

    public func toJson() -> String {
        let dict = self.toDict()
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)
            return jsonString ?? ""
        } catch {
            DDLogError("Error serializing object to JSON: " + error.localizedDescription)
            return ""
        }
    }

    static func getErrorCode(_ type: HTErrorType) -> HTErrorCode {
        switch type {
            /**
             Error for key not set
             */
        case HTErrorType.publishableKeyError:
            return HTErrorCode.publishableKeyError

            /**
             Error for user id not set
             */
        case HTErrorType.userIdError:
            return HTErrorCode.userIdError

            /**
             Error for location permissions
             */
        case HTErrorType.locationPermissionsError:
            return HTErrorCode.locationPermissionsError

            /**
             Error for location enabled
             */
        case HTErrorType.locationDisabledError:
            return HTErrorCode.locationDisabledError

            /**
             Invalid location error
             */
        case HTErrorType.invalidLocationError:
            return HTErrorCode.invalidLocationError

            /**
             Error while fetching ETA
             */
        case HTErrorType.invalidETAError:
            return HTErrorCode.invalidETAError

            /**
             Error for malformed json
             */
        case HTErrorType.jsonError:
            return HTErrorCode.jsonError

            /**
             Error for server errors
             */
        case HTErrorType.serverError:
            return HTErrorCode.serverError

            /**
             Error for invalid parameters
             */
        case HTErrorType.invalidParamsError:
            return HTErrorCode.invalidParamsError

            /**
             Unknown error
             */
        case HTErrorType.unknownError:
            return HTErrorCode.unknownError

        case .authorizationFailedError:
            return HTErrorCode.authorizationFailedError
        }
    }

    static func getErrorMessage(_ type: HTErrorType) -> String {
        switch type {
            /**
             Error for key not set
             */
        case HTErrorType.publishableKeyError:
            return "A publishable key has not been set"

            /**
             Error for user id not set
             */
        case HTErrorType.userIdError:
            return "A userId has not been set"

            /**
             Error for location permissions
             */
        case HTErrorType.locationPermissionsError:
            return "Location permissions are not enabled"

            /**
             Error for location enabled
             */
        case HTErrorType.locationDisabledError:
            return "Location services are not available"

            /**
             Invalid location error
             */
        case HTErrorType.invalidLocationError:
            return "Error fetching a valid Location"

            /**
             Error while fetching ETA
             */
        case HTErrorType.invalidETAError:
            return "Error while fetching eta. Please try again."

            /**
             Error for malformed json
             */
        case HTErrorType.jsonError:
            return "The server returned malformed json"

            /**
             Error for server errors
             */
        case HTErrorType.serverError:
            return "An error occurred communicating with the server"

            /**
             Error for invalid parameters
             */
        case HTErrorType.invalidParamsError:
            return "Invalid parameters supplied"

            /**
             Unknown error
             */
        case HTErrorType.unknownError:
            return "An unknown error occurred"

        case HTErrorType.authorizationFailedError:
            return "Authorization Failed. Check your publishable key."
        }
    }
}
