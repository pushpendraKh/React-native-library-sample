//
//  HTActivityAnalyzer.swift
//  HyperTrack
//
//  Created by ravi on 10/26/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

class HTActivityAnalyzer: NSObject {
    
    var activityWeights = [Double]()

    var lastAnalyzedTime: Date?
    let observedActivitiesCount  = 20

    let continousSegmentCountMap = [HTActivityType.walk: 4, HTActivityType.drive: 4, HTActivityType.run: 2, HTActivityType.cycle: 2, HTActivityType.stop: 4]

    
    func checkForMaxWeightActivity(activity: HTSDKActivity, recordedActivities : [HTSDKActivity]) -> HTSDKActivity? {
        
        if lastAnalyzedTime == nil {
            lastAnalyzedTime = Date()
        } else if Date().timeIntervalSince1970 - (lastAnalyzedTime?.timeIntervalSince1970)! < 15 {
            return nil
        }
        
        lastAnalyzedTime = Date()
        resetObservationStats()

        if (recordedActivities.count) > observedActivitiesCount {
            let recordedActivitiesSlice = recordedActivities.suffix(from: recordedActivities.count - observedActivitiesCount)
            let observedActivities = Array(recordedActivitiesSlice)
            
            var maxActivity = observedActivities.first
            var maxWeight = observedActivities.first?.confidence
            
            for activity in observedActivities {
                var confidence = 0.0
                if activity.type == HTActivityType.walk{
                    activityWeights[0] = activityWeights[0] + activity.confidence
                    confidence  = activityWeights[0]
                } else if activity.type == HTActivityType.run{
                    activityWeights[1] = activityWeights[1] + activity.confidence
                    confidence  = activityWeights[1]
                } else  if activity.type == HTActivityType.stop {
                    activityWeights[2] = activityWeights[2] + activity.confidence
                    confidence  = activityWeights[2]
                } else if activity.type == HTActivityType.drive{
                    activityWeights[3] = activityWeights[3] + activity.confidence
                    confidence  = activityWeights[3]
                } else if activity.type == HTActivityType.cycle{
                    activityWeights[4] = activityWeights[4] + activity.confidence
                    confidence  = activityWeights[4]
                }
                
                if confidence > maxWeight! {
                    maxWeight = confidence
                    maxActivity = activity
                }
                
                if maxActivity?.type == activity.type {
                    maxActivity = activity
                }
            }
            
            if let activity = maxActivity {
                let sdkActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: activity.type  , startTime: Date())
                
                if sdkActivity.type == activity.type {
                    return sdkActivity
                }
            }
        
            return nil
        }
        
        return nil
    }
    
    
    func confirmFromContinousSegments(recordedActivities: [HTSDKActivity], activityType: HTActivityType) -> HTSDKActivity? {
        
        if let continousSegmentCount = continousSegmentCountMap[activityType]{
            if recordedActivities.count >= continousSegmentCount{
                let recordedActivitiesSlice = recordedActivities.suffix(from: recordedActivities.count - continousSegmentCount)
                let observedActivities = Array(recordedActivitiesSlice)
                var isContinous = true
                for activity in observedActivities {
                    if activity.type != activityType {
                        isContinous = false
                        break
                    }
                }
                
                if isContinous{
                    if let activity =  observedActivities.first {
                        let sdkActivity = HTSDKActivity.init(lookUpId: UUID().uuidString, type: activity.type  , startTime: Date())
                        return sdkActivity
                    }
                    return observedActivities.first
                }
            }
        }
        
        return nil
    }
    
    func resetObservationStats() {
        activityWeights = [Double]()
        
        activityWeights.append(0.0)
        activityWeights.append(0.0)
        activityWeights.append(0.0)
        activityWeights.append(0.0)
        activityWeights.append(0.0)
    }
    
}
