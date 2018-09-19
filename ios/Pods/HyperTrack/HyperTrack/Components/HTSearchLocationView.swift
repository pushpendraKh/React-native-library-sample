//
//  HTSearchLocationView.swift
//  SDKTest
//
//  Created by Atul Manwar on 15/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

@objc public protocol HTAuxillaryFlowDelegate: class {
    func cancelClicked()
}

@objc public protocol HTPlaceSelectionDelegate: HTAuxillaryFlowDelegate {
    func expectedPlaceSet(_ data: HTPlace)
}

@objc public protocol HTPrimaryActionIntDelegate: HTAuxillaryFlowDelegate {
    func primaryActionClicked(_ data: Int)
}

public protocol HTShareEtaDelegate: HTPrimaryActionIntDelegate {
    func updatedQuery(_ query: String)
    func handleSpecialCase(_ selection: HTLocationSearchProvider.SearchLocationType)
}

final class HTSearchLocationView: UIView {
    fileprivate (set) var textField: UITextField! {
        didSet {
            textField.tintColor = HTProvider.style.colors.gray
            textField.placeholder = "Add destination to share ETA"
            textField.addLeftView(15)
            textField.clearButtonMode = .whileEditing
        }
    }
    fileprivate (set) var tableView: UITableView!
    weak var actionDelegate: HTAuxillaryFlowDelegate?

    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            removeConstraints(constraints)
            tableView.removeConstraints(tableView.constraints)
            textField.removeConstraints(textField.constraints)
            addConstraints([
                textField.top(constant: padding.top),
                textField.bottom(tableView, toAttribute: .top, constant: -padding.verticalInterItem),
                textField.right(constant: -padding.right),
                tableView.left(constant: padding.left),
                tableView.right(constant: -padding.right),
                tableView.bottom(constant: -padding.bottom),
                textField.left(constant: padding.left),
                ])
            textField.addConstraint(
                textField.height(constant: 45)
            )
            tableView.addConstraint(
                tableView.height(constant: UIScreen.main.bounds.height/4)
            )
        }
    }
    
    var delegate: UITableViewDelegate? = nil {
        didSet {
            tableView.delegate = delegate
        }
    }
    
    var dataSource: UITableViewDataSource? = nil {
        didSet {
            tableView.dataSource = dataSource
            reloadData()
        }
    }
    
    func reloadData() {
        tableView.reloadData()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews(padding)
    }
    
    convenience init(frame: CGRect, padding: HTPaddingProviderProtocol) {
        self.init(frame: frame)
        defer {
            self.padding = padding
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubViews(padding)
    }
    
    func clear() {
        textField.text = ""
        tableView.reloadData()
    }
    
    fileprivate func setupSubViews(_ padding: HTPaddingProviderProtocol) {
        translatesAutoresizingMaskIntoConstraints = false
        textField = UITextField(frame: .zero)
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.estimatedRowHeight = 50
        tableView.keyboardDismissMode = .onDrag
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView(frame: .zero)
        addSubview(textField)
        addSubview(tableView)
        textField.applyBaseStyles([
            .background(HTProvider.style.colors.lightGray),
            ])
        textField.textColor = HTProvider.style.colors.secondary
        textField.font = HTProvider.style.fonts.getFont(.info, weight: .regular)
        self.padding = padding
    }
    
    @objc func cancelButtonClicked() {
        textField.resignFirstResponder()
        actionDelegate?.cancelClicked()
    }
}

extension HTSearchLocationView: HTViewProtocol {
}

public protocol HTLocationSearchProviderProtocol: UITableViewDelegate, UITableViewDataSource {
    var data: [HTPlace] { get set }
    var enableCurrentLocationSelection: Bool { get set }
    var enableChooseOnMapSelection: Bool { get set }
    var searchBarPlaceHolderText: String { get set }
    var contentView: UIView { get }
    init(_ data: [HTPlace])
    var selectedResult: HTPlace? { get set }
    var delegate: HTShareEtaDelegate? { get set }
    func updateData(_ data: [HTPlace])
    func reloadData()
    func clear()
}

public final class HTLocationSearchProvider: NSObject, HTLocationSearchProviderProtocol {
    public var data: [HTPlace] = []
    public var selectedResult: HTPlace?
    fileprivate let identifier = "htLocationSearchCell"
    fileprivate var tableViewContainer: HTSearchLocationView!
    public weak var delegate: HTShareEtaDelegate? {
        didSet {
            tableViewContainer.actionDelegate = delegate
        }
    }
    
