//
//  UIKitExtensions.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/02/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

protocol HTViewProtocol {
    var padding: HTPaddingProviderProtocol { get set }
    init(frame: CGRect, padding: HTPaddingProviderProtocol)
}

extension UIView {
    public func edges(_ padding: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        superview?.addConstraints([
            top(constant: padding.top),
            bottom(constant: padding.bottom),
            left(constant: padding.left),
            right(constant: padding.right)
            ])
    }
    
    fileprivate func createConstraint(to: Any?, attribute: NSLayoutAttribute, toAttribute: NSLayoutAttribute? = nil, relation: NSLayoutRelation? = nil, constant: CGFloat) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation ?? .equal, toItem: to, attribute: toAttribute ?? attribute, multiplier: 1, constant: constant)
    }
    
    func top(_ view: UIView? = nil, toAttribute: NSLayoutAttribute? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view ?? superview, attribute: .top, toAttribute: toAttribute, relation: relation, constant: constant)
    }
    
    func bottom(_ view: UIView? = nil, toAttribute: NSLayoutAttribute? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view ?? superview, attribute: .bottom, toAttribute: toAttribute, relation: relation, constant: constant)
    }

    func left(_ view: UIView? = nil, toAttribute: NSLayoutAttribute? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view ?? superview, attribute: .leading, toAttribute: toAttribute, relation: relation, constant: constant)
    }

    func right(_ view: UIView? = nil, toAttribute: NSLayoutAttribute? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view ?? superview, attribute: .trailing, toAttribute: toAttribute, relation: relation, constant: constant)
    }

    func centerX(_ view: UIView? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view ?? superview, attribute: .centerX, toAttribute: .centerX, relation: nil, constant: constant)
    }
    
    func centerY(_ view: UIView? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view ?? superview, attribute: .centerY, toAttribute: .centerY, relation: nil, constant: constant)
    }
    
    func width(_ view: UIView? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view, attribute: .width, toAttribute: (view == nil ? .notAnAttribute : .width), relation: relation, constant: constant)
    }
    
    func height(_ view: UIView? = nil, relation: NSLayoutRelation = .equal, constant: CGFloat = 0) -> NSLayoutConstraint {
        return createConstraint(to: view, attribute: .height, toAttribute: (view == nil ? .notAnAttribute : .height), relation: relation, constant: constant)
    }
}

extension UIView {
    func applyShadow() {
        let shadowPath = UIBezierPath(rect: bounds)
        layer.masksToBounds = false
        layer.shadowColor = HTProvider.style.colors.dropShadow.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 0
        layer.shadowOpacity = 0.1
        layer.shadowPath = shadowPath.cgPath
    }
    
