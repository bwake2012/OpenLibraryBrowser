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
    @IBOutlet weak var displayAuthorDetail: UIButton!
    
    @IBAction func touchedAuthorName(sender: AnyObject) {

        setSelected( true, animated: true )
    }
    
    override func configure( tableView: UITableView, key: String, data: OLManagedObject? ) {
        
        assert( NSThread.isMainThread() )
        
        if let r = data as? OLGeneralSearchResult {
            titleText.text = "\(r.title)"
            authorName.text = r.author_name.joinWithSeparator( ", " )
            
            displayAuthorDetail.enabled = !r.author_name.isEmpty
            
//            titleText.text = "\(r.sequence).\(r.index) \(r.title)"
//            authorName.text = "\(r.key) \(r.author_name.joinWithSeparator( ", " )"
        } else {
            titleText.text = ""
            authorName.text = ""
        }
        
        clearCurrentImage()
    }
    
    override func clearCurrentImage() -> Void {
        
        assert( NSThread.isMainThread() )
        
        currentImageFile = nil
        cellImage.image = UIImage( named: "961-book-32.png" )
    }
}
