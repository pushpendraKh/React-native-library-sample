//
//  Providers.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import Foundation

@objc public class HTProvider: NSObject {
    public static var style: HTStyleProviderProtocol = HTStyleConfig()
    public static var animationDuration = 0.35
    public static var numberOfPointsForAnimation = 50
    public static var pollDuration: Double = 6
    public static var shouldShowPulsatingMarkers: Bool = false
    public static var shouldShowCallouts: Bool = false
    public static var alwaysRotateUserMarker: Bool = true
    public static var userMarkerSize: CGSize = CGSize(width: 25, height: 25)
    public static var destinationMarkerSize: CGSize = CGSize(width: 20, height: 20)
    public static var mapCustomizationDelegate: HTMapCustomizationDelegate?
}
