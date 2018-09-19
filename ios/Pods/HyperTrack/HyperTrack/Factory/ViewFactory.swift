//
//  ViewFactory.swift
//  SDKTest
//
//  Created by Atul Manwar on 13/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

public class HTBottomViewFactory {
    public class Order {
        public static func getOrderSummaryInfoView(_ data: HTOrderTrackingBottomCard.Data.OrderInfoArray) -> HTStackViewItem {
            let infoViews: [HTInfoView] = data.values.map({
                let infoView = HTInfoView(frame: .zero, padding: HTPaddingProvider(top: 10, left: 26, right: 26, bottom: 5, verticalInterItem: 3, horizontalInterItem: 8))
                infoView.titleText = $0.title
                infoView.descriptionText = $0.description
                infoView.titleLabel.applyStyles([.textColor(HTProvider.style.colors.gray)])
                infoView.descriptionLabel.applyStyles([.textColor(HTProvider.style.colors.secondary), .font(HTProvider.style.fonts.getFont(.info, weight: .bold))])
                return infoView
            })
            let stackView = UIStackView(frame: .zero)
            stackView.axis = .vertical
            var tempStackView: UIStackView!
            var lastView: UIView!
            for i in 0..<infoViews.count {
                let infoView = infoViews[i]
                if i % 2 == 1 {
                    let view = HTViewFactory.createVerticalSeparatorView(1, backgroundColor: HTProvider.style.colors.gray.withAlphaComponent(0.5))
                    tempStackView.addArrangedSubview(view)
                    tempStackView.addConstraints([
                        view.top(constant: 10),
                        view.bottom(constant: -5)
                        ])
                    infoView.titleLabel.textAlignment = .left
                    infoView.descriptionLabel.textAlignment = .left
                    tempStackView.addArrangedSubview(infoView)
                    tempStackView.addConstraint(
                        infoView.width(lastView)
                    )
                    stackView.addArrangedSubview(tempStackView)
                } else {
                    infoView.titleLabel.textAlignment = .right
                    infoView.descriptionLabel.textAlignment = .right
                    tempStackView = UIStackView(frame: .zero)
                    tempStackView.axis = .horizontal
                    tempStackView.translatesAutoresizingMaskIntoConstraints = false
                    tempStackView.addArrangedSubview(infoView)
                }
                lastView = infoView
            }
            let view = UIView(frame: .zero)
            view.addConstraint(
                view.height(constant: 30)
            )
            stackView.addArrangedSubview(view)
            let stackViewItem = HTStackViewItem(frame: .zero)
            stackViewItem.addSubview(stackView)
            stackView.edges()
            return stackViewItem
        }
        
        public static func getOrderStatusView(_ data: HTOrderTrackingBottomCard.Data.OrderStatus) -> HTStackViewItem {
            let orderStatusView = HTOrderStatusView(frame: .zero, padding: HTPaddingProvider(top: 26, left: 20, right: 20, bottom: 26, verticalInterItem: 1, horizontalInterItem: 8))
            orderStatusView.text = data.title
            orderStatusView.image = data.image
            return orderStatusView
        }
    }
}

public class HTViewFactory {
    public static func createVisualEffectView(_ vibrancy: Bool = true) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
        let view = UIVisualEffectView(effect: blurEffect)
        if vibrancy {
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            view.contentView.addSubview(vibrancyView)
        }
        return view
    }
    
    public static func createBottomViewContainer(_ enableBlur: Bool = true, enableShadow: Bool = true) -> HTBottomViewContainer {
        let bottomView = HTBottomViewContainer(frame: .zero)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.applyBaseStyles([.radius(HTProvider.style.layer.cornerRadius)])
        bottomView.isBlurEnabled = enableBlur
        bottomView.isShadowEnabled = enableShadow
        return bottomView
    }
    
    public static func createVerticalSeparatorView(_ width: CGFloat, backgroundColor: UIColor) -> HTBaseView {
        let view = HTBaseView(frame: .zero)
        view.backgroundColor = backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(
            view.width(constant: width)
        )
        return view
    }
    
    public static func createHorizontalSeparatorView(_ height: CGFloat, backgroundColor: UIColor) -> HTBaseView {
        let view = HTBaseView(frame: .zero)
        view.backgroundColor = backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraint(
            view.height(constant: height)
        )
        return view
    }

    public static func createPrimaryActionButton(_ text: String) -> HTButton {
        let button = HTButton(frame: .zero)
        button.setTitle(text, for: .normal)
        button.applyStyles([
            .radius(HTProvider.style.layer.cornerRadius),
            .textColor(HTProvider.style.colors.text),
            .font(HTProvider.style.fonts.getFont(.caption, weight: .bold)),
            .background(HTProvider.style.colors.default)
            ])
        return button
    }
    
    public static func createPrimaryActionView(_ text: String) -> UIView {
        return createPrimaryActionView(button: createPrimaryActionButton(text))
    }
    
    public static func createPrimaryActionView(button: UIButton) -> UIView {
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 30, bottom: 15, right: 30)
        let leftView = UIView(frame: .zero)
        leftView.addConstraint(leftView.width(constant: 36))
        let rightView = UIView(frame: .zero)
        rightView.addConstraint(rightView.width(constant: 36))
        let stackView = UIStackView(frame: .zero)
        [leftView, button, rightView].forEach({stackView.addArrangedSubview($0)})
        stackView.axis = .horizontal
        return stackView
    }
}
