//
//  OLPictureViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/6/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
import CoreData

import BNRCoreDataStack

class OLPictureViewController: UIViewController {

    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Properties
    var queryCoordinator: PictureViewCoordinator?
    
    override func viewDidLoad() {

        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
        
        super.viewWillAppear( animated )
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear( animated )
        
        assert( nil != queryCoordinator )
        
        queryCoordinator?.updateUI()
    }
    
    override func viewWillDisappear(animated: Bool) {

        if let queryCoordinator = queryCoordinator {
            
            queryCoordinator.cancelOperations()
        }
        
        super.viewWillDisappear( animated )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: Utility
    func displayImage( localURL: NSURL ) -> Bool {
        
        assert( NSThread.isMainThread() )

        if let data = NSData( contentsOfURL: localURL ) {
            if let image = UIImage( data: data ) {
                
                pictureView.image = image
                activityIndicator.stopAnimating()
                return true
            }
        }
        
        return false
    }
    

}
