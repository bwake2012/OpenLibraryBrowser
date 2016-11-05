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
    
    fileprivate lazy var mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    fileprivate lazy var navController: UINavigationController = {
        return self.mainStoryboard.instantiateViewController(withIdentifier: "rootNavigationController")
            as! UINavigationController
    }()
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var copyright: UIButton!

    @IBAction func copyrightButtonTapped( _ sender: UIButton ) {
        
        dismiss( animated: true, completion: nil )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        if enableClose {
            activityIndicator.stopAnimating()
        }
        
        copyright.isEnabled = enableClose
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
