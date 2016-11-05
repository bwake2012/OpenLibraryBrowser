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
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear( animated )
        
        assert( nil != queryCoordinator )
        
        queryCoordinator?.updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {

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
    func displayImage( _ localURL: URL ) -> Bool {
        
        assert( Thread.isMainThread )

        if let data = try? Data( contentsOf: localURL ) {
            if let image = UIImage( data: data ) {
                
                pictureView.image = image
                activityIndicator.stopAnimating()
                return true
            }
        }
        
        return false
    }
    

}
