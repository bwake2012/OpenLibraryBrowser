//
//  AuthorDeluxeDetailLinkTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/29/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class AuthorDeluxeDetailLinkTableViewCell: UITableViewCell {

    @IBOutlet weak var linkView: UILabel!

    var linkURL: String?

    func configure( data: DeluxeData ) {
        
        linkView.text = data.caption
        linkURL = data.value
    }
}
