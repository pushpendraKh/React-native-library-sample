//
//  HTCriticalErrorLogger.swift
//  HyperTrack
//
//  Created by ravi on 11/22/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
//import Sentry
import CocoaLumberjack
class HTCriticalErrorLogger: NSObject {

    public static func log(message: String){
        DDLogError(message)
//
//        let user = User(userId: HTUserService.sharedInstance.userId ?? "")
//        Client.shared?.user = user
//
//        Client.shared?.tags = ["iphone": "true"]
//
//        let event = Event(level: .error)
//        event.message = message
//        event.environment = "production"
//        event.extra = ["ios": true]
//        Client.shared?.send(event: event)
    }
    
    public static func log(message: String, otherInfo: String){
        DDLogError(message)
        DDLogError(otherInfo)
//        let user = User(userId: HTUserService.sharedInstance.userId ?? "")
//        Client.shared?.user = user
//
//        Client.shared?.tags = ["iphone": "true"]
//
//        let event = Event(level: .error)
//        event.message = message
//        event.environment = "production"
//        event.extra = ["ios": true, "otherInfo": otherInfo]
//        Client.shared?.send(event: event)
    }
}
