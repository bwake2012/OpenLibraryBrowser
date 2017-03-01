//
//  SplitViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/19/17.
//  Copyright © 2017 Bob Wakefield. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    // Preferred status bar style lightContent to use on dark background.
    // Swift 3
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
