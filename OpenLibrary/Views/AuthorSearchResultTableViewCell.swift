//
//  OLAuthorSearchResultTableviewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/24/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class AuthorSearchResultTableViewCell: OLTableViewCell {

    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var authorInfo: UILabel!
    
    func configure( result: OLAuthorSearchResult? ) {
        
        if let r = result {
            authorName.text = "\(r.sequence).\(r.index) \(r.name)"
            authorInfo.text = "\(r.key) \(r.top_work!)"
        } else {
            authorName.text = ""
            authorInfo.text = ""
        }
        
        clearCurrentImage()
    }

    override func clearCurrentImage() -> Void {
        
        currentImageURL = nil
        cellImage.image = UIImage( named: "253-person.png" )
    }
}
