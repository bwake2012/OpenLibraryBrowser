//
//  DeluxeDetailBookDownloadEditionTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/28/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class DeluxeDetailBookDownloadEditionTableViewCell: DeluxeDetailTableViewCell {

    @IBOutlet weak var captionView: UILabel!
    @IBOutlet weak var inlineTextView: UILabel!

    override func configure( data: DeluxeData ) {
        
        captionView.text = data.caption
        inlineTextView.text = data.value
    }
}

extension DeluxeDetailBookDownloadEditionTableViewCell {
    
    override class func registerCell( tableView: UITableView ) {
        
        registerCell( tableView, className: DeluxeDetail.downloadBookEdition.rawValue )
    }
    
}