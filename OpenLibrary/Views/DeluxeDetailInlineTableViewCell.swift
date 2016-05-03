//
//  DeluxeDetailInlineTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailInlineTableViewCell: UITableViewCell {

    @IBOutlet weak var captionView: UILabel!
    @IBOutlet weak var inlineTextView: UILabel!

    func configure( data: DeluxeData ) {
        
        captionView.text = data.caption
        inlineTextView.text = data.value
    }
}
