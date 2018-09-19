//
//  HTBottomCard.swift
//  SDKTest
//
//  Created by Atul Manwar on 14/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

public protocol HTBottomCardDataProtocol {
}

@objc public enum HTComponentType: Int {
    case user
    case status
    case userDetails
    case orderStatus
    case orderInfo
    case orderInfoArray
}

@objc public protocol HTBasicComponentProtocol {
}

@objc public protocol HTComponentProtocol: HTBasicComponentProtocol {
    var type: HTComponentType { get }
}

public class HTUserTrackingBottomCard: NSObject, HTBottomCardDataProtocol {
    public let components: [HTComponentProtocol]
    
    public init(_ components: [HTComponentProtocol]) {
        self.components = components
    }
    
    public class Data {
        public class UserCard: HTComponentProtocol {
            public let imageUrl: String?
            public let title: String
            public let description: String
            public let actionText: String
            public let actionImage: UIImage?
            public let actionType: HTBottomViewActionData
            public let isCurrent: Bool
            public let type: HTComponentType

            init(imageUrl: String?, title: String, description: String, actionText: String, actionImage: UIImage?, actionType: HTBottomViewActionData, isCurrent: Bool, type: HTComponentType) {
                self.imageUrl = imageUrl
                self.title = title
                self.description = description
                self.actionText = actionText
                self.actionImage = actionImage
                self.actionType = actionType
                self.isCurrent = isCurrent
                self.type = type
            }
        }
        public class Status: HTComponentProtocol {
            public let title: String
            public let actionText: String
            public let actionType: HTBottomViewActionData
            public let type: HTComponentType
            
            init(title: String, actionText: String, actionType: HTBottomViewActionData, type: HTComponentType) {
                self.title = title
                self.actionText = actionText
                self.actionType = actionType
                self.type = type
            }
        }
    }
}

public class HTOrderTrackingBottomCard: NSObject, HTBottomCardDataProtocol {
    public let components: [HTComponentProtocol]
    
    public init(_ components: [HTComponentProtocol]) {
        self.components = components
    }
    
    public class Data {
        public class OrderStatus: HTComponentProtocol {
            public let title: String
            public let image: UIImage?
            public let type: HTComponentType
            
            init(title: String, image: UIImage?, type: HTComponentType) {
                self.title = title
                self.image = image
                self.type = type
            }
        }
        public class OrderInfo: HTComponentProtocol {
            public let title: String
            public let description: String
            public let type: HTComponentType
            
            init(title: String, description: String, type: HTComponentType) {
                self.title = title
                self.description = description
                self.type = type
            }
        }
        public class OrderInfoArray: HTComponentProtocol {
            public let values: [OrderInfo]
            public let title: String
            public let type: HTComponentType
            
            init(values: [OrderInfo], title: String, type: HTComponentType) {
                self.values = values
                self.title = title
                self.type = type
            }
        }

    }
}
