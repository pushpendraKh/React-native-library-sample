//
//  HTNetworkOperation.swift
//  HyperTrack
//
//  Created by ravi on 11/15/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

class HTNetworkOperation: HTBaseOperation {
    
    let events: [HyperTrackEvent]
    let maxRetryCount = 5
    var currentRetryCount = 0
    
    init(events: [HyperTrackEvent]){
        self.events = events
    }
    
    override func main() {
        guard isCancelled == false else {
            finish(true)
            return
        }
        executing(true)
        postEvents(events: events)
    }
    
    
    func postEvents(events: [HyperTrackEvent]){
        
        if currentRetryCount != 0 {
            DDLogInfo("trying the request for \(currentRetryCount)")
        }

        if currentRetryCount == maxRetryCount{
            DDLogInfo("retried the request for \(maxRetryCount), so stopping to retry")
            self.executing(false)
            self.finish(true)
            return
        }
        
        
        currentRetryCount = currentRetryCount + 1
        var eventsDict: [[String: Any]] = []
        var eventIds: [Int64] = []
        
//        DDLogInfo("posting events")
        
        for event in events {
//            DDLogInfo("posting event of type \(event.eventType.rawValue)")
            if event.eventType == .activityStarted || event.eventType == .activityEnded{
                if event.getActivity()?.lookupId == nil {
//                    DDLogInfo("recieved an event with empty activity \(event.toDict().description)")
                    continue
                }
            }
            eventsDict.append(event.toServerParams())
//            DDLogInfo("posting event: \(event.toServerParams().description)")
            eventIds.append(event.id!)
        }
        
        if eventIds.count == 0 {
            self.executing(false)
            self.finish(true)
            return
        }
        
        if HTSDKDataManager.sharedInstance.healthManager.currentRadioHealth?.networkState == HTNetworkState.disconnected{
            self.executing(false)
            self.finish(true)
            return
        }
        
        HTNetworkRequest(method: .post, urlPath: "/v1/sdk_data/bulk/", arrayParams: eventsDict).makeRequest { response in
            switch response.result {
            case .success:
                HTDatabaseService.sharedInstance.eventsDBHelper?.bulkDelete(ids: eventIds)
                DDLogInfo("Events pushed successfully: \(String(describing: eventIds.count))")
                self.executing(false)
                self.finish(true)
                
            case .failure(let error):
                DDLogError("Error while postEvents: \(String(describing: error))  with response: \(String(describing: response))")
                
                // Delete Events for 4xx errors to prevent unnecessary retries
                if (response.response != nil) && (response.response?.statusCode)! >= 400 && (response.response?.statusCode)! < 500 {
                    HTDatabaseService.sharedInstance.eventsDBHelper?.bulkDelete(ids: eventIds)
                    self.executing(false)
                    self.finish(true)
                }else {
                    DDLogInfo("retrying the payload as post events failed")
                    self.performExponentialRetry(events: events)
                }
            }
            
        }
    }
    
    func performExponentialRetry(events: [HyperTrackEvent]){
        let nextRetryDelay = pow(Double(2.7), Double(currentRetryCount))
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(nextRetryDelay), execute: {
           self.postEvents(events: events)
        })
    }

}
