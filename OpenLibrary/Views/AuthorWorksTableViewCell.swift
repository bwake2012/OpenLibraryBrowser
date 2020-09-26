//
//  AuthorWorksTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class AuthorWorksTableViewCell: OLTableViewCell {

    @IBOutlet weak var workTitle: UILabel!
    @IBOutlet weak var workSubTitle: UILabel!

    override func configure( _ tableView: UITableView, indexPath: IndexPath, key: String, data: OLManagedObject? ) {
        
        assert( Thread.isMainThread )
        
        if let entry = data as? OLWorkDetail {
            
            workTitle.text = entry.title
            workSubTitle.text = entry.subtitle
            // workSubTitle.text = "\(entry.index) \(entry.key) \(entry.subtitle)"
            
        } else {

            workTitle.text = ""
            workSubTitle.text = ""
        }

        clearCurrentImage()
    }
    
    override func prepareForReuse() {
        
        workTitle.text = ""
        workSubTitle.text = ""
        
        cellImage.image = nil
    }
}
