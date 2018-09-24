//
//  HTUserService.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CocoaLumberjack

typealias HTUserResultHandler = (_ user: HTUser?, _ error: HTError?) -> Void

class HTUserService: NSObject {

    static let sharedInstance = HTUserService()

    private let userIdString = "HyperTrackUserId"
    private let lookupIdString = "HyperTrackLookupId"
    private let savedUser = "HyperTrackSavedUser"
    private let isPausedByUserKey = "hyperTrackIsTrackingPausedByUserKey"
    private var isPausedByUser = false {
        didSet {
            stopTimer()
            startTimer()
            
            HTUserDefaults.standard.set(isPausedByUser, forKey: isPausedByUserKey)
            HTUserDefaults.standard.synchronize()
        }
    }

    let requestManager: RequestManager
    var timer: Timer?
    let timerInterval: Double = 300
    var backgroundTaskIdentifier : UIBackgroundTaskIdentifier = 0
    
    override init() {
        self.requestManager = RequestManager()
        super.init()
        isPausedByUser = HTUserDefaults.standard.bool(forKey: isPausedByUserKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.onUserServiceInitialization()
        }
    }
    
    func onUserServiceInitialization(){
        if self.userId != nil {
            self.startCheckingForPendingActions()
        }
    }
    
    func startTracking(byUser: Bool, completionHandler: ((_ error: HTError?) -> Void)?) {
        if byUser {
            isPausedByUser = false
        }
//        if !isPausedByUser {
        HypertrackService.sharedInstance.startTracking(byUser: byUser, completionHandler: completionHandler)
//        }
    }
    
    func stopTracking(byUser: Bool) {
        if byUser {
            isPausedByUser = true
        }
        HypertrackService.sharedInstance.stopTracking(byUser: byUser, completionHandler: nil)
    }
    
    func onAppBackground(_ notification: Notification) {
        stopTimer()
        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "getPendingActions") {
            self.getPendingActionDetails()
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
        
        startTimer()
        if let timer = timer {
            RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
        }
    }
    
