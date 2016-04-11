//
//  OLTitleSearchResultTableviewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/10/2016.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class TitleSearchResultTableViewCell: OLTableViewCell {

    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var subtitleText: UILabel!
    
    func configure( result: OLTitleSearchResult? ) {
        
        if let r = result {
            titleText.text = "\(r.sequence).\(r.index) \(r.title)"
            subtitleText.text = "\(r.key) \(r.subtitle)"
        } else {
            titleText.text = ""
            subtitleText.text = ""
        }
        
        clearCurrentImage()
    }
}
