//
//  HTLocationDBHelper.swift
//  HyperTrack
//
//  Created by ravi on 10/27/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import SQLite
import CocoaLumberjack
import CoreLocation

class HTLocationDBHelper: HTBaseDBHelper {
    
    static let locationTableName = "locations"
    let table = Table(locationTableName)
    let lookUpId = Expression<String>("lookup_id")
    let latitude = Expression<Double>("latitude")
    let longitude =  Expression<Double>("longitude")
    let speed = Expression<Double?>("speed")
    let altitude = Expression<Double?>("altitude")
    let recordedAt =  Expression<Date>("recorded_at")
    let activityLookUpId = Expression<String>("activity_lookup_id")
    let horizontalAccuracy = Expression<Double?>("horizontal_accuracy")
    let verticalAccuracy = Expression<Double?>("vertical_accuracy")
    let bearing = Expression<Double?>("bearing")
    let uploadDate = Expression<Date?>("upload_date")

    override init(connection: Connection) {
        super.init(connection: connection)
    }
    
    func createTable() throws {
        guard let db = self.db else {
            throw HTDataAccessError.Datastore_Connection_Error
        }
        
        do {
            let _ = try db.run( table.create(ifNotExists: true) {locations in
                locations.column(lookUpId)
                locations.column(latitude)
                locations.column(longitude)
                locations.column(speed)
                locations.column(altitude)
                locations.column(recordedAt)
                locations.column(activityLookUpId)
                locations.column(horizontalAccuracy)
                locations.column(verticalAccuracy)
                locations.column(bearing)
                locations.column(uploadDate)
            })
            
        } catch _ {
            DDLogError("Error creating locations table")
        }
    }
    
    func insert(htLocation: HTLocation){
        do {
            try self.db?.run(table.insert(
                                         lookUpId <- htLocation.lookUpId ?? "",
                                         latitude <- htLocation.clLocation.coordinate.latitude,
                                         longitude <- htLocation.clLocation.coordinate.longitude,
                                         speed <- htLocation.speed,
                                         altitude <- htLocation.altitude,
                                         bearing <- htLocation.bearing,
                                         recordedAt <- htLocation.recordedAt,
                                         activityLookUpId <- htLocation.activityLookUpId,
                                         horizontalAccuracy <- htLocation.horizontalAccuracy,
                                         verticalAccuracy <- htLocation.verticalAccuracy))
            return
        } catch {
            DDLogError("Error inserting location to db")
            return
        }
    }
    
    func getLocationFromLookUpId(lookUpId: String) -> HTLocation?{
        let queryFilter = (self.lookUpId == lookUpId)
        
        let query = table.filter(queryFilter)
        var location: HTLocation?
        do {
            let queryResult = try self.db?.prepare(query)
            
            if let result = queryResult {
                for locationResult in result {
                    let latitude = locationResult[self.latitude]
                    let longitude =  locationResult[self.longitude]
                    let speed = locationResult[self.speed]
                    let altitude = locationResult[self.altitude] ?? 0.0
                    let recordedAt = locationResult[self.recordedAt]
                    let activityLookUpId = locationResult[self.activityLookUpId]
                    let horizontalAccuracy = locationResult[self.horizontalAccuracy] ?? 0.0
                    let verticalAccuracy = locationResult[self.verticalAccuracy] ?? 0.0
                    let bearing = locationResult[self.bearing] ?? 0.0
                    let uploadDate = locationResult[self.uploadDate]
                    
                    let clLocation = CLLocation(coordinate: CLLocationCoordinate2D.init(latitude: latitude, longitude: longitude), altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: bearing
                        , speed: speed!, timestamp: recordedAt)
                    
                    location = HTLocation.init(clLocation: clLocation, locationType: "point", activityLookUpId: activityLookUpId, provider: "gps")
                    location?.lookUpId = lookUpId
                    location!.uploadTime = uploadDate
                    break;
                }
            }
        } catch {
            DDLogError("Error getting events from db: " + error.localizedDescription)
            return location
        }
        
        return location
    }
}
