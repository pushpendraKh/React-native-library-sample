//
//  HTReusableStackView.swift
//  HyperTrack
//
//  Created by Atul Manwar on 08/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

@objc public protocol HTReusableStackViewDelegate: class {
}

@objc public protocol HTReusableStackViewDataSource: class {
    func numberOfItems(in stackView: HTReusableStackView) -> Int
    
    func stackView(_ stackView: HTReusableStackView, viewForRowAt index: Int) -> HTStackViewItem
}

@objc public class HTStackViewItem: UIView {
    var identifier: String = ""
}

@objc public class HTReusableStackView: UIStackView {
    weak var dataSource: HTReusableStackViewDataSource?
    weak var delegate: HTReusableStackViewDelegate?
    fileprivate var dictionary: [String: HTStackViewItem] = [:]
    fileprivate var separators: [UIView] = []
    fileprivate var previousViewIds: [String] = []
    
    var shouldAddSeparators: Bool = true {
        didSet {
            if !shouldAddSeparators {
                separators.forEach({ $0.removeFromSuperview() })
                separators = []
            } else {
                reAddSeparators()
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func reloadData(_ animated: Bool = true, collapsedIndexes: [Int] = []) {
        let numberOfItems = dataSource?.numberOfItems(in: self) ?? 0
        var views: [UIView] = []
        var newViewIds: [String] = []
        for i in 0..<numberOfItems {
            if let view = dataSource?.stackView(self, viewForRowAt: i) {
                views.append(view)
                if !view.identifier.isEmpty {
                    let viewId = "\(view.identifier)|\(i)"
                    newViewIds.append(viewId)
                    dictionary[viewId] = view
                }
                view.isHidden = (animated && collapsedIndexes.contains(i))// || previousViewIds.isEmpty)
            }
        }
        if previousViewIds.elementsEqual(newViewIds, by: { (old, new) -> Bool in
            return (old == new)
        }) {
            return
        } else {
            let diff = difference(old: previousViewIds, new: newViewIds)
            let deletes = diff.delete.sorted(by: {
                return ($0.0.value > $0.1.value)
            })
            func hideSubviews(_ deletes: [(key: String, value: Int)]) {
                deletes.forEach({
                    self.arrangedSubviews[htSafe: $0.value]?.isHidden = true
                })
            }
            
            func firstAnimationCompletionHandler() -> [(key: String, value: Int)] {
                deletes.forEach({
                    if let view = self.arrangedSubviews[htSafe: $0.value] {
                        self.removeArrangedSubview(view)
                    }
                })
                let inserts = diff.insert.sorted(by: {
                    return ($0.0.value < $0.1.value)
                })
                inserts.forEach({
                    if let view = self.dictionary[$0.key] {
                        self.addArrangedSubview(view)
                        view.layoutSubviews()
                    }
                })
                self.reAddSeparators()
                self.layoutSubviews()
                return inserts
            }
            
            func showSubviews(_ inserts: [(key: String, value: Int)]) {
                inserts.reversed().forEach({
                    let isHidden = collapsedIndexes.contains($0.value)
                    self.arrangedSubviews[htSafe: $0.value]?.isHidden = isHidden
                    if self.shouldAddSeparators {
                        self.separators[htSafe: $0.value]?.isHidden = isHidden
                    }
                })
            }
            if animated {
                UIView.animate(withDuration: !deletes.isEmpty ? HTProvider.animationDuration : 0, delay: 0, options: .curveEaseOut, animations: {
                    hideSubviews(deletes)
                }, completion: { (_) in
                    let inserts = firstAnimationCompletionHandler()
                    UIView.animate(withDuration: !inserts.isEmpty ? HTProvider.animationDuration : 0, delay: 0, options: .curveEaseOut, animations: {
                        showSubviews(inserts)
                    }, completion: nil)
                })
            } else {
                hideSubviews(deletes)
                let inserts = firstAnimationCompletionHandler()
                showSubviews(inserts)
            }
            previousViewIds = newViewIds
        }
    }
    
    fileprivate func difference(old: [String], new: [String]) -> (insert: [String: Int], delete: [String: Int]) {
        if old.isEmpty {
            return (insert: new.toDict(), delete: [:])
        } else if new.isEmpty {
            return (insert: [:], delete: old.toDict())
        } else {
            var inserts: [String: Int] = [:]
            var deletes: [String: Int] = [:]
            old.enumerated().forEach({ (index, element) in
                if !new.contains(element) {
                    deletes[element] = index
                }
            })
            new.enumerated().forEach({ (index, element) in
                if !old.contains(element) {
                    inserts[element] = index
                }
            })
            return (insert: inserts, delete: deletes)
        }
    }
    
    func expandItems(_ indexes: [Int], animated: Bool = true) {
        guard indexes.filter({ $0 > (arrangedSubviews.count - 1) }).count == 0 else { return }
        UIView.animate(withDuration: animated ? HTProvider.animationDuration - 0.1 : 0, delay: 0, options: .curveEaseOut, animations: {
            indexes.forEach({
                self.arrangedSubviews[htSafe: $0]?.isHidden = false
//                self.separators[$0].isHidden = false
            })
        }, completion: { (_) in
            indexes.forEach({
                if self.shouldAddSeparators {
                    self.separators[htSafe: $0]?.isHidden = false
                }
            })
        })
    }
    
    func collapseItems(_ indexes: [Int], animated: Bool = true) {
        guard indexes.filter({ $0 > (arrangedSubviews.count - 1) }).count == 0 else { return }
        UIView.animate(withDuration: animated ? HTProvider.animationDuration - 0.1 : 0, delay: 0, options: .curveEaseOut, animations: {
            indexes.forEach({
                self.arrangedSubviews[htSafe: $0]?.isHidden = true
                if self.shouldAddSeparators {
                    self.separators[htSafe: $0]?.isHidden = true
                }
            })
        }, completion: { (_) in
//            indexes.forEach({
//                self.separators[$0].isHidden = true
//            })
        })
    }

    fileprivate func reAddSeparators() {
        guard shouldAddSeparators else { return }
        separators.forEach({ $0.removeFromSuperview() })
        separators = []
        arrangedSubviews.forEach({
            let view = HTViewFactory.createHorizontalSeparatorView(1, backgroundColor: HTProvider.style.colors.lightGray)
            addSubview(view)
            addConstraints([
                view.bottom($0, toAttribute: .bottom),
                view.left(),
                view.right()
                ])
            separators.append(view)
        })
    }
    
    func dequeueReusableView(identifier: String, atIndex: Int) -> HTStackViewItem? {
        if let view = dictionary["\(identifier)|\(atIndex)"] {
            return view
        } else {
            return nil
        }
    }
    
    fileprivate func commonInit() {
        axis = .vertical
    }
}
