//
//  ZendriveHelper.swift
//  sampleAcko
//
//  Created by Pushpendra Khandelwal on 17/09/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import UIKit
import ZendriveSDK
//import HyperTrackCore

@objc(ZendriveHelper)
class ZendriveHelper: NSObject {

  static let sharedInstance = ZendriveHelper()
  
  @objc func methodQueue() ->  DispatchQueue {
    return DispatchQueue.main
  }
  
  @objc func setUpAndStartZenDrive(_ userId: String) {
    if userId == "" {
      return
    }
    let configuration = ZendriveConfiguration()
    configuration.applicationKey = "WAak1QFOA8OXl1GvjsVLmzRFafmZBOyK"
    configuration.driveDetectionMode = .autoON
    configuration.driverId = userId
    
    let driverAttrs = ZendriveDriverAttributes()
    driverAttrs.setFirstName(userId)
    driverAttrs.setPhoneNumber(userId)
    configuration.driverAttributes = driverAttrs
    
    Zendrive.setup(with: configuration, delegate: nil) { (_ success: Bool, _ error: Error?) -> Void in
      if success {
        // Helper.showToast(withText: "SDK Initialized")
      } else {
        print(error.debugDescription)
        //
      }
    }
  }
  
  @objc func disableZenDrive() {
    Zendrive.teardown()
  }
    
  @objc func openDocumentPicker() {

    
    let documentController = UIDocumentPickerViewController.init(documentTypes: ["com.adove.pdf",
                                                                                 "public.jpeg",
                                                                                 "public.image",
                                                                                 "public.audio",
                                                                                 "public.movie",
                                                                                 "public.text",
                                                                                 "public.item",
                                                                                 "public.content",
                                                                                 "public.source-code"],
                                                                 in: .import)
    documentController.delegate = self
    DispatchQueue.main.async {
      let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
      currentViewController.present(documentController, animated: true, completion: nil)
    }
  }
}

extension ZendriveHelper: UIDocumentPickerDelegate {
  
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    let data = NSData.init(contentsOf: url)
    print(data ?? NSData())
  }
  
}
