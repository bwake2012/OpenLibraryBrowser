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
    
    override func configure( _ data: DeluxeData ) {
        
        assert( Thread.isMainThread )
        
        label.text = data.value
    }
}

