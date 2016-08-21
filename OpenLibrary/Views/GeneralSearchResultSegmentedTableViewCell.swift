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
    @IBOutlet weak private var authorName: UILabel!
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
//                if let indexPath = tableView.indexPathForRowAtPoint( sender.superview?.convertPoint( sender.center, toView: tableView ) ) {
//                    
//                    delegate.tableView( tableView, accessoryButtonTappedForRowWithIndexPath: indexPath )
//                }
//            }
        }
    }
    
    @IBAction private func viewWorkEditionsTapped(sender: UIButton) {

    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        self.layoutMargins = UIEdgeInsetsZero
        self.preservesSuperviewLayoutMargins = false
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        
        updateButtons( selected )
    }
    
    override func prepareForReuse() {
        
        titleText.text = ""
        subtitleText.text = ""
        authorName.text = ""
        
        viewWorkDetail.setTitle( "", forState: .Normal )
        languageNames.text = ""
        
        firstPublished.text = ""
        
        viewBooks.setTitle( "", forState: .Normal )
        
        currentImageURL = nil

        isZoomEnabled = false
        haveEbooks = false
        haveEditions = false
        
        updateButtons( false )
    }

    private func updateButtons( selected: Bool ) {

        assert( NSThread.isMainThread() )
        
        zoomCover.enabled = selected && isZoomEnabled
        
        viewAuthorDetail.enabled = selected
        authorName.textColor = viewAuthorDetail.currentTitleColor
        
        viewWorkDetail.enabled = selected && haveEditions
        
        viewBooks.enabled = selected && haveEbooks
        
    }

    override func configure( tableView: UITableView, key: String, data: OLManagedObject? ) {
        
        assert( NSThread.isMainThread() )
        
        if let r = data as? OLGeneralSearchResult {

            titleText.text = r.title
            subtitleText.text = r.subtitle
            authorName.text = r.author_name.joinWithSeparator( ", " )
            
            viewWorkDetail.setTitle( "Editions: " + String( r.edition_count ), forState: .Normal )
            languageNames.text = r.language_names.joinWithSeparator( ", " )
            
            firstPublished.text = String( r.first_publish_year )
            
            isZoomEnabled = r.hasImage
            haveEbooks = 0 < r.ebook_count_i
            haveEditions = 0 < r.edition_count

            if r.hasImage {
                
                cellImage.image = nil
                
            } else {
            
                clearCurrentImage()
            }
            
        } else {
            
            titleText.text = ""
            subtitleText.text = ""
            authorName.text = ""
            
            viewWorkDetail.setTitle( "", forState: .Normal )
            languageNames.text = ""
            
            firstPublished.text = ""
            
            viewBooks.setTitle( "", forState: .Normal )

            isZoomEnabled = false
            haveEbooks = false
            haveEditions = false
            
            clearCurrentImage()
        }
        
        viewBooks.setTitle(
                "Electronic Editions " + ( haveEbooks ? "found" : "not found" ),
                forState: .Normal
            )
        
        updateButtons( selected )
        
//        setNeedsLayout()
        layoutIfNeeded()
        
        adjustCellHeights( tableView, key: key )
        
//        delegate.tableView.beginUpdates()
//        delegate.tableView.endUpdates()
    }

}
