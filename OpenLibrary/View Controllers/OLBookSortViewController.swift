//
//  OLBookSortViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
   
typealias SaveSortFields = ( _ sortFields: [SortField] ) -> Void

class OLBookSortViewController: UIViewController {
    
    var queryCoordinator: GeneralSearchResultsCoordinator?
    
    var saveSortFields: SaveSortFields?
    
    var sortFields = [SortField]()
    
    @IBOutlet fileprivate var sortLabels:  Array< UIButton >!
    @IBOutlet fileprivate var sortButtons: Array< UIButton >!
    
    @IBAction func sortButtonTapped( _ sender: UIButton ) {
        
        if let saveSortFields = saveSortFields {
            
            saveSortFields( sortFields )
            
            performSegue( withIdentifier: "beginBookSort", sender: self )
        }
    }
    
    @IBAction func sortByIcon( _ sender: UIButton ) {

        updateButtonIcons( sender, buttonArray: sortButtons )
    }
    
    @IBAction func sortByLabel( _ sender: UIButton ) {
        
        updateButtonIcons( sender, buttonArray: sortLabels )
    }
    
    deinit {
        NotificationCenter.default.removeObserver( self )
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {

        super.viewDidLoad()
                
        assert( sortLabels.count == sortButtons.count && sortLabels.count == sortFields.count )

        self.sortLabels.sort{ $0.frame.origin.y < $1.frame.origin.y }
        self.sortButtons.sort{ $0.frame.origin.y < $1.frame.origin.y }
        
        displaySortKeys()
        
        // navigationController?.hidesBarsOnSwipe = false
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear( animated )
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
    }
    
    func displaySortKeys() {
        
        for ( index, sortField ) in sortFields.enumerated() {
            
            sortButtons[index].setImage( sortField.image(), for: UIControlState() )
            sortLabels[index].setTitle( sortField.label, for: UIControlState() )
        }
    }
    
    func updateButtonIcons( _ sender: UIButton, buttonArray: [UIButton] ) {
        
        for (index, button) in buttonArray.enumerated() {
            
            if sender === button {
                
                let nextSort = sortFields[index].sort.nextSort()
                sortFields[index].sort = nextSort
                
            } else {
                
                sortFields[index].sort = .sortNone
                
            }
        }

        for ( index, button ) in sortButtons.enumerated() {
            
            button.setImage( sortFields[index].image(), for: UIControlState() )
        }
    }
}
