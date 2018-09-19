
//
//  HTActivitySensorHelper.swift
//  HyperTrack
//
//  Created by ravi on 10/26/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

typealias HTActivityResultHandler = (_ activity: HTSDKActivity?) -> Void

class HTActivitySensorHelper: NSObject {

    let driveConfirmationDuration = 60.0
    let driveAccelerometerFrequency = 0.1
    let driveMovementValue = 50.0
    let driveNumOfSensorPoints = 500
    
    
    let walkConfirmationDuration = 20.0
    let walkAccelerometerFrequency = 0.1
    let walkMovementValue = 40.0
    let walkNumOfSensorPoints = 50

    let automotiveSensorHelper = HTDeviceSensorsDataHelper()
    let otherSensorHelper = HTDeviceSensorsDataHelper()

    
    func confirmDriveUsingSensors(resultHandler: @escaping HTActivityResultHandler){
        if automotiveSensorHelper.isGivingUpdateBasedOnDuration == false {
            automotiveSensorHelper.getAccelerometerUpdates(forDuration: driveConfirmationDuration, frequency: driveAccelerometerFrequency, withHandler: { (historicMotion, error) in
                if error != nil {
                    resultHandler(nil)
                    return
                }
                
                let movement = self.mostRecentMovementOverall(historicMotion: historicMotion, numberOfHistoricPoints: self.driveNumOfSensorPoints)
                if movement > self.driveMovementValue {
                    let sdkActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: HTActivityType.drive, startTime:Date())
                        resultHandler(sdkActivity)
                        return
                }else{
                    resultHandler(nil)
                    return
                }
            })
        }else{
            resultHandler(nil)
        }
    }
    
    func confirmWalkOrStopUsingSensors(resultHandler: @escaping HTActivityResultHandler){
        if otherSensorHelper.isGivingUpdateBasedOnDuration == false {
            otherSensorHelper.getAccelerometerUpdates(forDuration: walkConfirmationDuration, frequency: walkAccelerometerFrequency, withHandler: { (historicMotion, error) in
                if error != nil {
                    resultHandler(nil)
                    return
                }

                self.otherSensorHelper.getGyroUpdates(onlyOnce: true, withHandler: { (gyroData, error) in
                    if error != nil {
                        resultHandler(nil)
                        return
                    }
                    var historicOrientation = [String: [Double]]()
                    historicOrientation["x"] = [Double]()
                    historicOrientation["y"] = [Double]()
                    historicOrientation["z"] = [Double]()
                    
                    historicOrientation["x"]?.append((gyroData?.rotationRate.x)!)
                    historicOrientation["y"]?.append((gyroData?.rotationRate.y)!)
                    historicOrientation["z"]?.append((gyroData?.rotationRate.z)!)
                    
                    let activityType =  self.getActivityFromSensors(historicMotion: historicMotion, historicOrientation: historicOrientation)
                    if activityType != HTActivityType.unknown{
                        let sdkActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: activityType, startTime:Date())
                        resultHandler(sdkActivity)
                        return
                    }else{
                        resultHandler(nil)
                        return
                    }
                })
            })
        }else{
            resultHandler(nil)
        }
    }
    
    
    func getActivityFromSensors(historicMotion: [String: [Double]], historicOrientation: [String: [Double]]) -> HTActivityType {
        
        var activity = HTActivityType.unknown
        let movement = mostRecentMovementOverall(historicMotion: historicMotion, numberOfHistoricPoints: walkNumOfSensorPoints)
//        DDLogInfo("movement in \(walkNumOfSensorPoints.description) points :" +  movement.description)
        
        if (historicOrientation["z"]?.last!)! > Double(70.0) || (historicOrientation["z"]?.last!)! < Double(-70.0) {
            activity = HTActivityType.stop
        } else if (historicOrientation["y"]?.last)! > 160.0 || (historicOrientation["y"]?.last)! < -160.0 {
            activity = HTActivityType.stop
        } else if (historicOrientation["y"]?.last)! >= 30 && (historicOrientation["y"]?.last)! < 70 {
            if movement > walkMovementValue {
                activity = HTActivityType.walk
            } else {
                activity = HTActivityType.stop
            }
        } else if (historicOrientation["y"]?.last)! >= 70.0 && (historicOrientation["y"]?.last)! < 95.0 {
            if movement > walkMovementValue {
                activity = HTActivityType.walk
            } else {
                activity = HTActivityType.stop
            }
        } else if (historicOrientation["y"]?.last)! >= 95 && (historicOrientation["y"]?.last)! < 120 {
            activity = HTActivityType.stop
        } else if round((historicOrientation["z"]?.last)!) == 0 && round((historicOrientation["y"]?.last)!) == 0 {
            activity = HTActivityType.stop
        } else {
            if movement > walkMovementValue {
                activity = HTActivityType.walk
            } else {
                activity = HTActivityType.stop
            }
        }
        
        return activity
    }
    
    func mostRecentMovementOverall(historicMotion: [String: [Double]], numberOfHistoricPoints: Int) -> Double {
        return (mostRecentMovement(historicMotion["x"]!, numberOfHistoricPoints, true) +
            mostRecentMovement(historicMotion["y"]!, numberOfHistoricPoints, true) +
            mostRecentMovement(historicMotion["z"]!, numberOfHistoricPoints, true)) / 3.0
    }
    
    func mostRecentMovement(_  array: [Double], _ numberOfHistoricPoints: Int, _ removeNegatives: Bool) -> Double {
        
        if array.count > numberOfHistoricPoints {
            var totalSum = 0.0
            for toCount in 0 ..< numberOfHistoricPoints {
                var currentElement = array[array.count - toCount - 1]
                currentElement *= Double( (1 - toCount / numberOfHistoricPoints)) // weight the most recent data more
                if currentElement < 0 && removeNegatives {
                    currentElement  *= -1
                }
                
                if currentElement > 0.1 || currentElement < -0.1 {
                    totalSum += currentElement
                }
            }
            return totalSum * 100.0 / Double(numberOfHistoricPoints)
        }
        return 0 // not enough data yet
        
    }

}
