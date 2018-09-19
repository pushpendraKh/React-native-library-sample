//
//  HTAnnotationView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 09/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit
import MapKit

@objc public enum AnchorPosition: Int {
    case top = 0
    case bottom
    case left
    case right
    case topLeft
    case topRight
    case center
}

class HTAnnotationView: MKAnnotationView {
    fileprivate var contentView: HTMarkerContentView!
    fileprivate var moveToSuperViewAnimation: ((HTAnnotationView) -> Void)?
    
    var data: HTAnnotationData? {
        didSet {
            contentView.data = data
        }
    }
    
    var shouldRotate: Bool = false
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let contentView = contentView else { return }
            contentView.removeCallout()
        }
    }
    var pulseColor: UIColor? = nil {
        didSet {
            contentView.pulseColor = pulseColor
        }
    }
    var annotationImage: UIImage? = nil {
        didSet {
            contentView.annotationImage = annotationImage
        }
    }
    var imageView: UIImageView? = nil {
        didSet {
            contentView.imageView = imageView
        }
    }
    var scaleFactor: CGFloat = 5.3 {
        didSet {
            contentView.scaleFactor = scaleFactor
        }
    }
    var animationDuration: Double = 1.5 {
        didSet {
            contentView.animationDuration = animationDuration
        }
    }
    var animationDelay: Double = 1.5 {
        didSet {
            contentView.animationDelay = animationDelay
        }
    }
    var size: CGSize = HTProvider.userMarkerSize {
        didSet {
            contentView.size = size
        }
    }
    var annotationColor: UIColor? = nil {
        didSet {
            contentView.annotationColor = annotationColor
        }
    }
    var isPulsating: Bool = true {
        didSet {
            contentView.isPulsating = isPulsating
        }
    }
    
    convenience init(annotation: MKAnnotation?, reuseIdentifier: String?, data: HTAnnotationData?) {
        self.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        defer {
            self.data = data
        }
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        canShowCallout = false
        contentView = HTMarkerContentView(frame: .zero)
        contentView.center = self.center
//        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.edges()
        contentView.removeCallout()
        contentView.annotationColor = HTProvider.style.colors.brand
        moveToSuperViewAnimation = {(annotationView: HTAnnotationView) in
            annotationView.layer.add(HTAnnotationView.bounceAnimation, forKey: "popIn")
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentView.showCallOut = selected
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepareForReuse() {
        //        super.prepareForReuse()
        guard let contentView = contentView else { return }
        contentView.removeCallout()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if let _ = newSuperview {
            contentView.setup()
        } else {
            moveToSuperViewAnimation?(self)
        }
    }
    
    func rotateForBearing(_ bearing: CGFloat) {
        contentView.rotateForBearing(bearing)
    }
    
    static var bounceAnimation: CAKeyframeAnimation {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        let easeInOut = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        bounceAnimation.values = [0.05, 1.25, 0.8, 1.1, 0.9, 1.0]
        bounceAnimation.timingFunctions = bounceAnimation.values?.map({ _ in return easeInOut }) ?? []
        bounceAnimation.duration = 0.3
        return bounceAnimation
    }
    
    fileprivate func popIn() {
        layer.add(HTAnnotationView.bounceAnimation, forKey: "popIn")
    }
}

public class HTMarkerContentView: UIView {
    fileprivate var calloutView: HTCalloutView?
    fileprivate var anchor: AnchorPosition = .right
    var data: HTAnnotationData? {
        didSet {
            self.isPulsating = data?.metaData.isPulsating ?? false
            if data?.callout == nil {
                removeCallout()
            }
            if let meta = data?.metaData {
                applyStyles(meta)
            }
            shouldRotate = (data?.metaData.activityType == .drive) || HTProvider.alwaysRotateUserMarker
            setup()
        }
    }
    
    var shouldRotate: Bool = false
    
    public var pulseColor: UIColor? = nil {
        didSet {
            setup()
        }
    }
    public var annotationImage: UIImage? = nil {
        didSet {
            setup()
        }
    }
    public var imageView: UIImageView? = nil {
        didSet {
//            setup()
        }
    }
    public var scaleFactor: CGFloat = 5.3 {
        didSet {
            setup()
        }
    }
    public var animationDuration: Double = 1.5 {
        didSet {
            setup()
        }
    }
    public var animationDelay: Double = 1.5 {
        didSet {
            setup()
        }
    }
    public var size: CGSize = HTProvider.userMarkerSize {
        didSet {
            bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            imageView?.bounds.size = bounds.size
            frame.size = bounds.size
            setup()
        }
    }
    public var annotationColor: UIColor? = nil {
        didSet {
            setup()
        }
    }
    public var isPulsating: Bool = true {
        didSet {
            setup()
        }
    }

    var showCallOut: Bool = false {
        didSet {
            calloutView?.data = nil
            calloutView?.removeFromSuperview()
            calloutView = nil
            if showCallOut && HTProvider.shouldShowCallouts {
                let metaData = data?.callout?.metaData ?? HTCallout.MetaData.default
                let calloutView = HTCalloutView(arrangedSubviews: [], metaData: metaData)
                calloutView.translatesAutoresizingMaskIntoConstraints = false
                addSubview(calloutView)
                calloutView.data = data?.callout
                addConstaintsToCalloutView(calloutView, anchor: anchor, padding: 4)
                self.calloutView = calloutView
                self.calloutView?.isHidden = false
//                self.calloutView?.alpha = 0
//                UIView.animate(withDuration: 0.1, animations: {
//                    self.calloutView?.alpha = 1
//                })
            } else {
//                UIView.animate(withDuration: 0.1, animations: {
//                    self.calloutView?.alpha = 0
//                }, completion: nil)
            }
        }
    }
    fileprivate var annotationLayer: CALayer?
    fileprivate var pulseLayer: CALayer?
    fileprivate var moveToSuperViewAnimation: ((HTAnnotationView) -> Void)?
    fileprivate var bearing: CGFloat = 0
    
    public convenience init(frame: CGRect, data: HTAnnotationData?) {
        self.init(frame: frame)
        removeCallout()
        defer {
            self.data = data
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        annotationColor = HTProvider.style.colors.brand
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func removeCallout() {
        showCallOut = false
        calloutView?.data = nil
        calloutView?.removeFromSuperview()
        calloutView = nil
    }
    
    fileprivate func addConstaintsToCalloutView(_ calloutView: UIView, anchor: AnchorPosition, padding: CGFloat) {
        let newPadding = ((anchor == .top || anchor == .bottom) ? size.height : size.width) * 0.5 + padding
        switch anchor {
        case .top:
            addConstraints([
                calloutView.centerX(constant: 0),
                calloutView.bottom(toAttribute: .top, constant: newPadding)
                ])
        case .bottom:
            addConstraints([
                calloutView.centerX(constant: 0),
                calloutView.top(toAttribute: .bottom, constant: newPadding)
                ])
        case .left:
            addConstraints([
                calloutView.centerY(constant: 0),
                calloutView.right(toAttribute: .leading, constant: newPadding)
                ])
        case .right:
            addConstraints([
                calloutView.centerY(constant: 0),
                calloutView.left(toAttribute: .trailing, constant: newPadding)
                ])
        default:
            break
        }
    }
    
    func redraw() {
        setup()
    }
    
    func rotateForBearing(_ bearing: CGFloat) {
        self.bearing = bearing
        if shouldRotate {
            imageView?.transform = CGAffineTransform(rotationAngle: bearing)
        } else {
            imageView?.transform = .identity
        }
    }
    
    fileprivate func setup() {
        layer.removeAllAnimations()
        annotationLayer?.removeFromSuperlayer()
        annotationLayer = nil
        pulseLayer?.removeFromSuperlayer()
        pulseLayer = nil
        if annotationImage != nil {
            imageView?.removeFromSuperview()
            imageView = nil
        }
        if isPulsating && HTProvider.shouldShowPulsatingMarkers {
            if pulseColor == nil {
                pulseColor = annotationColor
            }
            layer.addSublayer(createPulseLayer())
        }
        layer.addSublayer(createDotLayer())
        if annotationImage != nil {
            let imageView = UIImageView(image: annotationImage)
            imageView.bounds.size = size
            imageView.center = CGPoint(x: bounds.width/2, y: bounds.height/2)
            self.imageView = imageView
            rotateForBearing(bearing)
            addSubview(imageView)
        }
    }
}

extension HTMarkerContentView {
    fileprivate func createDotLayer() -> CALayer {
        if let layer = annotationLayer {
            return layer
        } else {
            let layer = CALayer()
            layer.bounds = bounds
            layer.allowsGroupOpacity = true
//            layer.backgroundColor = isPulsating ? annotationColor?.cgColor : UIColor.clear.cgColor
            layer.cornerRadius = bounds.width/2
            layer.position = CGPoint(x: bounds.width/2, y: bounds.height/2)
            layer.shouldRasterize = true
            layer.rasterizationScale = UIScreen.main.scale
            if animationDelay > 0 && animationDelay != Double.infinity && isPulsating {
                let group = createAnimationGroup(duration: animationDuration)
                group.autoreverses = true
                group.speed = 1
                group.fillMode = kCAFillModeBoth
                let pulseAnimation = createBasicAnimation(keyPath: "transform.scale.xy", duration: animationDuration, fromValue: 0.8, toValue: 1)
                let opacityAnimation = createBasicAnimation(keyPath: "opacity", duration: animationDuration, fromValue: 0.8, toValue: 1)
                group.animations = [pulseAnimation, opacityAnimation]
                DispatchQueue.main.async {
                    layer.add(group, forKey: "pulse")
                }
            }
            annotationLayer = layer
            return layer
        }
    }
    
    fileprivate func createPulseLayer() -> CALayer {
        if let layer = pulseLayer {
            return layer
        } else {
            let width = bounds.size.width * scaleFactor
            let layer = CALayer()
            layer.bounds = CGRect(x: 0, y: 0, width: width, height: width)
//            layer.backgroundColor = (pulseColor ?? UIColor.blue).cgColor
            layer.cornerRadius = width/2
            layer.position = CGPoint(x: bounds.width/2, y: bounds.height/2)
            layer.opacity = isPulsating ? 0 : 1
            layer.contentsScale = UIScreen.main.scale
            if animationDelay != Double.infinity && isPulsating {
                DispatchQueue.global(qos: .default).async {
                    let group = self.pulseAnimatingGroup
                    DispatchQueue.main.async {
                        layer.add(group, forKey: "pulse")
                    }
                }
            }
            pulseLayer = layer
            return layer
        }
    }
}

extension HTMarkerContentView {
    fileprivate func createAnimationGroup(duration: Double) -> CAAnimationGroup {
        let group = CAAnimationGroup()
        group.duration = duration
        group.repeatCount = Float.infinity
        group.isRemovedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        return group
    }
    
    fileprivate func createBasicAnimation(keyPath: String, duration: Double, fromValue: Double, toValue: Double) -> CABasicAnimation {
        let pulseAnimation = CABasicAnimation(keyPath: keyPath)
        pulseAnimation.fromValue = fromValue
        pulseAnimation.toValue = toValue
        pulseAnimation.duration = duration
        return pulseAnimation
    }
    
    fileprivate func createKeyFrameAnimation(keyPath: String, duration: Double, values: [Double], keyTimes: [NSNumber]) -> CAKeyframeAnimation {
        let opacityAnimation = CAKeyframeAnimation(keyPath: keyPath)
        opacityAnimation.duration = duration
        opacityAnimation.values = values
        opacityAnimation.keyTimes = keyTimes
        opacityAnimation.isRemovedOnCompletion = false
        return opacityAnimation
    }
    
    fileprivate var pulseAnimatingGroup: CAAnimationGroup {
        let group = createAnimationGroup(duration: animationDuration + animationDelay)
        let pulseAnimation = createBasicAnimation(keyPath: "transform.scale.xy", duration: animationDuration, fromValue: 0, toValue: 1)
        let opacityAnimation = createKeyFrameAnimation(keyPath: "opacity", duration: animationDuration, values: [0.45, 0.45, 0], keyTimes: [0, 0.2, 1])
        group.animations = [pulseAnimation, opacityAnimation]
        return group
    }
    
    fileprivate func circularFilledImage(_ color: UIColor, height: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: height, height: height), false, 0)
        _ = CGColorSpaceCreateDeviceRGB()
        let fillPath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: height, height: height))
        color.setFill()
        fillPath.fill()
        let dotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return dotImage
    }
}

extension HTMarkerContentView: HTAnnotationStyleProtocol {
}
