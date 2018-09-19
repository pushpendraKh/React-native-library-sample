//
//  HTDatabaseService.swift
//  HyperTrack
//
//  Created by ravi on 10/27/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import SQLite
import CoreLocation
import CocoaLumberjack

enum HTDataAccessError: Error {
    case Datastore_Connection_Error
    case Insert_Error
    case Delete_Error
    case Search_Error
    case Nil_In_Data
}

class HTDatabaseService: NSObject {
    let dbName = "hypertrackV4DB.sqlite3"
    
    var path: String
    var db: Connection?
    var activityDBHelper: HTActivityDBHelper? = nil
    var healthDBHelper: HTHealthDBHelper? = nil
    var locationDBHelper: HTLocationDBHelper? = nil
    var eventsDBHelper: HTSDKEventsDBHelper? = nil
    static let sharedInstance = HTDatabaseService()

    override init() {
        self.path = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory, .userDomainMask, true
            ).first! + "/" + (Bundle.main.bundleIdentifier ?? "com.hypertrack.HyperTrack")
        super.init()
        self.createDBAndInitializeHelper()
    }
    
    func createDBAndInitializeHelper(){
        do {
            try FileManager.default.createDirectory(
                atPath: path, withIntermediateDirectories: true, attributes: nil
            )
            self.db = try Connection("\(path)/\(dbName)")
        } catch {
            DDLogError("Error connecting to db: " + error.localizedDescription)
            self.db = nil
        }
        
        if let connection = self.db {
            self.activityDBHelper = HTActivityDBHelper.init(connection: connection)
            self.healthDBHelper = HTHealthDBHelper.init(connection: connection)
            self.locationDBHelper = HTLocationDBHelper.init(connection: connection)
            self.eventsDBHelper = HTSDKEventsDBHelper.init(connection: connection)
        }
    }
    
    
    public static func deleteDB(){
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .applicationSupportDirectory, .userDomainMask, true
                ).first! + "/" + (Bundle.main.bundleIdentifier ?? "com.hypertrack.HyperTrack")

            try  FileManager.default.removeItem(atPath: path)
            
        } catch {
            DDLogError("Error deleting db: " + error.localizedDescription)
        }
    }
}
