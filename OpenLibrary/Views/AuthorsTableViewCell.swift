//
//  AuthorsTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/14/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class AuthorsTableViewCell: OLTableViewCell {

    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var birthDate: UILabel!
    @IBOutlet weak var deathDate: UILabel!
    
    override func prepareForReuse() {
        
        authorName.text = ""
        
        cellImage.image = nil
    }

    override func configure(_ tableView: UITableView, indexPath: IndexPath, key: String, data: OLManagedObject?) {
        
        if let data = data as? OLAuthorDetail {
            
            authorName.text = data.name
            
            self.birthDate.text =
                data.birth_date.isEmpty ? nil : "Born: " + data.birth_date.stringWithNonBreakingSpaces()
            self.deathDate.text =
                data.death_date.isEmpty ? nil : "Died: " + data.death_date.stringWithNonBreakingSpaces()

            if data.hasImage {
                
                cellImage.image = nil

            } else {
                
                cellImage.image = UIImage( named: "253-person" )
            }
        }
    }
}