    var userId: String? {
        get {
            return HTUserDefaults.standard.string(forKey: userIdString)
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: userIdString)
            HTUserDefaults.standard.synchronize()
            HypertrackService.sharedInstance.pushNotificationService.registerDeviceToken()
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name(rawValue: HTConstants.HTUserIdCreatedNotification),
                    object: nil,
                    userInfo: nil)
        }
    }
    
    var uniqueId: String {
        get {
            return HTUserDefaults.standard.string(forKey: lookupIdString) ?? ""
        }
        
        set {
            HTUserDefaults.standard.set(newValue, forKey: lookupIdString)
            HTUserDefaults.standard.synchronize()
        }
    }
    
    func createUser(id: String, completionHandler: @escaping HTUserResultHandler) {
        self.requestManager.createUser(["id": id]) { user, error in
            if  let user = user {
                self.userId = user.id
                self.saveUser(user: user)
            }
            else if error != nil {
                DDLogError("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            else{
                DDLogError("Error creating user: user is null")
            }
            completionHandler(user, error)
        }
    }

    func  createUser(_ name: String, completionHandler: HTUserResultHandler?) {
        self.requestManager.createUser(["name": name]) { user, error in

            if  let user = user {
                self.userId = user.id
                self.saveUser(user: user)
            }
            else if error != nil {
                DDLogError("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            else{
                DDLogError("Error creating user: user is null")
            }
          
            if completionHandler != nil {
                completionHandler!(user, error)
            }
        }
    }

    func createUser(_ name: String, _ phone: String, _ uniqueId: String, _ photo: UIImage?, _ completionHandler: @escaping HTUserResultHandler) {
        var requestBody = ["name": name, "phone": phone, "unique_id": uniqueId]

        if let photo = photo {
            // Convert image to base64 before upload
            if let imageData = UIImagePNGRepresentation(photo) {
                let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                requestBody["photo"] = strBase64
            }
        }

        self.requestManager.createUser(requestBody) { user, error in
            if  let user = user {
                self.saveUser(user: user)
            } else if error != nil {
                DDLogError("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            else{
                DDLogError("Error creating user: user is null")
            }

            completionHandler(user, error)
        }
    }

    func createUser(_ name: String, _ phone: String, _ uniqueId: String, _ completionHandler: @escaping HTUserResultHandler) {

        self.requestManager.createUser(["name": name, "phone": phone, "unique_id": uniqueId]) { user, error in
            if  let user = user {
                self.saveUser(user: user)
                self.uniqueId = uniqueId
            } else if error != nil {
                DDLogError("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            else{
                DDLogError("Error creating user: user is null")
            }

            completionHandler(user, error)
        }
    }

    func updateUser(_ name: String, _ phone: String? = nil, _ uniqueId: String? = nil, _ photo: UIImage? = nil, _ completionHandler: @escaping HTUserResultHandler) {

        var requestBody = ["name": name]
        if let phone = phone {
            requestBody["phone"] = phone
        }

        if let uniqueId = uniqueId {
            requestBody["unique_id"] = uniqueId
        }
        if let photo = photo {
            // Convert image to base64 before upload
            if let imageData = UIImagePNGRepresentation(photo) {
                let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
                requestBody["photo"] = strBase64
            }
        }

        self.requestManager.updateUser(userId ?? "", params: requestBody) { user, error in
            if  let user = user {
                self.saveUser(user: user)
            } else if error != nil {
                DDLogError("Error creating user: \(String(describing: error?.type.rawValue))")
            }
            else{
                DDLogError("Error creating user: user is null")
            }

            completionHandler(user, error)
        }
    }
    
    func saveUser(user: HTUser) {
        self.userId = user.id
        let jsonData = user.toJson()
        HTUserDefaults.standard.set(jsonData, forKey: savedUser)
        HTUserDefaults.standard.synchronize()
        startCheckingForPendingActions()
    }
    
    func getUser() -> HTUser? {
        if let jsonData = HTUserDefaults.standard.string(forKey: savedUser) {
            return HTUser.fromJson(text: jsonData)
        }
        return nil
    }
    
    func getPlacelineActivity(date: Date? = nil, userID: String? = nil, completionHandler: @escaping (_ placeline: HTPlaceline?, _ error: HTError?) -> Void) {
        // TODO: this method should not be in Transmitter, but needs access to request manager
        var user = userID
        if user == nil {
            user = HTUserService.sharedInstance.userId
        }
        
        guard let userId = user else {
            completionHandler(nil, HTError(HTErrorType.userIdError))
            return
        }
        
        requestManager.getUserPlaceline(date: date, userId: userId) { (placeline, error) in
            if error != nil {
                completionHandler(nil, error)
                return
            }
            
            completionHandler(placeline, nil)
        }
    }
    
    public func isCurrentUser(userId: String?) -> Bool {
        if let userId = userId {
            if let currentUserId = HTUserService.sharedInstance.userId {
                if currentUserId == userId {
                    return true
                }
            }
        }
        return false
    }
    
    func startCheckingForPendingActions() {
        startTimer()
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAppBackground(_:)), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
        getPendingActionDetails()
    }
    
    func stopCheckingForPendingActions() {
        stopTimer()
    }

    fileprivate func startTimer() {
        if timer?.isValid == true {
            self.stopTimer()
        }
        timer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(self.getPendingActionDetails), userInfo: Date(), repeats: true)
        timer?.fire()
    }
    
    fileprivate func stopTimer() {
        self.timer?.invalidate()
    }
    
    @objc func getPendingActions(completionHandler: @escaping (_ actions: [HTAction]?, _ error: HTError?) -> Void) {
        if let userId = self.userId {
            requestManager.getPendingActions(userId) { (actions, error) in
                completionHandler(actions, error)
            }
        } else {
            completionHandler(nil, HTError(.userIdError))
        }
    }
    
    @objc func getPendingActionDetails() {
        getPendingActions { (actions, error) in
            if error != nil {
                return
            }
            self.processPendingActionsResponse(actions: actions)
        }
    }
    
    func processPendingActionsResponse(actions: [HTAction]?) {
        //Addeing a guard here to prevent completion handler call if timer was stopped by user
        if (actions ?? []).filter({ !$0.actionStatus.isCompleted }).count > 0 {
            startTracking(byUser: false, completionHandler: nil)
        } else {
            stopTracking(byUser: false)
        }
    }
    
    func fire() {
        timer?.fire()
    }
}
