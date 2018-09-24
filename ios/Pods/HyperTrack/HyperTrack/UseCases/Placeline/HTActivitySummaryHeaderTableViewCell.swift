//
//  HTActivitySummaryHeaderTableViewCell.swift
//  HyperTrack
//
//  Created by Atul Manwar on 22/03/18.
//  Copyright © 2018 HyperTrack. All rights reserved.
//

import UIKit

final class HTActivitySummaryHeaderTableViewCell: UITableViewCell {
    fileprivate (set) var headerView: HTActivitySummaryHeaderView!
    
    var padding: HTPaddingProviderProtocol = HTPaddingProvider.default {
        didSet {
            headerView.padding = padding
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupSubviews(padding)
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
        setupSubviews(padding)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    fileprivate func setupSubviews(_ padding: HTPaddingProviderProtocol) {
        headerView = HTActivitySummaryHeaderView(frame: .zero, padding: padding)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        headerView.edges()
        headerView.isSeparatorHidden = false
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    func initialize(_ summary: HTPlaceline.ActivitySummary?) {
        headerView.setSummaryInfo(summary)
    }
}
