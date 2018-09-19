

//
//  HTEncodings.swift
//  HyperTrack
//
//  Created by ravi on 11/15/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import Alamofire
import Gzip
import CocoaLumberjack


struct JSONArrayEncoding: ParameterEncoding {
    /// Returns a `JSONArrayEncoding` instance with default writing options.
    public static var `default`: JSONArrayEncoding { return JSONArrayEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = urlRequest.urlRequest
        let array = parameters?["array"]
        
        let data = try JSONSerialization.data(withJSONObject: array as! [Any], options: [])
        
        if urlRequest?.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest?.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        urlRequest?.httpBody = data
        
        return urlRequest!
    }
}

struct GZippedJSONEncoding: ParameterEncoding {
    public static var `default`: GZippedJSONEncoding { return GZippedJSONEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var encodedRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        encodedRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        encodedRequest.httpBody = try encodedRequest.httpBody?.gzipped()
        return encodedRequest
    }
}

struct GZippedJSONArrayEncoding: ParameterEncoding {
    public static var `default`: GZippedJSONArrayEncoding { return GZippedJSONArrayEncoding() }
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var encodedRequest = try JSONArrayEncoding.default.encode(urlRequest, with: parameters)
        encodedRequest.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
        encodedRequest.httpBody = try encodedRequest.httpBody?.gzipped()
        return encodedRequest
    }
}
