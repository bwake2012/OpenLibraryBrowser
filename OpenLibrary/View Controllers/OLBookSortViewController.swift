//
//  OLBookSortViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

struct SortField {
    
    let name: String
    let label: String
    var sort: SortOptions
    
    func image() -> UIImage {
        
        return UIImage( named: sort.imageName )!
    }
}

enum SortOptions: Int {
    
    case sortNone = 0, sortUp = 1, sortDown = 2, sortMax  = 3
    
    var imageName: String {
        
        switch self {
        case sortNone: return "rsw-notsorted-28x26"
        case sortUp:   return "763-arrow-up"
        case sortDown: return "764-arrow-down"
        case sortMax:
            assert( self != sortMax )
            return ""
        }
    }
    
    func nextSort() -> SortOptions {
        
        let rawNext = self.rawValue + 1
        let rawMax  = sortMax.rawValue
        
        let rawNew = rawNext % rawMax
        
        return SortOptions( rawValue: rawNew )!
    }
    
    var ascending: Bool {
        
        return self == .sortUp
    }
}
    
typealias SaveSortFields = ( sortFields: [SortField] ) -> Void

class OLBookSortViewController: UIViewController {
    
    var queryCoordinator: GeneralSearchResultsCoordinator?
    
    var saveSortFields: SaveSortFields?
    
    var sortFields = [SortField]()
    
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var sortButton: UIButton!
    
    @IBOutlet private var sortLabels:  Array< UIButton >!
    @IBOutlet private var sortButtons: Array< UIButton >!
    
    @IBAction func cancelButtonTapped( sender: UIButton ) {}
    
    @IBAction func sortButtonTapped( sender: UIButton ) {
        
        if let saveSortFields = saveSortFields {
            
            saveSortFields( sortFields: sortFields )
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
    }
    
    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                sortButton.enabled = .sortNone != nextSort
                
            } else {
                
                sortFields[index].sort = .sortNone
                
            }
        }

        for ( index, button ) in sortButtons.enumerate() {
            
            button.setImage( sortFields[index].image(), forState: .Normal )
        }
    }
}
