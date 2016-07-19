//
//  GeneralSearchResultSegmentedTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class GeneralSearchResultSegmentedTableViewCell: SegmentedTableViewCell {

    @IBOutlet weak private var zoomCover: UIButton!
    
    @IBOutlet weak private var titleText: UILabel!
    @IBOutlet weak private var subtitleText: UILabel!
    @IBOutlet weak private var authorNameText: UILabel!
    @IBOutlet weak private var viewAuthorDetail: UIButton!
    
    @IBOutlet weak private var editionCount: UILabel!
    @IBOutlet weak private var viewWorkDetail: UIButton!

    @IBOutlet weak private var languageNames: UILabel!
    
    @IBOutlet weak private var firstPublished: UILabel!
    
    @IBOutlet weak private var eBookCount: UILabel!
    @IBOutlet weak private var viewBooks: UIButton!

    var delegate: UITableViewController?

    var isZoomEnabled = false
    var haveEditions = false
    var haveEbooks = false
    
    @IBAction private func zoomCoverTapped(sender: UIButton) {
        
        if !isAnimating() {
            
        }
    }
    
    @IBAction private func viewAuthorDetailTapped(sender: UIButton) {
        
        if !isAnimating() {
            
        }
    }
    
    @IBAction private func viewBooksTapped( sender: UIButton ) {

        if !isAnimating() {
            
            if let delegate = delegate, tableView = delegate.tableView {
                
                // [[[event touchesForView: button] anyObject] locationInView: self.tableView]]
                if let indexPath = tableView.indexPathForRowAtPoint( sender.superview!.convertPoint( sender.center, toView: tableView ) ) {
                    
                    delegate.tableView( tableView, accessoryButtonTappedForRowWithIndexPath: indexPath )
                }
            }
        }
    }
    
    @IBAction private func viewWorkEditionsTapped(sender: UIButton) {

        if !isAnimating() {
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        
        updateButtons( selected )
    }

    private func updateButtons( selected: Bool ) {

        zoomCover.enabled = selected && isZoomEnabled
        viewAuthorDetail.enabled = selected
        viewWorkDetail.enabled = selected && haveEbooks
        viewBooks.enabled = selected && haveEditions
    }

    func configure( delegate: UITableViewController, indexPath: NSIndexPath, generalResult: OLGeneralSearchResult? ) {
        
        self.delegate = delegate
        
        configureCell( delegate.tableView, indexPath: indexPath )
        
        if let r = generalResult {

            titleText.text = r.title
            subtitleText.text = r.subtitle
            authorNameText.text = r.author_name.joinWithSeparator( ", " )
            
            editionCount.text = String( r.edition_count )
            languageNames.text = r.language_names.joinWithSeparator( ", " )
            
            firstPublished.text = String( r.first_publish_year )
            
            eBookCount.text = String( r.ebook_count_i )
            
            isZoomEnabled = r.hasImage
            haveEbooks = 0 < r.ebook_count_i
            haveEditions = 0 < r.edition_count

        } else {
            
            titleText.text = ""
            subtitleText.text = ""
            authorNameText.text = ""
            
            editionCount.text = ""
            languageNames.text = ""
            
            firstPublished.text = ""
            
            isZoomEnabled = false
            haveEbooks = false
            haveEditions = false
        }
        
        clearCurrentImage()
        
        updateButtons( selected )
        
        setNeedsLayout()
        layoutIfNeeded()
        
        adjustCellHeights( indexPath )
        
//        delegate.tableView.beginUpdates()
//        delegate.tableView.endUpdates()
    }

}
