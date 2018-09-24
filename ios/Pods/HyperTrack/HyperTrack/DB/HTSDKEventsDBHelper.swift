//
//  HTSDKEventsDBHelper.swift
//  HyperTrack
//
//  Created by ravi on 11/13/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import SQLite
import CocoaLumberjack

class HTSDKEventsDBHelper: HTBaseDBHelper {

    static let eventTableName = "sdk_events"

    let events = Table("sdk_events")

    let eventId = Expression<Int64>("id")
    let userId = Expression<String>("user_id")
    let sessionId = Expression<String>("session_id")
    let deviceId = Expression<String>("device_id")
    let recordedAt = Expression<Date>("recorded_at")
    let eventType = Expression<String>("type")
    let activityLookUpId = Expression<String>("activity_lookup_id")
    let healthLookUpId = Expression<String>("health_lookup_id")
    let locationLookUpId = Expression<String>("location_lookup_id")
    let data = Expression<Data>("data")
    
    override init(connection: Connection) {
        super.init(connection: connection)
    }
    
    
    func createTable() throws {
        guard let db = self.db else {
            throw HTDataAccessError.Datastore_Connection_Error
        }
        
        do {
            DDLogInfo("Creating events table")
            try db.run(events.create(ifNotExists: true) { event in
                event.column(eventId, primaryKey: true)
                event.column(userId)
                event.column(sessionId)
                event.column(deviceId)
                event.column(eventType)
                event.column(activityLookUpId)
                event.column(healthLookUpId)
                event.column(locationLookUpId)
                event.column(data)
                event.column(recordedAt)
            })
        } catch {
            DDLogError("Error creating events table: " + error.localizedDescription)
        }
    }
    
    func insert(event: HyperTrackEvent) {
        do {
            guard let trackingStartedDate = Settings.trackingStartedAt else {
                return
            }
            
            if trackingStartedDate.timeIntervalSince1970 < event.recordedAt.timeIntervalSince1970{
                let jsonData = try JSONSerialization.data(withJSONObject: event.data)
                try db?.run(events.insert(userId <- event.userId,
                                          sessionId <- event.sessionId,
                                          deviceId <- event.deviceId,
                                          eventType <- event.eventType.rawValue,
                                          activityLookUpId <- event.activityLookUpId,
                                          healthLookUpId <- event.healthLookUpId,
                                          locationLookUpId <- event.locationLookUpId,
                                          data <- jsonData,
                                          recordedAt <- event.recordedAt))
            }else{
                DDLogError("Discarding event since it is recorded before tracking started")
            }
 
         } catch {
            DDLogError("Error inserting event to db: " + error.localizedDescription)
        }
    }
    
    func getEvents() -> [HyperTrackEvent] {
        let query = events.order(recordedAt.asc)
        var eventsArray:  [HyperTrackEvent] = [HyperTrackEvent]()

        do {
            let queryResult = try self.db?.prepare(query)

            if let result = queryResult {
                for dbEvent in result {
                    let eventId = dbEvent[self.eventId]
                    let userId = dbEvent[self.userId]
                    let sessionId = dbEvent[self.sessionId]
                    let deviceId = dbEvent[self.deviceId]
                    let activityLookUpId = dbEvent[self.activityLookUpId]
                    let healthLookUpId = dbEvent[self.healthLookUpId]
                    let locationLookUpId = dbEvent[self.locationLookUpId]
                    let recordedAt = dbEvent[self.recordedAt]
                    let eventType = dbEvent[self.eventType]
                    let jsonData = dbEvent[self.data]
                    
                    let data = try JSONSerialization.jsonObject(with: jsonData, options: [])

                    if let type = HyperTrackEventType(rawValue:eventType) {
                        let event = HyperTrackEvent.init(userId: userId, sessionId: sessionId, deviceId: deviceId, recordedAt: recordedAt, eventType: type , activityLookUpId: activityLookUpId, locationLookUpId: locationLookUpId, healthLookUpId: healthLookUpId, data: data as? [String : Any] ?? [:])
                        
                        event.id = eventId
                        eventsArray.append(event)
                    }
                }
            }
        } catch {
            DDLogError("Error getting events from db: " + error.localizedDescription)
            return eventsArray
        }
        
        return eventsArray
    }
    
    func deleteAll() {
        do {
            try db?.run(events.delete())
        } catch {
            DDLogError("Error deleting all events from db: " + error.localizedDescription)
        }
    }
    
    func bulkDelete(ids: [Int64]) {
        let toDeleteEvents = events.filter(ids.contains(eventId))
        do {
            try db?.run(toDeleteEvents.delete())
        } catch {
            DDLogError("Error deleting events from db: " + error.localizedDescription)
        }
    }
   
}
