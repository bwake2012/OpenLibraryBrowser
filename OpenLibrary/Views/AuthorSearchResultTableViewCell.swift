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
    
    override func configure( tableView: UITableView, key: String, data: OLManagedObject? ) {
        
        assert( NSThread.isMainThread() )

        if let r = data as? OLAuthorSearchResult {
            authorName.text = "\(r.name)"
            authorInfo.text = "\(r.top_work)"
//            authorName.text = "\(r.sequence).\(r.index) \(r.name)"
//            authorInfo.text = "\(r.key) \(r.top_work)"
        } else {
            authorName.text = ""
            authorInfo.text = ""
        }
        
        clearCurrentImage()
    }

    override func clearCurrentImage() -> Void {
        
        assert( NSThread.isMainThread() )

        currentImageFile = nil
        cellImage.image = UIImage( named: "253-person.png" )
    }
}
