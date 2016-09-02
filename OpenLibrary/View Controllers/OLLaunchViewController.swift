//
//  OLLaunchViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 9/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLLaunchViewController: UIViewController {

    private let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    private lazy var navController: UINavigationController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("rootNavigationController")
            as! UINavigationController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear( animated )
    }

    func loadAppRootViewController() {
        
        dispatch_async( dispatch_get_main_queue() ) {
            
            let navController = self.navController
            self.presentViewController( navController, animated: true, completion: nil )
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
