//
//  HTPushNotification.swift
//  HyperTrack
//
//  Created by Arjun Attam on 27/05/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import Foundation
import CocoaLumberjack

protocol PushNotificationDelegate: class {
   func didRecieveNotificationForSDKControls()
}

class PushNotificationService {
    
    let pushNotificationTokenString = "HyperTrackDeviceToken"
    let registeredTokenString = "HyperTrackDeviceTokenRegistered"
    let requestManager = RequestManager()
    weak var delegate : PushNotificationDelegate?
    
    func registerForNotifications() {
        // Checks if user has given push notification
        // permissions to the app and saves
        // device token to settings
        let application = UIApplication.shared
        application.registerForRemoteNotifications()
    }
    
    func didRegisterForRemoteNotificationsWithDeviceToken(deviceToken: Data) {
        var token = ""
        
        for i in 0..<deviceToken.count {
            token  += String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        
        self.setDeviceToken(deviceToken: token)
        self.registerDeviceToken()
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(error: Error) {
        DDLogError("Failed to register for notification: \(String(describing: error.localizedDescription))")
    }
    
    func registerDeviceToken() {
        // Called after the user has been set, so that
        // the device can be registered on the HyperTrack server
        
        let device = UIDevice.current
        let deviceId = device.identifierForVendor?.uuidString
        var toRegister = true
        
        if let deviceToken = self.getDeviceToken(), let userId = HTUserService.sharedInstance.userId {
            if let registeredToken = self.getRegisteredToken() {
                if registeredToken == deviceToken {
                    toRegister = false
                }
            }
            
            if toRegister {
                requestManager.registerDeviceToken(userId: userId, deviceId: deviceId!, registrationId: deviceToken) { error in
                    if error == nil {
                        // Successfully registered the token
                        DDLogInfo("Device Token for user: \(userId) registered successfully: \(deviceToken)")
                        self.setRegisteredToken(deviceToken: deviceToken)
                    }else{
                        DDLogError("Device Token registrartion failed for user: \(userId) : \(deviceToken)")
                        
                    }
                }
            }
        }
    }
    
    func didReceiveRemoteNotification(userInfo: [AnyHashable: Any]) {
        if self.isHyperTrackNotification(userInfo: userInfo) {
            
            if let notificationUserId = userInfo["user_id"], let sdkUserId = HTUserService.sharedInstance.userId {
                if  let notificationUserIdString = notificationUserId as? String {
                    DDLogInfo("Received notification for user \(String(describing: notificationUserIdString))")
                    
                    if sdkUserId == notificationUserIdString {
                        if let pushDelegate = self.delegate{
                            pushDelegate.didRecieveNotificationForSDKControls()
                        }
                    }
                    if let trackThroughTheDay = userInfo["track_through_the_day"] as? Int {
                        if trackThroughTheDay == 1 {
                            HTUserService.sharedInstance.startTracking(byUser: false, completionHandler: nil)
                        } else {
                            HTUserService.sharedInstance.stopTracking(byUser: false)
                        }
                    }
                }
            }
            
        }
    }
    
    func isHyperTrackNotification(userInfo: [AnyHashable: Any]) -> Bool {
        let key = "hypertrack_sdk_notification"
        return userInfo[key] != nil
    }
    
    func deleteRegisteredToken(){
        Settings.deleteRegisteredToken()
    }
    
    func setDeviceToken(deviceToken: String) {
        HTUserDefaults.standard.set(deviceToken, forKey: pushNotificationTokenString)
        HTUserDefaults.standard.synchronize()
    }
    
    func getDeviceToken() -> String? {
        return HTUserDefaults.standard.string(forKey: pushNotificationTokenString)
    }
    
    func setRegisteredToken(deviceToken: String) {
        HTUserDefaults.standard.set(deviceToken, forKey: registeredTokenString)
        HTUserDefaults.standard.synchronize()
    }
    
    func getRegisteredToken() -> String? {
        return HTUserDefaults.standard.string(forKey: registeredTokenString)
    }
    
}
