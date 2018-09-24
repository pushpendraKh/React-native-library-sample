//
//  HTMotionHelper.swift
//  HyperTrack
//
//  Created by Ravi Jain on 8/5/17.
//  Copyright © 2017 HyperTrack. All rights reserved.
//

import UIKit
import CoreMotion

protocol HTDeviceSensorDelegate : class {
    func didRecieveGyroData(gyroData: CMGyroData)
    func didRecieveAccelerometerData(accelerometerData: CMAccelerometerData)
    func didRecieveDeviceMotionData(deviceMotionData: CMDeviceMotion)
}

class HTDeviceSensorsDataHelper: NSObject {

    let motionManager = CMMotionManager()
    weak var delegate: HTDeviceSensorDelegate?

    public var isGivingUpdateBasedOnDuration = false

    func getAccelerometerUpdates(forDuration: Double, frequency: Double,
                                 withHandler handler: @escaping (_ historicMotion: [String: [Double]], _ error: Error?) -> Void) {
        var historicMotion = [String: [Double]]()
        var isCompleted = false
        if self.motionManager.isAccelerometerAvailable {
            historicMotion["x"] = [Double]()
            historicMotion["y"] = [Double]()
            historicMotion["z"] = [Double]()
            var time  = 0.0
            isGivingUpdateBasedOnDuration = true
            self.motionManager.accelerometerUpdateInterval = frequency
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                if let data  = data {

                    historicMotion["x"]?.append(data.acceleration.x)
                    historicMotion["y"]?.append(data.acceleration.y)
                    historicMotion["z"]?.append(data.acceleration.z)

                    time += frequency
                    if time > forDuration {
                        if !isCompleted {
                            isCompleted = true
                            handler(historicMotion, nil)
                            self.stopAccelerometerUpdates()
                            self.isGivingUpdateBasedOnDuration = false
                            return
                        }
                    }
                } else {
                    handler(historicMotion, error)
                    self.isGivingUpdateBasedOnDuration = false
                    return
                }
            }
        } else {
            isGivingUpdateBasedOnDuration = false
            let errorTitle = "AccelerometerDataNotAvailable"
            let error = CustomError.init(localizedTitle: errorTitle, localizedDescription: "", code: 0)
            handler(historicMotion, error)
        }
    }

    func getAccelerometerUpdates(onlyOnce: Bool,
                                 withHandler handler: @escaping CMAccelerometerHandler) {

        if self.motionManager.isAccelerometerAvailable {
            self.motionManager.accelerometerUpdateInterval = 0.1
            self.motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                handler(data, error)
                if let data  = data {
                    if let delegate = self.delegate {
                        delegate.didRecieveAccelerometerData(accelerometerData: data)
                    }
                }

                if onlyOnce {
                    self.stopAccelerometerUpdates()
                }
            }
        } else {
            let errorTitle = "AccelerometerDataNotAvailable"
            let error = CustomError.init(localizedTitle: errorTitle, localizedDescription: "", code: 0)
            handler(nil, error)
        }
    }

    func getGyroUpdates(onlyOnce: Bool,
                        withHandler handler: @escaping CMGyroHandler) {

        var isUpdateDelivered = false
        if self.motionManager.isGyroAvailable {
            self.motionManager.gyroUpdateInterval = 0.5
            self.motionManager.startGyroUpdates(to: OperationQueue.main, withHandler: { (data, error) in
                if !isUpdateDelivered && onlyOnce{
                    isUpdateDelivered = true
                    handler(data, error)
                }
                if let data  = data {
                    if let delegate = self.delegate {
                        delegate.didRecieveGyroData(gyroData: data)
                    }
                }
                if onlyOnce {
                    self.stopGyroUpdates()
                }
            })
        } else {
            let error = CustomError.init(localizedTitle: "GyroDataNotAvailable", localizedDescription: "", code: 0)
            handler(nil, error)
        }
    }

    func getDeviceMotionUpdates(onlyOnce: Bool,
                                withHandler handler: @escaping CMDeviceMotionHandler) {
        if self.motionManager.isDeviceMotionActive {
            self.motionManager.deviceMotionUpdateInterval = 0.1
            self.motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (data, error) in
                handler(data, error)
                if let error = error {
                    print(error.localizedDescription)
                }

                if let data  = data {
                    if let delegate = self.delegate {
                        delegate.didRecieveDeviceMotionData(deviceMotionData: data)
                    }
                }

                if onlyOnce {
                    self.stopDeviceMotionUpdates()
                }

            })
        } else {
            let errorTitle = "DeviceMotionDataNotAvailable"
            let error = CustomError.init(localizedTitle: errorTitle, localizedDescription: "", code: 0)
            handler(nil, error)
        }
    }

    func stopAccelerometerUpdates() {
        self.motionManager.stopAccelerometerUpdates()
    }

    func stopGyroUpdates() {
        self.motionManager.stopGyroUpdates()
    }

    func stopDeviceMotionUpdates() {
        self.motionManager.stopDeviceMotionUpdates()
    }

    func stopmagnetometerUpdates() {
        self.motionManager.stopMagnetometerUpdates()
    }
}

struct CustomError: Error {

    var localizedTitle: String
    var localizedDescription: String
    var code: Int

    init(localizedTitle: String?, localizedDescription: String, code: Int) {
        self.localizedTitle = localizedTitle ?? "Error"
        self.localizedDescription = localizedDescription
        self.code = code
    }
}
