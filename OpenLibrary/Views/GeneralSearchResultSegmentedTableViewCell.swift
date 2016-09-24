//
//  GeneralSearchResultSegmentedTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class GeneralSearchResultSegmentedTableViewCell: SegmentedTableViewCell, OLCell {

    @IBOutlet weak private var zoomCover: UIButton!
    
    @IBOutlet weak private var titleText: UILabel!
    @IBOutlet weak private var subtitleText: UILabel!
    @IBOutlet weak private var authorName: UILabel!
    @IBOutlet weak private var viewAuthorDetail: UIButton!
    
    @IBOutlet weak private var workDetail: UILabel!
    @IBOutlet weak private var viewWorkDetail: UIButton!

    @IBOutlet weak private var languageNames: UILabel!
    
    @IBOutlet weak private var firstPublished: UILabel!
    
    @IBOutlet weak private var eBooksLabel: UILabel!
    @IBOutlet weak private var viewBooks: UIButton!
    
    var tableVC: UIViewController?

    var currentImageFile: String? = ""
    var isZoomEnabled = false
    var haveEditions = false
    var haveEbooks = false
    
    @IBAction private func zoomCoverTapped(sender: UIButton) {
        
        tableVC?.performSegueWithIdentifier( "largeCoverImage", sender: self )
    }
    
    @IBAction private func viewAuthorDetailTapped(sender: UIButton) {
        
        tableVC?.performSegueWithIdentifier( "displayGeneralSearchAuthorDetail", sender: self )
    }
    
    @IBAction private func viewBooksTapped( sender: UIButton ) {

        tableVC?.performSegueWithIdentifier( "displayEBookTableView", sender: self )
     }
    
    @IBAction private func viewWorkEditionsTapped(sender: UIButton) {

        tableVC?.performSegueWithIdentifier( "displayGeneralSearchWorkDetail", sender: self )
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
        
//        zoomCover.imageView?.tintColor = UIColor( red: 0x00, green: 0x7A, blue: 0xFF, alpha: 1.0 )
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        
        updateButtons( selected )
    }
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        titleText.text = ""
        subtitleText.text = ""
        authorName.text = ""
        
        workDetail.text = ""
        languageNames.text = ""
        
        firstPublished.text = ""
        
        eBooksLabel.text = ""
        
        currentImageFile = nil

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
        workDetail.textColor = viewWorkDetail.currentTitleColor
        
        viewBooks.enabled = selected && haveEbooks
        eBooksLabel.textColor = viewBooks.currentTitleColor
    }
    
    func clearCurrentImage() -> Void {
        
    }
    
    func imageSize() -> CGSize? {
        
        return zoomCover.bounds.size
    }


    func configure( tableView: UITableView, indexPath: NSIndexPath, key: String, data: OLManagedObject? ) {
        
        assert( NSThread.isMainThread() )
        
        if let r = data as? OLGeneralSearchResult {
            
            self.key = key

            titleText.text = r.title
            subtitleText.text = r.subtitle
            authorName.text = r.author_name.joinWithSeparator( ", " )
            
            workDetail.text = "Editions: " + String( r.edition_count )
            languageNames.text = r.language_names.joinWithSeparator( ", " )
            
            firstPublished.text = String( r.first_publish_year )
            
            isZoomEnabled = r.hasImage
            haveEbooks = 0 < r.ebook_count_i
            haveEditions = 0 < r.edition_count

            if r.hasImage {
                
                zoomCover.setImage( nil, forState: .Normal )
                zoomCover.setImage( nil, forState: .Disabled )

                let url = data?.localURL( "S" )
                currentImageFile = url?.lastPathComponent
                
            } else {
            
                currentImageFile = "thumbnail-book"
                let thumbNail = UIImage( named: currentImageFile! )
                zoomCover.setImage( thumbNail, forState: .Normal )
                zoomCover.setImage( thumbNail, forState: .Disabled )
            }

            let labelText = "Electronic Editions " + ( haveEbooks ? "found" : "not found" )
            eBooksLabel.text = labelText
            updateButtons( selected )
            
            saveCellHeights( tableView, key: key, isExpanded: false )
            saveIndexPath( indexPath, inTableView: tableView, forKey: key )
        }
    }
    
    func displayImage( localURL: NSURL, image: UIImage ) -> Bool {
        
        assert( NSThread.isMainThread() )
        
        let newImageFile = localURL.lastPathComponent
        guard nil == currentImageFile || newImageFile == currentImageFile else { return true }
        
        zoomCover.setImage( image, forState: .Normal )
        zoomCover.setImage( image, forState: .Disabled )
        currentImageFile = newImageFile
        
        return true
    }

    
    func transitionSourceRectView() -> UIImageView? {
        
        return zoomCover.imageView
    }
    

}
