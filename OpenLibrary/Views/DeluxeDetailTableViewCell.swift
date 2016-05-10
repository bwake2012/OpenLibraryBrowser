//
//  DeluxeDetailTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/4/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure( data: DeluxeData ) {
        
    }
}

extension DeluxeDetailTableViewCell {
    
    class func registerCell( tableView: UITableView, className: String ) {

        let nib = UINib( nibName: className, bundle: nil )
        
        tableView.registerNib( nib, forCellReuseIdentifier: className )
    }
    
    class func registerCell( tableView: UITableView ) {
        
        registerCell( tableView, className: "" )
    }
}