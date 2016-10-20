//
//  OLBookSortViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit
   
typealias SaveSortFields = ( sortFields: [SortField] ) -> Void

class OLBookSortViewController: UIViewController {
    
    var queryCoordinator: GeneralSearchResultsCoordinator?
    
    var saveSortFields: SaveSortFields?
    
    var sortFields = [SortField]()
    
    @IBOutlet private var sortLabels:  Array< UIButton >!
    @IBOutlet private var sortButtons: Array< UIButton >!
    
    @IBAction func sortButtonTapped( sender: UIButton ) {
        
        if let saveSortFields = saveSortFields {
            
            saveSortFields( sortFields: sortFields )
            
            performSegueWithIdentifier( "beginBookSort", sender: self )
        }
    }
    
    @IBAction func sortByIcon( sender: UIButton ) {

        updateButtonIcons( sender, buttonArray: sortButtons )
    }
    
    @IBAction func sortByLabel( sender: UIButton ) {
        
        updateButtonIcons( sender, buttonArray: sortLabels )
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver( self )
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {

        super.viewDidLoad()
                
        assert( sortLabels.count == sortButtons.count && sortLabels.count == sortFields.count )

        self.sortLabels.sortInPlace{ $0.frame.origin.y < $1.frame.origin.y }
        self.sortButtons.sortInPlace{ $0.frame.origin.y < $1.frame.origin.y }
        
        displaySortKeys()
        
        // navigationController?.hidesBarsOnSwipe = false
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        
        navigationController?.setNavigationBarHidden( false, animated: animated )
        
        super.viewWillAppear( animated )
    }
    
    func displaySortKeys() {
        
        for ( index, sortField ) in sortFields.enumerate() {
            
            sortButtons[index].setImage( sortField.image(), forState: .Normal )
            sortLabels[index].setTitle( sortField.label, forState: .Normal )
        }
    }
    
    func updateButtonIcons( sender: UIButton, buttonArray: [UIButton] ) {
        
        for (index, button) in buttonArray.enumerate() {
            
            if sender === button {
                
                let nextSort = sortFields[index].sort.nextSort()
                sortFields[index].sort = nextSort
                
            } else {
                
                sortFields[index].sort = .sortNone
                
            }
        }

        for ( index, button ) in sortButtons.enumerate() {
            
            button.setImage( sortFields[index].image(), forState: .Normal )
        }
    }
}
