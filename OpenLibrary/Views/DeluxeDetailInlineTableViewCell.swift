//
//  DeluxeDetailInlineTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailInlineTableViewCell: DeluxeDetailTableViewCell {

    @IBOutlet weak var captionView: UILabel!
    @IBOutlet weak var inlineTextView: UILabel!

    override func configure( _ data: DeluxeData ) {
        
        assert( Thread.isMainThread )
        
        captionView.text = data.caption
        inlineTextView.text = data.value
    }
}

