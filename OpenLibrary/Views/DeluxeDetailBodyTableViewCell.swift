//
//  DeluxeDetailBodyTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/3/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailBodyTableViewCell: DeluxeDetailTableViewCell {
    
    @IBOutlet weak var label: UILabel!
    
    override func configure( data: DeluxeData ) {
        
        label.text = data.value
    }
}

extension DeluxeDetailBodyTableViewCell {
    
    override class func registerCell( tableView: UITableView ) {
        
        registerCell( tableView, className: DeluxeDetail.body.rawValue )
    }
}
