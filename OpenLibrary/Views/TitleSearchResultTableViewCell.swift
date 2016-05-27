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
    
    func configure( titleResult: OLTitleSearchResult? ) {
        
        if let r = titleResult {
            titleText.text = "\(r.sequence).\(r.index) \(r.title)"
            subtitleText.text = "\(r.key) \(r.subtitle)"
        } else {
            titleText.text = ""
            subtitleText.text = ""
        }
        
        clearCurrentImage()
    }

    override func clearCurrentImage() -> Void {
        
        currentImageURL = nil
        cellImage.image = UIImage( named: "961-book-32.png" )
    }
}
