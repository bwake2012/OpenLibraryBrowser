//
//  OLAuthorDeluxeDetailViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/22/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLAuthorDeluxeDetailViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var authorName: UILabel!
    @IBOutlet weak var authorPhoto: UIImageView!
    @IBOutlet weak var displayLargePhoto: UIButton!
    
    var queryCoordinator: AuthorDeluxeDetailCoordinator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidLayoutSubviews()
    {
        let scrollViewBounds = scrollView.bounds
        let contentViewBounds = contentView.bounds
        
        var scrollViewInsets = UIEdgeInsetsZero
        scrollViewInsets.top = scrollViewBounds.size.height/2.0;
        scrollViewInsets.top -= contentViewBounds.size.height/2.0;
        
        scrollViewInsets.bottom = scrollViewBounds.size.height/2.0
        scrollViewInsets.bottom -= contentViewBounds.size.height/2.0;
        scrollViewInsets.bottom += 1
        
        scrollView.contentInset = scrollViewInsets
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "deluxeLargeAuthorPhoto" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {
                
                queryCoordinator?.installAuthorPictureCoordinator( destVC )
            }
        }
    }
    
    // MARK: UI updates

    func updateUI( authorDetail: OLAuthorDetail ) {
        
        self.displayLargePhoto.enabled = authorDetail.hasImage
        
        self.authorName.text = authorDetail.name
        
        if !authorDetail.hasImage {
            self.authorPhoto.image = UIImage( named: "253-person.png" )
        }
    }
    
    func displayImage( localURL: NSURL ) -> Bool {
        
        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                authorPhoto.image = image
                return true
            }
        }
        
        return false
    }
}
