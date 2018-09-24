//
//  HTNetworkRequest.swift
//  HyperTrack
//
//  Created by ravi on 11/15/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import Alamofire

class HTNetworkRequest: NSObject {

    var arrayParams: [Any]?
    var jsonParams: [String: Any]?
    var urlParams: [String: String]?
    let method: HTTPMethod
    var headers: [String: String]
    let urlPath: String
    let baseURL: String = "\(HTApiRouter.baseUrlString)/api"
    let sdkVersion: String = Settings.sdkVersion
    let osVersion: String = UIDevice.current.systemVersion
    let appId: String = Bundle.main.bundleIdentifier ?? ""
    let deviceId: String = Settings.deviceId
    
    init(method: HTTPMethod, urlPath: String, jsonParams: [String: Any]) {
        self.jsonParams = jsonParams
        self.method = method
        self.urlPath = urlPath
        
        let publishableKey = Settings.getPublishableKey()! as String
        self.headers = [
            "Authorization": "token \(publishableKey)",
            "Content-Type": "application/json",
            "User-Agent": "HyperTrack iOS SDK/\(sdkVersion) (\(osVersion))",
            "App-ID": "\(appId )",
            "Device-ID": "\(deviceId)",
            "Timezone": TimeZone.current.identifier
        ]
    }
    
    init(method: HTTPMethod, urlPath: String, arrayParams: [Any]) {
        self.arrayParams = arrayParams
        self.method = method
        self.urlPath = urlPath
        
        let publishableKey = Settings.getPublishableKey()! as String
        self.headers = [
            "Authorization": "token \(publishableKey)",
            "Content-Type": "application/json",
            "User-Agent": "HyperTrack iOS SDK/\(sdkVersion) (\(osVersion))",
            "App-ID": "\(appId )",
            "Device-ID": deviceId,
            "Timezone": TimeZone.current.identifier
        ]
    }
    
    init(method: HTTPMethod, urlPath: String, urlParams: [String: String]) {
        self.urlParams = urlParams
        self.method = method
        self.urlPath = urlPath
        
        let publishableKey = Settings.getPublishableKey()! as String
        self.headers = [
            "Authorization": "token \(publishableKey)",
            "Content-Type": "application/json",
            "User-Agent": "HyperTrack iOS SDK/\(sdkVersion) (\(osVersion))",
            "App-ID": "\(appId )",
            "Device-ID": deviceId,
            "Timezone": TimeZone.current.identifier
        ]
    }
    
    func buildURL() -> String {
        return self.baseURL + self.urlPath
    }
    
    func makeRequest(completionHandler: @escaping (DataResponse<Any>) -> Void) {
        if let array = self.arrayParams {
            Alamofire.request(
                self.buildURL(),
                method: self.method,
                parameters: ["array": array],
                encoding: GZippedJSONArrayEncoding.default,
                headers: self.headers
                ).validate().responseJSON(completionHandler: completionHandler)
        } else if let json = self.jsonParams {
            Alamofire.request(
                self.buildURL(),
                method: self.method,
                parameters: json,
                encoding: GZippedJSONEncoding
                    .default,
                headers: self.headers
                ).validate().responseJSON(completionHandler: completionHandler)
        }
    }
}
