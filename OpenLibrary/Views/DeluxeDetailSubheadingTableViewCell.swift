//
//  DeluxeDetailSubheadingTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/3/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailSubheadingTableViewCell: DeluxeDetailTableViewCell {

    @IBOutlet weak var label: UILabel!
    
    override func configure( data: DeluxeData ) {
        
        assert( NSThread.isMainThread() )
        
        label.text = data.value
    }
}

