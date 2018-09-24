//
//  NativeClickHandler.swift
//  sampleAcko
//
//  Created by Pushpendra Khandelwal on 14/09/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

import UIKit

@objc(NativeClickHandler)
class NativeClickHandler: NSObject {
  
  
  @objc func methodQueue() -> DispatchQueue {
    return DispatchQueue.main
  }
  
  @objc func didButtonClick() {
    let alertController = UIAlertController.init(title: "Button Clicked", message: "This method is exposed in Native iOS", preferredStyle: .actionSheet)
    let okAction = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
    alertController.addAction(okAction)
    let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
    currentViewController.present(alertController, animated: true, completion: nil)
  }
  
  @objc func permissionNotGranted() {
    let alertController = UIAlertController.init(title: "Gallery Permission Denied", message: "User has denied access for Gallery.", preferredStyle: .actionSheet)
    let okAction = UIAlertAction.init(title: "Ok", style: .default, handler: nil)
    alertController.addAction(okAction)
    let currentViewController = UIApplication.shared.keyWindow?.rootViewController ?? UIViewController()
    currentViewController.present(alertController, animated: true, completion: nil)
  }
  
}