    public var searchBarPlaceHolderText: String = "" {
        didSet {
            guard tableViewContainer != nil else { return }
            tableViewContainer.textField.placeholder = searchBarPlaceHolderText
        }
    }
    
    public var enableCurrentLocationSelection: Bool = true {
        didSet {
            reloadData()
        }
    }
    
    public var enableChooseOnMapSelection: Bool  = true {
        didSet {
            reloadData()
        }
    }
    
    public var contentView: UIView {
        return tableViewContainer
    }
    
    public convenience override init() {
        self.init([])
    }

    public init(_ data: [HTPlace]) {
        self.data = data
        super.init()
        commonInit()
    }
    
    public func updateData(_ data: [HTPlace]) {
        self.data = data
    }
    
    public func reloadData() {
        tableViewContainer.reloadData()
    }
    
    public func clear() {
        updateData([])
        tableViewContainer.clear()
        reloadData()
    }
    
    fileprivate func commonInit() {
        tableViewContainer = HTSearchLocationView(frame: .zero, padding: HTPaddingProvider(top: 42, left: 40, right: 40, bottom: 30, verticalInterItem: 8, horizontalInterItem: 8))
        tableViewContainer.dataSource = self
        tableViewContainer.delegate = self
        tableViewContainer.textField.delegate = self
    }
    
    public enum SearchLocationType: Int {
        case current = 1
        case usingMap = 0
        case total = 2
    }
}

extension HTLocationSearchProvider: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count + SearchLocationType.total.rawValue
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case SearchLocationType.current.rawValue:
            if !enableCurrentLocationSelection {
                return UITableViewCell(frame: .zero)
            }
            let cell = createAndInitializeCell(tableView, identifier: identifier, text: "Use my current location", detailText: "")
            cell?.imageView?.image = UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.AddressResult.current)
            cell?.textLabel?.applyStyles([
                .textColor(HTProvider.style.colors.brand),
                .font(HTProvider.style.fonts.getFont(.normal, weight: .bold))
                ])
            return cell!
        case SearchLocationType.usingMap.rawValue:
            if !enableChooseOnMapSelection {
                return UITableViewCell(frame: .zero)
            }
            let cell = createAndInitializeCell(tableView, identifier: identifier, text: "Set location on map", detailText: "")
            cell?.imageView?.image = UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.selectOnMap)
            cell?.textLabel?.applyStyles([
                .textColor(HTProvider.style.colors.default),
                .font(HTProvider.style.fonts.getFont(.normal, weight: .bold))
                ])
            return cell!
        default:
            let result = data[indexPath.row - SearchLocationType.total.rawValue]
            let cell = createAndInitializeCell(tableView, identifier: identifier, text: result.displayName, detailText: result.address)
            cell?.imageView?.image = UIImage.getImageFromHTBundle(named: HTConstants.ImageNames.AddressResult.new)
            return cell!
        }
    }
    
    fileprivate func createAndInitializeCell(_ tableView: UITableView, identifier: String, text: String, detailText: String) -> UITableViewCell? {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        }
        cell?.textLabel?.text = text
        cell?.detailTextLabel?.text = detailText
        cell?.backgroundColor = .clear
        cell?.selectionStyle = .default
        cell?.textLabel?.applyStyles([
            .font(HTProvider.style.fonts.getFont(.info, weight: .regular)),
            .textColor(HTProvider.style.colors.secondary)
            ])
        cell?.detailTextLabel?.applyStyles([
            .font(HTProvider.style.fonts.getFont(.info, weight: .regular)),
            .textColor(HTProvider.style.colors.gray)
            ])
        return cell
    }
}

extension HTLocationSearchProvider: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case SearchLocationType.current.rawValue:
            delegate?.handleSpecialCase(.current)
        case SearchLocationType.usingMap.rawValue:
            delegate?.handleSpecialCase(.usingMap)
        default:
            selectedResult = data[indexPath.row - SearchLocationType.total.rawValue]
            delegate?.primaryActionClicked(indexPath.row - SearchLocationType.total.rawValue)
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case SearchLocationType.current.rawValue:
            return enableCurrentLocationSelection ? 40 : 0
        case SearchLocationType.usingMap.rawValue:
            return enableChooseOnMapSelection ? 50 : 0
        default:
            return 50
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}

extension HTLocationSearchProvider: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        delegate?.updatedQuery((textField.text! as NSString).replacingCharacters(in: range, with: string))
        return true
    }
}

public struct HTLocationSearchResult {
    let title: String
}
