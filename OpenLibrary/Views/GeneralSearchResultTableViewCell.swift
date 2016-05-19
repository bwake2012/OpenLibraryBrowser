//
//  GeneralSearchResultTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/18/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class GeneralSearchResultTableViewCell: OLTableViewCell {

    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var authorName: UILabel!
    
    func configure( generalResult: OLGeneralSearchResult? ) {
        
        if let r = generalResult {
            titleText.text = "\(r.sequence).\(r.index) \(r.title)"
            authorName.text = "\(r.key) \(r.author_name)"
        } else {
            titleText.text = ""
            authorName.text = ""
        }
        
        clearCurrentImage()
    }
    
    override func clearCurrentImage() -> Void {
        
        currentImageURL = nil
        cellImage.image = UIImage( named: "96-book.png" )
    }
}
