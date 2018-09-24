//
//  HTDownloadManager.swift
//  HyperTrack
//
//  Created by Atul Manwar on 03/04/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

final class HTDownloadManager: NSObject {
    fileprivate var cachedImages: [String: UIImage] = [:]
    
    static let instance = HTDownloadManager()
    
    override init() {
        super.init()
    }
    
    func downloadImage(urlString: String, completionHandler: @escaping (_ image: UIImage?) -> Void) {
        if let image = cachedImages[urlString] {
            completionHandler(image)
        } else {
            HTApiRouter.downloadImage(urlString: urlString) { [weak self] (image) in
                if let image = image {
                    self?.cachedImages[urlString] = image
                }
                completionHandler(image)
            }
        }
    }
}
