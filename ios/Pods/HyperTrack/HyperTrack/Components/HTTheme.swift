//
//  HTTheme.swift
//  HyperTrack
//
//  Created by Atul Manwar on 07/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

public class HTTheme {
    public enum Style {
        case background(UIColor)
        case textColor(UIColor)
        case font(UIFont)
        case radius(CGFloat)
        case padding(UIEdgeInsets)
        case tintColor(UIColor)
    }
    
    public enum AnnotationStyle {
        case color(UIColor)
        case pulseColor(UIColor)
        case scaleFactor(CGFloat)
        case size(CGSize)
        case pulsating(Bool)
        case image(UIImage?)
    }
}
