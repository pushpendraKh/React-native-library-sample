//
//  HTHealthDBHelper.swift
//  HyperTrack
//
//  Created by ravi on 10/27/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import SQLite
import CocoaLumberjack

class HTHealthDBHelper: HTBaseDBHelper {
    
    static let healthTableName = "health"
    
    let table = Table(healthTableName)
    let lookUpId = Expression<String>("lookup_id")
    let sessionId = Expression<String>("session_id")
    let deviceId = Expression<String>("device_id")
    let recordedAt = Expression<Date>("recorded_at")
    let startTime = Expression<Date>("start_time")
    let endTime = Expression<Date?>("end_time")
    let type = Expression<String>("type")
    let data = Expression<Data>("data")
    let uploadDate = Expression<Date?>("upload_date")
    
    override init(connection: Connection) {
        super.init(connection: connection)
    }
    
    func createTable() throws {
        guard let db = self.db else {
            throw HTDataAccessError.Datastore_Connection_Error
        }
        
        do {
            let _ = try db.run( table.create(ifNotExists: true) {t in
                t.column(lookUpId, primaryKey: true)
                t.column(sessionId)
                t.column(deviceId)
                t.column(recordedAt)
                t.column(startTime)
                t.column(endTime)
                t.column(type)
                t.column(data)
                t.column(uploadDate)
            })
            
        } catch _ {
            DDLogError("Error creating health table")
        }
    }
    
    func insert(health: HTSDKHealth){
        do {
            try self.db?.run(table.insert( lookUpId <- health.lookupId,
                                           sessionId <- health.sessionId,
                                           deviceId <- health.deviceId,
                                           recordedAt <- health.recordedAt,
                                           startTime <- health.startTime ?? Date(),
                                           endTime <- health.endTime,
                                           type <- health.type.rawValue,
                                           data <- health.healthData.getJsonData()
            ))
            return
        } catch {
            DDLogError("Error inserting health to db")
            return
        }
    }
    
    func delete(health: HTSDKHealth){
        do {
            let dbHealth = table.filter(lookUpId == health.lookupId)
            try db?.run(
                dbHealth.delete()
            )
            
        } catch {
            DDLogError("Error inserting update to db: " + error.localizedDescription)
        }
    }
    
    func getHealthForLookUpId(lookupId: String) -> HTSDKHealth? {
        let queryFilter = (self.lookUpId == lookupId)
        
        let query = table.filter(queryFilter)
        var health: HTSDKHealth?
        do {
            let queryResult = try self.db?.prepare(query)
            
            if let result = queryResult {
                for dbHealthSegment in result {
                    let lookUpId = dbHealthSegment[self.lookUpId]
                    let startTime = dbHealthSegment[self.startTime]
                    let endTime = dbHealthSegment[self.endTime]
                    let deviceId = dbHealthSegment[self.deviceId]
                    let sessionId = dbHealthSegment[self.sessionId]
                    let recordedAt = dbHealthSegment[self.recordedAt]
                    let type = dbHealthSegment[self.type]
                    let data = dbHealthSegment[self.data]
                    
                    if let type = HTSDKHealthType(rawValue: type){
                        if let healthData = HTSDKHealth.getHealthData(data: data, type: type) {
                            health =  HTSDKHealth.init(lookupId: lookUpId, type: type, healthData: healthData)
                            
                            health!.startTime = startTime
                            health!.endTime = endTime
                            health!.sessionId = sessionId
                            health!.deviceId = deviceId
                            health!.recordedAt = recordedAt
                            break;
                        }
                    }
                }
            }
        } catch {
            DDLogError("Error getting events from db: " + error.localizedDescription)
            return health
        }
        
        return health
    }
}
