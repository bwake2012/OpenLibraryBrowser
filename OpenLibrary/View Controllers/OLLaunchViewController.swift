//
//  OLLaunchViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 9/1/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLLaunchViewController: UIViewController {
    
    var enableClose: Bool = false
    
    private let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    private lazy var navController: UINavigationController = {
        return self.mainStoryboard.instantiateViewControllerWithIdentifier("rootNavigationController")
            as! UINavigationController
    }()
    
    @IBOutlet var copyrightLabel: UILabel!
    @IBOutlet var copyright: UIButton!

    @IBAction func copyrightButtonTapped( sender: UIButton ) {
        
        dismissViewControllerAnimated( true, completion: nil )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        super.viewWillAppear( animated )
        
        let nonBreakingSpace = "\u{00a0}"
        copyright.enabled = enableClose
        copyrightLabel.text = "Copyright\(nonBreakingSpace)2016 Cockleburr\(nonBreakingSpace)Software"
        copyrightLabel.textColor = copyright.currentTitleColor
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
