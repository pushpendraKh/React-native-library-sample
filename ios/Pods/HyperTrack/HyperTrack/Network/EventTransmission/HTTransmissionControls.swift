//
//  HTTransmissionControls.swift
//  HyperTrack
//
//  Created by ravi on 12/12/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit

class HTTransmissionControls: NSObject {
    
    public let ttl: Double
    public let batchDuration: Double
    public let batchSize: Double
    
     init(ttl: Double, batchDuration: Double, batchSize: Double) {
        self.ttl = ttl
        self.batchDuration = batchDuration
        self.batchSize = batchSize
        super.init()
    }
}
