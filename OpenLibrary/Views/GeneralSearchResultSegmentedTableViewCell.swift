//
//  GeneralSearchResultSegmentedTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 7/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class GeneralSearchResultSegmentedTableViewCell: SegmentedTableViewCell, OLCell {

    @IBOutlet weak fileprivate var zoomCover: UIButton!
    
    @IBOutlet weak fileprivate var titleText: UILabel!
    @IBOutlet weak fileprivate var subtitleText: UILabel!
    @IBOutlet weak fileprivate var authorName: UILabel!
    @IBOutlet weak fileprivate var viewAuthorDetail: UIButton!
    
    @IBOutlet weak fileprivate var workDetail: UILabel!
    @IBOutlet weak fileprivate var viewWorkDetail: UIButton!

    @IBOutlet weak fileprivate var languageNames: UILabel!
    
    @IBOutlet weak fileprivate var firstPublished: UILabel!
    
    @IBOutlet weak fileprivate var eBooksLabel: UILabel!
    @IBOutlet weak fileprivate var viewBooks: UIButton!
    
    var tableVC: UIViewController?

    var currentImageFile: String? = ""
    var isZoomEnabled = false
    var haveEditions = false
    var haveEbooks = false
    
    var authorCount = 0
    
    var haveWorkDetail = false
    
    @IBAction fileprivate func zoomCoverTapped(_ sender: UIButton) {
        
        tableVC?.performSegue( withIdentifier: "zoomLargeImage", sender: self )
    }
    
    @IBAction fileprivate func viewAuthorDetailTapped(_ sender: UIButton) {
        
        if 1 == authorCount {

            tableVC?.performSegue( withIdentifier: "displayGeneralSearchAuthorDetail", sender: self )
            
        } else if 1 < authorCount {
            
            tableVC?.performSegue( withIdentifier: "displayGeneralSearchAuthorList", sender: self )
        }
    }
    
    @IBAction fileprivate func viewBooksTapped( _ sender: UIButton ) {

        tableVC?.performSegue( withIdentifier: "displayWorkEBooks", sender: self )
     }
    
    @IBAction fileprivate func viewWorkEditionsTapped(_ sender: UIButton) {

        tableVC?.performSegue( withIdentifier: "displayGeneralSearchWorkDetail", sender: self )
    }
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
        
//        zoomCover.imageView?.tintColor = UIColor( red: 0x00, green: 0x7A, blue: 0xFF, alpha: 1.0 )
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        updateButtons( selected && haveWorkDetail )
    }
    
    override func prepareForReuse() {
        
        titleText.text = ""
        titleText.sizeToFit()
        subtitleText.text = ""
        subtitleText.sizeToFit()
        authorName.text = ""
        authorName.sizeToFit()
        
        workDetail.text = ""
        workDetail.sizeToFit()
        languageNames.text = ""
        languageNames.sizeToFit()
        
        firstPublished.text = ""
        firstPublished.sizeToFit()
        
        eBooksLabel.text = ""
        eBooksLabel.sizeToFit()
        
        currentImageFile = nil

        isZoomEnabled = false
        haveEbooks = false
        haveEditions = false
        
        authorCount = 0
        
        updateButtons( false )
        
        super.prepareForReuse()
    }

    fileprivate func updateButtons( _ selected: Bool ) {

        assert( Thread.isMainThread )
        
        zoomCover.isEnabled = selected && isZoomEnabled
        
        viewAuthorDetail.isEnabled = selected && authorCount > 0
        authorName.textColor = viewAuthorDetail.currentTitleColor
        
        viewWorkDetail.isEnabled = selected && haveEditions
        workDetail.textColor = viewWorkDetail.currentTitleColor
        
        viewBooks.isEnabled = selected && haveEbooks
        eBooksLabel.textColor = viewBooks.currentTitleColor
    }
    
    func clearCurrentImage() -> Void {
        
    }
    
    func imageSize() -> CGSize? {
        
        return zoomCover.bounds.size
    }


    func configure( _ tableView: UITableView, indexPath: IndexPath, key: String, data: OLManagedObject? ) {
        
        assert( Thread.isMainThread )
        
        haveWorkDetail = false
        
        if let r = data as? OLGeneralSearchResult {
            
            self.key = key
            haveWorkDetail = nil != r.work_detail

            titleText.text = r.title
            subtitleText.text = r.subtitle
            authorName.text = r.author_name.joined( separator: ", " )
            
            workDetail.text = "Editions: " + String( r.edition_count )
            workDetail.sizeToFit()
            languageNames.text = r.language_names.joined( separator: ", " )
            
            firstPublished.text = String( r.first_publish_year )
            
            isZoomEnabled = r.hasImage
            haveEbooks = 0 < r.ebook_count_i
            haveEditions = 0 < r.edition_count
            
            authorCount = r.author_key.count

            if r.hasImage {
                
                zoomCover.setImage( nil, for: UIControlState() )
                zoomCover.setImage( nil, for: .disabled )

                let url = data?.localURL( "S" )
                currentImageFile = url?.lastPathComponent
                
            } else {
            
                currentImageFile = "thumbnail-book"
                let thumbNail = UIImage( named: currentImageFile! )
                zoomCover.setImage( thumbNail, for: UIControlState() )
                zoomCover.setImage( thumbNail, for: .disabled )
            }

            let labelText = "Electronic Editions " + ( haveEbooks ? "found" : "not found" )
            eBooksLabel.text = labelText
            updateButtons( isSelected && haveWorkDetail )
            
            layoutIfNeeded()
            
            _ = saveCellHeights( tableView, key: key, isExpanded: false )
            saveIndexPath( indexPath, inTableView: tableView, forKey: key )
        }
    }
    
    func displayImage( _ localURL: URL, image: UIImage ) -> Bool {
        
        assert( Thread.isMainThread )
        
        let newImageFile = localURL.lastPathComponent
        guard nil == currentImageFile || newImageFile == currentImageFile else { return true }
        
        zoomCover.setImage( image, for: UIControlState() )
        zoomCover.setImage( image, for: .disabled )
        currentImageFile = newImageFile
        
        return true
    }

    
    func transitionSourceRectView() -> UIImageView? {
        
        return zoomCover.imageView
    }
    

}