    func clipTopCorners(_ cornerRadius: CGFloat) {
        let path = UIBezierPath(roundedRect:bounds,
                                byRoundingCorners:[.topRight, .topLeft],
                                cornerRadii: CGSize(width: cornerRadius, height:  cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        layer.mask = maskLayer
    }
}

extension UIView {
    func removeDashedLine() {
        layer.sublayers?.filter({ $0.name == "htDashedLine" }).forEach({ $0.removeFromSuperlayer() })
    }
    
    func addDashedLine(from: CGPoint, to: CGPoint, color: UIColor = .lightGray, pattern: [NSNumber] = [4, 4], width: CGFloat = 1) {
        removeDashedLine()
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = width
        shapeLayer.lineDashPattern = pattern
        shapeLayer.name = "htDashedLine"
        let path = CGMutablePath()
        path.addLines(between: [from, to])
        shapeLayer.path = path
        layer.addSublayer(shapeLayer)
    }
    
    func addDashedLine(color: UIColor = .lightGray) {
        removeDashedLine()
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineDashPattern = [4, 4]
        shapeLayer.name = "htDashedLine"
        let path = CGMutablePath()
        if bounds.height > bounds.width {
            path.addLines(between: [CGPoint(x: bounds.width/2, y: 0),
                                    CGPoint(x: bounds.width/2, y: bounds.height)])
        } else {
            path.addLines(between: [CGPoint(x: 0, y: bounds.height/2),
                                    CGPoint(x: bounds.width, y: bounds.height/2)])
        }
        shapeLayer.path = path
        
        layer.addSublayer(shapeLayer)
    }
}

open class HTBaseView: UIView {
    public var enableShadow: Bool = false
    public var dashBorderedColor: UIColor? = nil
    fileprivate var isDashBorderCreated = false
    public var topCornerRadius: CGFloat = 0
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if enableShadow {
            applyShadow()
        }
        if let color = dashBorderedColor, bounds.height > 0 {
            isDashBorderCreated = true
            addDashedLine(color: color)
        } else if isDashBorderCreated {
            removeDashedLine()
            isDashBorderCreated = false
        }
        if topCornerRadius > 0 {
            clipTopCorners(topCornerRadius)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

public  class HTLabel: UILabel {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

public class HTButton: UIButton {
    public var topCornerRadius: CGFloat = 0
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if topCornerRadius > 0 {
            clipTopCorners(topCornerRadius)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension UIImage {
    static func resizableShadowImage(withSideLength sideLength: CGFloat, cornerRadius: CGFloat, shadow: Shadow) -> UIImage {
        // The image is a square, which makes it easier to set up the cap insets.
        //
        // Note: this implementation assumes an offset of CGSize(0, 0)
        
        let lengthAdjustment = sideLength + (shadow.blur * 2.0)
        let graphicContextSize = CGSize(width: lengthAdjustment, height: lengthAdjustment)
        
        // Note: the image is transparent
        UIGraphicsBeginImageContextWithOptions(graphicContextSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        defer {
            UIGraphicsEndImageContext()
        }
        
        let roundedRect = CGRect(x: shadow.blur, y: shadow.blur, width: sideLength, height: sideLength)
        let shadowPath = UIBezierPath(roundedRect: roundedRect, cornerRadius: cornerRadius)
        let color = shadow.color.cgColor
        
        // Cut out the middle
        context.addRect(context.boundingBoxOfClipPath)
        context.addPath(shadowPath.cgPath)
        context.clip(using: .evenOdd)
        
        context.setStrokeColor(color)
        context.addPath(shadowPath.cgPath)
        context.setShadow(offset: shadow.offset, blur: shadow.blur, color: color)
        context.fillPath()
        
        let capInset = cornerRadius + shadow.blur
        let edgeInsets = UIEdgeInsets(top: capInset, left: capInset, bottom: capInset, right: capInset)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        return image.resizableImage(withCapInsets: edgeInsets, resizingMode: .tile)
    }
}

extension UIView {
    func applyBaseStyles(_ styles: [HTTheme.Style]) {
        styles.forEach({
            self.applyBaseStyle($0)
        })
    }
    
    func applyBaseStyle(_ style: HTTheme.Style) {
        switch style {
        case .background(let color):
            backgroundColor = color
        case .radius(let radius):
            layer.cornerRadius = radius
        case .tintColor(let color):
            tintColor = color
        default:
            break
        }
    }
}

extension UILabel {
    func applyStyle(_ style: HTTheme.Style) {
        switch style {
        case .background(let color):
            backgroundColor = color
        case .textColor(let color):
            textColor = color
        case .font(let font):
            self.font = font
        default:
            super.applyBaseStyle(style)
        }
    }
    
    func applyStyles(_ styles: [HTTheme.Style]) {
        styles.forEach({
            self.applyStyle($0)
        })
    }
}

extension UIButton {
    func applyStyles(_ styles: [HTTheme.Style]) {
        styles.forEach({
            self.applyStyle($0)
        })
    }
    
    func applyStyle(_ style: HTTheme.Style) {
        switch style {
        case .background(let color):
            backgroundColor = color
        case .textColor(let color):
            setTitleColor(color, for: .normal)
        case .font(let font):
            self.titleLabel?.font = font
        default:
            super.applyBaseStyle(style)
        }
    }
}

public protocol HTAnnotationStyleProtocol: class {
    var pulseColor: UIColor? { get set }
    var annotationImage: UIImage?  { get set }
    var imageView: UIImageView?  { get set }
    var scaleFactor: CGFloat  { get set }
    var animationDuration: Double  { get set }
    var animationDelay: Double  { get set }
    var size: CGSize  { get set }
    var annotationColor: UIColor? { get set }
    var isPulsating: Bool { get set }

}

extension HTAnnotationStyleProtocol {
    public func applyStyles(_ styles: [HTTheme.AnnotationStyle]) {
        styles.forEach({
            self.applyStyle($0)
        })
    }
    
    public func applyStyle(_ style: HTTheme.AnnotationStyle) {
        switch style {
        case .color(let color):
            annotationColor = color
        case .pulseColor(let color):
            pulseColor = color
        case .scaleFactor(let factor):
            scaleFactor = factor
        case .size(let size):
            self.size = size
        case .pulsating(let pulsating):
            isPulsating = pulsating
        case .image(let image):
            self.annotationImage = image
        }
    }
    
    public func applyStyles(_ metaData: HTAnnotationData.MetaData) {
        switch metaData.type {
        case .destination:
            applyStyles([
                .image(HTProvider.style.markerImages.destination),
                .size(HTProvider.destinationMarkerSize),
                .pulsating(false),
                ])
            if let image = HTProvider.mapCustomizationDelegate?.expectedPlaceMarkerImage?() {
                applyStyles([
                    .image(image),
                    ])
            } else if let actionInfo = metaData.actionInfo, let image = HTProvider.mapCustomizationDelegate?.expectedPlaceMarkerImage?(actionInfo: actionInfo) {
                applyStyles([
                    .image(image),
                    ])
            } else {
                applyStyles([
                    .image(HTProvider.style.markerImages.destination),
                    ])
            }
        case .error:
            applyStyles([
                .size(HTProvider.userMarkerSize),
                .pulsating(false),
                ])
            if let image = HTProvider.mapCustomizationDelegate?.userMarkerImage?(annotationType: .error) {
                applyStyles([
                    .image(image),
                    ])
            } else if let actionInfo = metaData.actionInfo, let image = HTProvider.mapCustomizationDelegate?.userMarkerImage?(actionInfo: actionInfo) {
                applyStyles([
                    .image(image),
                    ])
            } else {
                applyStyles([
                    .image(HTProvider.style.markerImages.offline),
                    ])
            }
        case .user:
            applyStyles([
                .color(HTProvider.style.colors.primary),
                .pulsating(false),
                .size(HTProvider.userMarkerSize),
                ])
            if let image = HTProvider.mapCustomizationDelegate?.userMarkerImage?(annotationType: .user) {
                applyStyles([
                    .image(image),
                    ])
            } else if let actionInfo = metaData.actionInfo, let image = HTProvider.mapCustomizationDelegate?.userMarkerImage?(actionInfo: actionInfo) {
                applyStyles([
                    .image(image),
                    ])
            } else {
                applyStyles([
                    .image(metaData.activityType.getMarkerImage()),
                    ])
            }
        case .currentUser:
            applyStyles([
                .color(HTProvider.style.colors.brand),
                .pulsating(HTProvider.shouldShowPulsatingMarkers),
                .size(HTProvider.userMarkerSize),
                ])
            if let image = HTProvider.mapCustomizationDelegate?.userMarkerImage?(annotationType: .currentUser) {
                applyStyles([
                    .image(image),
                    ])
            } else if let actionInfo = metaData.actionInfo, let image = HTProvider.mapCustomizationDelegate?.userMarkerImage?(actionInfo: actionInfo) {
                applyStyles([
                    .image(image),
                    ])
            } else {
                applyStyles([
                    .image(metaData.activityType.getMarkerImage()),
                    ])
            }
        default:
            break
        }
    }
}

extension UITextField {
    func addLeftView(_ width: CGFloat) {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: width, height: max(bounds.height, 1)))
        leftView = view
        leftViewMode = .always
    }
}

extension UIImage {
    public static func getImageFromHTBundle(named: String) -> UIImage? {
        return UIImage(named: named, in: Settings.getBundle(), compatibleWith: nil)
    }
}
