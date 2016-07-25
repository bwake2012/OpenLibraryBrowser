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
    @IBOutlet weak private var viewAuthorDetail: UIButton!
    
    @IBOutlet weak private var viewWorkDetail: UIButton!

    @IBOutlet weak private var languageNames: UILabel!
    
    @IBOutlet weak private var firstPublished: UILabel!
    
    @IBOutlet weak private var viewBooks: UIButton!

//    var delegate: UITableViewController?

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
            
//            if let delegate = delegate, tableView = delegate.tableView {
//                
//                // [[[event touchesForView: button] anyObject] locationInView: self.tableView]]
//                if let indexPath = tableView.indexPathForRowAtPoint( sender.superview!.convertPoint( sender.center, toView: tableView ) ) {
//                    
//                    delegate.tableView( tableView, accessoryButtonTappedForRowWithIndexPath: indexPath )
//                }
//            }
        }
    }
    
    @IBAction private func viewWorkEditionsTapped(sender: UIButton) {

    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        
        updateButtons( selected )
    }

    private func updateButtons( selected: Bool ) {

        zoomCover.enabled = selected && isZoomEnabled
        
        viewAuthorDetail.enabled = selected
        
        viewWorkDetail.enabled = selected && haveEditions
        
        viewBooks.enabled = selected && haveEbooks
    }

    override func configure( tableView: UITableView, indexPath: NSIndexPath, withData data: AnyObject? ) {
        
        configureCell( tableView, indexPath: indexPath )
        
        if let r = data as? OLGeneralSearchResult {

            titleText.text = r.title
            subtitleText.text = r.subtitle
            viewAuthorDetail.setTitle( r.author_name.joinWithSeparator( ", " ), forState: .Normal )
            
            viewWorkDetail.setTitle( "Editions: " + String( r.edition_count ), forState: .Normal )
            languageNames.text = r.language_names.joinWithSeparator( ", " )
            
            firstPublished.text = String( r.first_publish_year )
            
            isZoomEnabled = r.hasImage
            haveEbooks = 0 < r.ebook_count_i
            haveEditions = 0 < r.edition_count

        } else {
            
            titleText.text = ""
            subtitleText.text = ""
            viewAuthorDetail.setTitle( "", forState: .Normal )
            
            viewWorkDetail.setTitle( "", forState: .Normal )
            languageNames.text = ""
            
            firstPublished.text = ""
            
            viewBooks.setTitle( "", forState: .Normal )

            isZoomEnabled = false
            haveEbooks = false
            haveEditions = false
        }
        
        viewBooks.setTitle(
                "Electronic Editions " + ( haveEbooks ? "found" : "not found" ),
                forState: .Normal
            )
        
        clearCurrentImage()
        
        updateButtons( selected )
        
        setNeedsLayout()
        layoutIfNeeded()
        
//        adjustCellHeights( tableView, indexPath: indexPath )
        
//        delegate.tableView.beginUpdates()
//        delegate.tableView.endUpdates()
    }

}
