//
//  AuthorDeluxeDetailLinkTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/29/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailLinkTableViewCell: DeluxeDetailTableViewCell {

    @IBOutlet weak var linkView: UILabel!

    var linkURL: String?

    override func configure( _ data: DeluxeData ) {
        
        assert( Thread.isMainThread )
        
        linkView.text = data.caption
        linkURL = data.value
    }
}

