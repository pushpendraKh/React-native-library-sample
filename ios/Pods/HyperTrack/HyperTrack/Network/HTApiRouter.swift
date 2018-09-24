//
//  HTApiRouter.swift
//  HyperTrack
//
//  Created by Atul Manwar on 27/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import Alamofire
import CocoaLumberjack

enum HTApiRouter {
    /// Action APIs
    case getAction(id: String)
    case getActionsByShortCode(shortCode: String)
    case getActionsByIds(ids: [String])
    case getActionsByShortCodes(codes: [String])
    case getActionsByUniqueId(uniqueId: String)
    case getActionsByCollectionId(collectionId: String)
    case createAction(params: HTPayload)
    case assignActions(userId: String, params: HTPayload)
    case patchAction(id: String, params: HTPayload)
    case completeAction(id: String, params: HTPayload)
    case completeActionWithUniqueId(uniqueId: String, params: HTPayload)
    case cancelActions(userId: String)
    case editDestination(collectionId: String, params: HTPayload)
    /// Track Action APIs
    case trackAction(id: String)
    case trackActionsByShortCode(shortCode: String)
    case trackActionsByIds(ids: [String])
    case trackActionsByShortCodes(codes: [String])
    case trackActionsByUniqueId(uniqueId: String)
    case trackActionsByCollectionId(collectionId: String)
    /// User APIs
    case getUser(id: String)
    case createUser(params: HTPayload)
    case updateUser(id: String, params: HTPayload)
    case registerDeviceToken(userId: String, deviceId: String, registrationId: String)
    case placeline(userId: String, date: String)
    case getSdkControls(userId: String)
    case getPendingActions(userId: String)
    /// Places APIs
    case autocompletePlaces(query: String, lat: Double, lng: Double)
    case createPlace(place: HTPayload)
    /// Simulate
    case simulatePolyline(origin: String, destination: String?)
}

extension HTApiRouter {
    static var baseUrlString: String { return "https://api.hypertrack.com" }
    
    var baseURL: URL { return URL(string: "\(HTApiRouter.baseUrlString)/api")! }
    
    private var actionPath: String {
        return "/v2/actions"
    }
    
    private var userPath: String {
        return "/v2/users"
    }
    
    private var placesPath: String {
        return "/v1/places"
    }
    
    private var simulatePath: String {
        return "/v1/simulate"
    }
    
    private var sdkVersion: String {
        return Settings.sdkVersion
    }
    
    private var osVersion: String {
        return UIDevice.current.systemVersion
        
    }
    
    private var appId: String {
        return Bundle.main.bundleIdentifier ?? ""
    }
    
    private var deviceId: String {
        return Settings.deviceId
    }
    
    private var publishableKey: String {
        return Settings.getPublishableKey() ?? ""
    }
    
    var path: String {
        switch self {
        case .getAction(let id):
            return "\(actionPath)/\(id)"
        case .getActionsByIds: fallthrough
        case .getActionsByShortCodes: fallthrough
        case .getActionsByUniqueId: fallthrough
        case .getActionsByCollectionId: fallthrough
        case .getActionsByShortCode: fallthrough
        case .createAction:
            return actionPath
        case .trackAction: fallthrough
        case .trackActionsByShortCode: fallthrough
        case .trackActionsByIds: fallthrough
        case .trackActionsByShortCodes: fallthrough
        case .trackActionsByUniqueId: fallthrough
        case .trackActionsByCollectionId:
            return "\(actionPath)/track"
        case .assignActions(let userId, _):
            return "\(userPath)/\(userId)/assign_actions"
        case .patchAction(let id, _):
            return "\(actionPath)/\(id)"
        case .completeAction(let id, _):
            return "\(actionPath)/\(id)/complete"
        case .completeActionWithUniqueId(_, _):
            return "\(actionPath)/complete"
        case .getUser: fallthrough
        case .createUser:
            return "\(userPath)/get_or_create"
        case .updateUser(let userId, _):
            return "\(userPath)/\(userId)"
        case .cancelActions(let userId):
            return "\(userPath)/\(userId)/cancel_actions"
        case .registerDeviceToken:
            return "/v1/apnsdevices"
        case .getSdkControls(let userId):
            return "\(userPath)/\(userId)/controls"
        case .placeline(let userId, _):
            return "\(userPath)/\(userId)/placeline"
        case .getPendingActions(let userId):
            return "\(userPath)/\(userId)/actions"
        case .editDestination:
            return "\(actionPath)/edit_destination"
        case .autocompletePlaces:
            return "\(placesPath)/search"
        case .createPlace:
            return placesPath
        case .simulatePolyline:
            return simulatePath
        }
    }
    var parameters: HTPayload {
        switch self {
        case .getActionsByShortCode(let shortCode):
            return ["short_code": shortCode]
        case .getActionsByIds(let ids):
            return ["id": ids.joined(separator: ",")]
        case .getActionsByShortCodes(let codes):
            return ["short_code": codes.joined(separator: ",")]
        case .getActionsByUniqueId(let uniqueId):
            return ["unique_id": uniqueId]
        case .getActionsByCollectionId(let collectionId):
            return ["collection_id": collectionId]
        case .createAction(let params):
            return params
        case .trackAction(let id):
            return ["id": id]
        case .trackActionsByShortCode(let shortCode):
            return ["short_code": shortCode]
        case .trackActionsByIds(let ids):
            return ["id": ids.joined(separator: ",")]
        case .trackActionsByShortCodes(let codes):
            return ["short_code": codes.joined(separator: ",")]
        case .trackActionsByUniqueId(let uniqueId):
            return ["unique_id": uniqueId]
        case .trackActionsByCollectionId(let collectionId):
            return ["collection_id": collectionId]
        case .assignActions(_, let params):
            return params
        case .patchAction(_, let params):
            return params
        case .completeAction(_, let params):
            return params
        case .completeActionWithUniqueId(_, let params):
            return params
        case .createUser(let params):
            return params
        case .getUser(let id):
            return ["id": id]
        case .updateUser(_, let params):
            return params
        case .registerDeviceToken(let userId, let deviceId, let registrationId):
            return ["user_id": userId, "device_id": deviceId, "registration_id": registrationId]
        case .placeline( _ , let date):
            return ["date": date]
        case .editDestination(_, let params):
            return params
        case .autocompletePlaces(let query, let lat, let lng):
            return ["q": query, "lat": lat, "lon": lng]
        case .createPlace(let place):
            return ["location": place]
        case .simulatePolyline(let origin, let destination):
            return ["origin" : origin, "destination": destination ?? ""]
        default:
            return [:]
        }
    }
    var encoding: Alamofire.ParameterEncoding {
        switch self {
        case .editDestination: fallthrough
        case .createAction: fallthrough
        case .assignActions: fallthrough
        case .patchAction: fallthrough
        case .completeAction: fallthrough
        case .completeActionWithUniqueId: fallthrough
        case .createUser: fallthrough
        case .getUser: fallthrough
        case .updateUser: fallthrough
        case .cancelActions: fallthrough
        case .createPlace: fallthrough
        case .registerDeviceToken:
            return GZippedJSONEncoding.default
        default:
            return URLEncoding.default
        }
    }
    var method: Alamofire.HTTPMethod {
        switch self {
        case .patchAction: fallthrough
        case .updateUser:
            return .patch
        case .assignActions: fallthrough
        case .createAction: fallthrough
        case .completeAction: fallthrough
        case .completeActionWithUniqueId: fallthrough
        case .createUser: fallthrough
        case .getUser: fallthrough
        case .cancelActions: fallthrough
        case .editDestination: fallthrough
        case .createPlace: fallthrough
        case .registerDeviceToken:
            return .post
        default:
            return .get
        }
    }
    
