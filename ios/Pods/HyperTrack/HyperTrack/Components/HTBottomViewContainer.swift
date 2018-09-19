//
//  HTBottomViewContainer.swift
//  SDKTest
//
//  Created by Atul Manwar on 13/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

struct Shadow {
    let offset: CGSize
    let blur: CGFloat
    let color: UIColor
}

public class HTBottomViewContainer: UIView {
    fileprivate enum Properties {
        static let cornerRadius: CGFloat = 10.0
        static let shadow: Shadow = Shadow(offset: CGSize(), blur: 10.0, color: HTProvider.style.colors.dropShadow)
    }
    @IBInspectable public var isShadowEnabled: Bool = false {
        didSet {
            if isShadowEnabled {
                if shadowView != nil {
                    return
                } else {
                    let shadowView = setupShadowView()
                    shadowView.translatesAutoresizingMaskIntoConstraints = false
                    let radius = Properties.shadow.blur
                    insertSubview(shadowView, at: 0)
                    shadowView.edges(UIEdgeInsets(top: -radius, left: -radius, bottom: radius, right: radius))
                    self.shadowView = shadowView
                }
            } else {
                shadowView?.removeFromSuperview()
                shadowView = nil
            }
        }
    }
    @IBInspectable public var isBlurEnabled: Bool = false {
        didSet {
            if isBlurEnabled {
                if visualEffectView != nil {
                    return
                } else {
                    backgroundColor = .clear
                    let visualEffectView = setupVisualEffectView()
                    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
                    insertSubview(visualEffectView, at: 1)
                    visualEffectView.edges()
                    self.visualEffectView = visualEffectView
                    if let contentView = contentView {
                        contentView.removeFromSuperview()
                        visualEffectView.contentView.addSubview(contentView)
                    }
                }
            } else {
                visualEffectView?.removeFromSuperview()
                visualEffectView = nil
            }
        }
    }
    fileprivate var visualEffectView: UIVisualEffectView?
    fileprivate var shadowView: UIImageView?
    fileprivate var contentView: UIView?
    
    public func setContentView(_ contentView: UIView?) {
        self.contentView?.removeFromSuperview()
        self.contentView = contentView
        guard let contentView = contentView else { return }
        if isBlurEnabled {
            visualEffectView?.contentView.addSubview(contentView)
        } else {
            addSubview(contentView)
        }
    }

    public convenience init() {
        self.init(frame: CGRect())
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        applyBaseStyles([
            .background(HTProvider.style.colors.default)
            ])
    }

    fileprivate func setupVisualEffectView() -> UIVisualEffectView {
        let view = HTViewFactory.createVisualEffectView(true)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = Properties.cornerRadius
        view.layer.masksToBounds = true
        return view
    }
    
    fileprivate func setupShadowView() -> UIImageView {
        let image = resizeableShadowImage (
            withCornerRadius: Properties.cornerRadius,
            shadow: Properties.shadow
        )
        let view = UIImageView(image: image)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    fileprivate func resizeableShadowImage(
        withCornerRadius cornerRadius: CGFloat,
        shadow: Shadow
        ) -> UIImage {
        
        let sideLength = cornerRadius * 5
        return UIImage.resizableShadowImage(
            withSideLength: sideLength,
            cornerRadius: cornerRadius,
            shadow: shadow
        )
    }
}
