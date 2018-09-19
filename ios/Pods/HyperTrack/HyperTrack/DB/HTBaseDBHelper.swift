//
//  HTBaseDBHelper.swift
//  HyperTrack
//
//  Created by ravi on 10/30/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import SQLite


class HTBaseDBHelper: NSObject {
    
    weak var db: Connection?
    
    public init(connection: Connection){
        self.db = connection
    }
}
