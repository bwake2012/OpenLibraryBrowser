//
//  OLEditionDetailViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/7/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLEditionDetailViewController: UIViewController {

    @IBOutlet weak var editionCoverView: UIImageView!
    @IBOutlet weak var editionTitleView: UILabel!
    @IBOutlet weak var editionSubtitleView: UILabel!
    @IBOutlet weak var editionAuthorView: UILabel!
    @IBOutlet weak var displayLargeCover: UIButton!

    var editionDetail: OLEditionDetail? {
        
        didSet( newDetail ) {
            
            if let newDetail = newDetail where newDetail.hasImage {
                
                editionCoverView.displayFromURL( newDetail.localURL( "S" ) )
            }
        }
    }
    var queryCoordinator: EditionDetailCoordinator?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        assert( nil != queryCoordinator )
        
        queryCoordinator?.updateUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
        
        super.viewWillAppear( animated )
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "zoomDeluxeDetailImage" {
            
            if let destVC = segue.destinationViewController as? OLPictureViewController {
                
                queryCoordinator!.installCoverPictureViewCoordinator( destVC )
                
            }
        }
    }
    
    // MARK: Utility
    func updateUI( editionDetail: OLEditionDetail ) {
        
        assert( NSThread.isMainThread() )

        self.editionTitleView.text = editionDetail.title
        self.editionSubtitleView.text = editionDetail.subtitle
        self.editionAuthorView.text =
            !editionDetail.by_statement.isEmpty ?
                editionDetail.by_statement : editionDetail.author_names.joinWithSeparator( ", " )
        
        self.displayLargeCover.enabled = editionDetail.coversFound
        if !editionDetail.coversFound {
            editionCoverView.image = UIImage( named: editionDetail.defaultImageName )
        }
    }
    
    func displayImage( localURL: NSURL ) -> Bool {
        
        assert( NSThread.isMainThread() )

        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                editionCoverView.image = image
                return true
            }
        }
        
        return false
    }
}

extension OLEditionDetailViewController: TransitionSourceImage {
    
    func transitionSourceRectImageView() -> UIImageView? {
        
        return editionCoverView
    }
}

