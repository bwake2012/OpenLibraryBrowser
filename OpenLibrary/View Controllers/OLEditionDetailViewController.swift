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
            
            if let newDetail = newDetail , newDetail.hasImage {
                
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "zoomLargeImage" {
            
            if let destVC = segue.destination as? OLPictureViewController {
                
                queryCoordinator!.installCoverPictureViewCoordinator( destVC )
                
            }
        }
    }
    
    // MARK: Utility
    func updateUI( _ editionDetail: OLEditionDetail ) {
        
        assert( Thread.isMainThread )

        self.editionTitleView.text = editionDetail.title
        self.editionSubtitleView.text = editionDetail.subtitle
        self.editionAuthorView.text =
            !editionDetail.by_statement.isEmpty ?
                editionDetail.by_statement : editionDetail.author_names.joined( separator: ", " )
        
        self.displayLargeCover.isEnabled = editionDetail.coversFound
        if !editionDetail.coversFound {
            editionCoverView.image = UIImage( named: editionDetail.defaultImageName )
        }
    }
    
    @discardableResult func displayImage( _ localURL: URL ) -> Bool {
        
        assert( Thread.isMainThread )

        if let data = try? Data( contentsOf: localURL ) {
            if let image = UIImage( data: data ) {
                
                editionCoverView.image = image
                return true
            }
        }
        
        return false
    }
}

extension OLEditionDetailViewController: TransitionImage {
    
    var transitionRectImageView: UIImageView? {
        
        return editionCoverView
    }
}

