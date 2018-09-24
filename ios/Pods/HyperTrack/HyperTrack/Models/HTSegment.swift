//
//  HTSegment.swift
//  Pods
//
//  Created by ravi on 9/13/17.
//
//

import UIKit


public enum HTSegmentType: String {
    case activity
    case health
}

@objc public class HTSegment: NSObject {
    
    public let lookupId: String
    public var sessionId =  Settings.sessionId
    public var deviceId = Settings.deviceId
    public var recordedAt: Date
    public var startTime: Date
    public var endTime: Date?
    public let segmentType: HTSegmentType
    public var uploadTime: Date?

    public  init(lookupId: String, segmentType: HTSegmentType,recordedAt: Date, startTime: Date) {
        self.lookupId = lookupId
        self.segmentType = segmentType
        self.recordedAt = recordedAt
        self.startTime = startTime
        super.init()
    }

}
