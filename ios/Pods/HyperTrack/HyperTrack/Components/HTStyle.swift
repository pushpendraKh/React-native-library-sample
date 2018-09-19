//
//  HTStyle.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public protocol HTStyleProviderProtocol: class {
    var colors: HTColorProviderProtocol { get set }
    var fonts: HTFontProviderProtocol { get set }
    var padding: HTPaddingProviderProtocol { get set }
    var layer: HTLayerProviderProtocol { get set }
    var markerImages: HTMarkerImagesProviderProtocol { get set }
}

@objc public final class HTStyleConfig: NSObject, HTStyleProviderProtocol {
    public var colors: HTColorProviderProtocol
    public var fonts: HTFontProviderProtocol
    public var padding: HTPaddingProviderProtocol
    public var layer: HTLayerProviderProtocol
    public var markerImages: HTMarkerImagesProviderProtocol
    
    public override init() {
        colors = HTColorProvider()
        fonts = HTFontProvider()
        padding = HTPaddingProvider()
        layer = HTLayerProvider()
        markerImages = HTMarkerImagesProvider()
        super.init()
    }
}
