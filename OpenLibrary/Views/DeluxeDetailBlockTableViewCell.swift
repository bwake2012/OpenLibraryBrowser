//
//  DeluxeDetailBlockTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailBlockTableViewCell: DeluxeDetailTableViewCell {

    @IBOutlet weak var captionView: UILabel!
    @IBOutlet weak var blockTextView: UILabel!
    
    override func configure( data: DeluxeData ) {
        
        assert( NSThread.isMainThread() )
        
        captionView.text = data.caption
        blockTextView.text = data.value
    }
}

