//
//  HTPlaceLineTableViewCell.swift
//  SDKTest
//
//  Created by Atul Manwar on 20/02/18.
//  Copyright © 2018 www.hypertrack.com. All rights reserved.
//

import UIKit

final class HTPlaceLineTableViewCell: UITableViewCell {
    fileprivate var placeLineContentView: HTPlaceLineView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews(padding)
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            placeLineContentView.padding = padding
        }
    }
    
    convenience init(style: UITableViewCellStyle, reuseIdentifier: String?, padding: HTPaddingProviderProtocol) {
        self.init(style: style, reuseIdentifier: reuseIdentifier)
        defer {
            self.padding = padding
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews(padding)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        placeLineContentView.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func initialize(_ data: HTPlaceline.DisplayData.ActivityInfo) {
//        placeLineContentView.actionIdDisplayText = data.id ?? ""
//        placeLineContentView.actionDescriptionText = data.
        placeLineContentView.activityDescription = data.descriptionText
        placeLineContentView.activityType = data.activityType
        placeLineContentView.moreInfoAvailable = data.moreInfoAvailable
    }

    fileprivate func setupSubviews(_ padding: HTPaddingProviderProtocol) {
        placeLineContentView = HTPlaceLineView(frame: .zero, padding: padding)
        contentView.addSubview(placeLineContentView)
        placeLineContentView.edges()
        self.padding = padding
        backgroundColor = .clear
        selectionStyle = .none
        separatorInset = .zero
    }
}
