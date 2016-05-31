//
//  GeneralSearchResultTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/18/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class GeneralSearchResultTableViewCell: OLTableViewCell {

    var delegate: UITableViewController?
    
    @IBOutlet weak var titleText: UILabel!
    @IBOutlet weak var authorName: UILabel!
    
    @IBAction func touchedAuthorName(sender: AnyObject) {

        setSelected( true, animated: true )
        delegate!.performSegueWithIdentifier( "displayGeneralSearchAuthorDetail", sender: self )
    }
    
    func configure( delegate: UITableViewController, generalResult: OLGeneralSearchResult? ) {
        
        self.delegate = delegate

        if let r = generalResult {
            titleText.text = "\(r.title)"
            authorName.text = r.author_name.joinWithSeparator( ", " )
//            titleText.text = "\(r.sequence).\(r.index) \(r.title)"
//            authorName.text = "\(r.key) \(r.author_name.joinWithSeparator( ", " )"
        } else {
            titleText.text = ""
            authorName.text = ""
        }
        
        clearCurrentImage()
    }
    
    override func clearCurrentImage() -> Void {
        
        currentImageURL = nil
        cellImage.image = UIImage( named: "961-book-32.png" )
    }
}
