//
//  HTActivityDBHelper.swift
//  HyperTrack
//
//  Created by ravi on 10/27/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import SQLite
import CocoaLumberjack

class HTActivityDBHelper: HTBaseDBHelper {

    static let activityTableName = "activities"
    
    let table = Table(activityTableName)
    let lookUpId = Expression<String>("lookup_id")
    let sessionId = Expression<String>("session_id")
    let deviceId = Expression<String>("device_id")
    let recordedAt = Expression<Date>("recorded_at")
    let startTime = Expression<Date>("start_time")
    let endTime = Expression<Date?>("end_time")
    let type = Expression<String>("type")
    let unknownReason = Expression<String>("unknown_reason")
    let dataJson = Expression<Data>("activity_json")
    let uploadDate = Expression<Date?>("upload_date")

    override init(connection: Connection) {
        super.init(connection: connection)
    }
    
    func createTable() throws {
        guard let db = self.db else {
            throw HTDataAccessError.Datastore_Connection_Error
        }
        
        do {
            let _ = try db.run( table.create(ifNotExists: true) {activity in
                activity.column(lookUpId, primaryKey: true)
                activity.column(sessionId)
                activity.column(deviceId)
                activity.column(recordedAt)
                activity.column(startTime)
                activity.column(endTime)
                activity.column(type)
                activity.column(unknownReason)
                activity.column(dataJson)
                activity.column(uploadDate)
            })
            
        } catch {
            DDLogError("Error creating activities table")
        }
    }
    
    func canSaveNewActivity(activity: HTSDKActivity) -> Bool{
        
        if self.doesActivityExistAtDate(date: activity.startTime){
            HTCriticalErrorLogger.log(message: "overlapping segment found", otherInfo:"\(activity.type) at time \(activity.startTime.description) having description: \(activity.toDict().description)")
            return false
        }
        
        if let dbActivity =  getPreviousActivities(1).first {
            if let endTime = dbActivity.endTime {
                if (activity.startTime.timeIntervalSince1970 - endTime.timeIntervalSince1970 >= 1){
                    HTCriticalErrorLogger.log(message: "segments are not continous", otherInfo:" previous activity end time: \(endTime.description) and new activity starting at time: \(activity.startTime.description) ")
                }
            }
        }
        
        return true
    }
    
    
    func insert(activity: HTSDKActivity){
        if canSaveNewActivity(activity: activity){
            do {
                try self.db?.run(table.insert( lookUpId <- activity.lookupId,
                                               sessionId <- activity.sessionId,
                                               deviceId <- activity.deviceId,
                                               recordedAt <- activity.recordedAt,
                                               startTime <- activity.startTime,
                                               endTime <- activity.endTime,
                                               type <- activity.type.rawValue,
                                               unknownReason <- (activity.unknownReason?.rawValue) ?? "",
                                               dataJson <- activity.getJsonForExtraData()
                ))
                return
            } catch {
                DDLogError("Error inserting activity to db :  \(error.localizedDescription)")
                return
            }
        }
    }
    
    func update(activity: HTSDKActivity){
        do {
            let dbActvity = table.filter(lookUpId == activity.lookupId)
            
            try db?.run(
                dbActvity.update(
                    recordedAt <- activity.recordedAt,
                    startTime <- activity.startTime,
                    endTime <- activity.endTime,
                    type <- activity.type.rawValue,
                    unknownReason <- (activity.unknownReason?.rawValue) ?? "",
                    dataJson <- activity.getJsonForExtraData()
            ))
            
        } catch {
            DDLogError("Error updating update to db: " + error.localizedDescription)
        }
    }
    
    
    
    func updateSteps(activity: HTSDKActivity){
        do {
            let dbActvity = table.filter(lookUpId == activity.lookupId)
            
            try db?.run(
                dbActvity.update(
                    recordedAt <- activity.recordedAt,
                    dataJson <- activity.getJsonForExtraData()
            ))
            
        } catch {
            DDLogError("Error updating update to db: " + error.localizedDescription)
        }
    }
    
    
    
    func delete(activity: HTSDKActivity){
        do {
            let dbActvity = table.filter(lookUpId == activity.lookupId)
            
            try db?.run(
                dbActvity.delete()
            )
            
        } catch {
            DDLogError("Error inserting update to db: " + error.localizedDescription)
        }
    }
    
