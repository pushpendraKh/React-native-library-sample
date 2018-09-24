//
//  HTStatusAndActionTableViewCell.swift
//  HyperTrack
//
//  Created by Atul Manwar on 05/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

final class HTStatusAndActionTableViewCell: UITableViewCell {
    fileprivate var view: HTStatusAndActionView!
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews(padding)
    }
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            view.padding = padding
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
        
        // Configure the view for the selected state
    }
    
    func initialize(_ data: HTUserTrackingBottomCard.Data.Status, delegate: HTBottomViewUseCaseDelegate? = nil) {
        view.titleText = data.title
        view.actionButtonText = data.actionText
        view.actionType = data.actionType
        view.delegate = delegate
    }
    
    fileprivate func setupSubviews(_ padding: HTPaddingProviderProtocol) {
        view = HTStatusAndActionView(frame: .zero, padding: padding)
        contentView.addSubview(view)
        view.edges()
    }
}