    var headers: [String: String] {
        return [
            "Authorization": "token \(publishableKey)",
            "Content-Type": "application/json",
            "User-Agent": "HyperTrack iOS SDK/\(sdkVersion) (\(osVersion))",
            "App-ID": "\(appId )",
            "Device-ID": deviceId,
            "Timezone": TimeZone.current.identifier
        ]
    }
    
    func url() -> String {
        var urlString = baseURL.appendingPathComponent(path).absoluteString + "/"
        switch self {
        case .editDestination(let collectionId, _):
            urlString += "?action_collection_id=\(collectionId)"
        case .completeActionWithUniqueId(let uniqueId, _):
            urlString += "?unique_id=\(uniqueId)"
        default:
            break
        }
        return urlString
    }
    
    func makeRequest(completionHandler: @escaping (DataResponse<Any>) -> Void) {
        let request = Alamofire.request(
                        url(),
                        method: method,
                        parameters: parameters,
                        encoding: encoding,
                        headers: headers
                    )
        guard !publishableKey.isEmpty else {
            completionHandler(DataResponse<Any>(request: request.request, response: nil, data: nil, result: Result<Any>.failure(HTError(HTErrorType.publishableKeyError))))
            return
        }
        request
            .validate()
            .responseJSON(completionHandler: completionHandler)
    }
    
    static func downloadImage(urlString: String, completionHandler: @escaping (_ image: UIImage?) -> Void) {
        Alamofire.request(urlString).responseData { (response) in
            switch response.result {
            case .success(let data):
                completionHandler(UIImage(data: data))
            case .failure(_):
                completionHandler(nil)
            }
        }
    }
}

//extension HTApiRouter: URLRequestConvertible {
//    public func asURLRequest() throws -> URLRequest {
//        let request = URLRequest(url: url())
//        request.allHTTPHeaderFields = headers
//        request.httpMethod = method.rawValue
//        return request
//    }
//}

extension DataResponse where Value: Any {
    func mapToArray<T: HTModelProtocol>() -> ([T]?, HTError?) {
        switch result {
        case .success:
            guard let data = data, let dict = data.toDict(), let array = dict[T.arrayKey] as? [HTPayload] else {
                return (nil, getHTError())
            }
            return (array.flatMap({ T(dict: $0) }), nil)
        case .failure(let error):
            return (nil, getHTError(error))
        }
    }
    
    func mapToModel<T: HTModelProtocol>() -> (T?, HTError?) {
        switch result {
        case .success:
            guard let dict = data?.toDict() else {
                return (nil, getHTError())
            }
            return (T(dict: dict), nil)
        case .failure(let error):
            return (nil, getHTError(error))
        }
    }
    
    func mapToModel<T: HTModelProtocol>(dict: HTPayload) -> (T?, HTError?) {
        return (T(dict: dict), nil)
    }
    
    fileprivate func getHTError(_ error: Error? = nil) -> HTError {
        if let error = error as? HTError {
            DDLogError("Error while \(request?.url?.description ?? "") : \(error.errorMessage)")
            return error
        } else if response?.statusCode == 403 {
            // handle auth error
            let htError = HTError(HTErrorType.authorizationFailedError)
            DDLogError("Error while \(request?.url?.description ?? "") : \(htError.errorMessage)")
            return htError
        } else {
            let htError = HTError(HTErrorType.serverError, responseData: data)
            DDLogError("Error while \(request?.url?.description ?? "") : \(htError.errorMessage)")
            return htError
        }
    }
}