    func getPreviousActivities(_ limit: Int? = 50) -> [HTSDKActivity]{
        let query = table.order(startTime.desc).limit(limit)
        var activities = [HTSDKActivity]()
        do {
            let queryResult = try self.db?.prepare(query)
            if let result = queryResult {
                for activity in result {
                    let lookUpId = activity[self.lookUpId]
                    let startTime = activity[self.startTime]
                    let type = activity[self.type]
                    let sdkActivity =  HTSDKActivity.init(lookUpId: lookUpId, type: HTActivityType(rawValue: type)!, startTime: startTime)
                    let deviceId = activity[self.deviceId]
                    let sessionId = activity[self.sessionId]
                    let recordedAt = activity[self.recordedAt]
                    let unknownReason = activity[self.unknownReason]
                    let jsonData = activity[self.dataJson]
                    sdkActivity.setJsonDataToModel(data: jsonData)
                    sdkActivity.sessionId = sessionId
                    sdkActivity.deviceId = deviceId
                    sdkActivity.recordedAt = recordedAt
                    sdkActivity.endTime = activity[self.endTime]
                    sdkActivity.unknownReason = HTUnknownActivityType(rawValue: unknownReason)
                    activities.append(sdkActivity)
                 }
            }
        } catch {
            DDLogError("Error getting activities from db: " + error.localizedDescription)
            return activities
        }
        
        return activities
    }
    
    func doesActivityExistAtDate(date: Date) -> Bool {
        let queryFilter = (self.startTime <= date) && ((self.endTime == nil) || self.endTime > date)
        let query = table.filter(queryFilter)
        var doesActivityExist = false
        do {
            let queryResult = try self.db?.prepare(query)
            if let result = queryResult {
                for _ in result {
                    doesActivityExist = true
                    break;
                }
            }
        } catch {
            DDLogError("Error getting activities from db: " + error.localizedDescription)
            return doesActivityExist
        }
        
        return doesActivityExist
    }
    
    func getActivityAtDate(date: Date) -> HTSDKActivity?{
        let queryFilter = (self.startTime <= date) && ((self.endTime == nil) || self.endTime >= date)
        let query = table.filter(queryFilter)
        var sdkActivity : HTSDKActivity? = nil
        do {
            let queryResult = try self.db?.prepare(query)
            if let result = queryResult {
                for activity in result {
                    let lookUpId = activity[self.lookUpId]
                    let startTime = activity[self.startTime]
                    let type = activity[self.type]
                    sdkActivity =  HTSDKActivity.init(lookUpId: lookUpId, type: HTActivityType(rawValue: type)!, startTime: startTime)
                    let deviceId = activity[self.deviceId]
                    let sessionId = activity[self.sessionId]
                    let recordedAt = activity[self.recordedAt]
                    let unknownReason = activity[self.unknownReason]
                    let jsonData = activity[self.dataJson]
                    sdkActivity!.setJsonDataToModel(data: jsonData)
                    sdkActivity!.sessionId = sessionId
                    sdkActivity!.deviceId = deviceId
                    sdkActivity!.recordedAt = recordedAt
                    sdkActivity!.endTime = activity[self.endTime]
                    sdkActivity!.unknownReason = HTUnknownActivityType(rawValue: unknownReason)
                    break;
                }
            }
        } catch {
            DDLogError("Error getting activities from db: " + error.localizedDescription)
            return sdkActivity
        }
        
        return sdkActivity
    }

    func getActivityFromLookUpId(lookUpId: String) -> HTSDKActivity?{
        let queryFilter = (self.lookUpId == lookUpId)
        let query = table.filter(queryFilter)
        var sdkActivity : HTSDKActivity? = nil
        do {
            let queryResult = try self.db?.prepare(query)
            if let result = queryResult {
                for activity in result {
                    let lookUpId = activity[self.lookUpId]
                    let startTime = activity[self.startTime]
                    let type = activity[self.type]
                    sdkActivity =  HTSDKActivity.init(lookUpId: lookUpId, type: HTActivityType(rawValue: type)!, startTime: startTime)
                    let deviceId = activity[self.deviceId]
                    let sessionId = activity[self.sessionId]
                    let recordedAt = activity[self.recordedAt]
                    let unknownReason = activity[self.unknownReason]
                    let jsonData = activity[self.dataJson]
                    sdkActivity!.setJsonDataToModel(data: jsonData)
                    sdkActivity!.sessionId = sessionId
                    sdkActivity!.deviceId = deviceId
                    sdkActivity!.recordedAt = recordedAt
                    sdkActivity!.endTime = activity[self.endTime]
                    sdkActivity!.unknownReason = HTUnknownActivityType(rawValue: unknownReason)
                    break;
                }
            }
        } catch {
            DDLogError("Error getting activities from db: " + error.localizedDescription)
        }
        if sdkActivity == nil {
//            DDLogError("activity is nil, not able to find in db, lookupid : \(lookUpId)")
        }
        
        
        return sdkActivity
    }
    
}
