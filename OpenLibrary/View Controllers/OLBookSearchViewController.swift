//
//  OLBookSearchViewController.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 5/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

class OLBookSearchViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var generalSearch:   UITextField!
    @IBOutlet weak var titleSearch:     UITextField!
    @IBOutlet weak var authorSearch:    UITextField!
    @IBOutlet weak var isbnSearch:      UITextField!
    @IBOutlet weak var subjectSearch:   UITextField!
    @IBOutlet weak var placeSearch:     UITextField!
    @IBOutlet weak var personSearch:    UITextField!
    @IBOutlet weak var publisherSearch: UITextField!
    
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var ebookOnlySwitch: UISwitch!
    
    weak var activeField: UITextField?
    
    var queryCoordinator: GeneralSearchResultsCoordinator?
    var searchKeys = [String: String]()
    
    @IBAction func ebookOnlySwitchChanged(sender: AnyObject) {
        
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        
        if let activeField = activeField {
            
            activeField.resignFirstResponder()
        }
        
        searchKeys = [String: String]()
        
        performSegueWithIdentifier( "exitBookSearch", sender: self )
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver( self )
    }
    
    // MARK: UIViewController
    override func viewDidLoad() {

        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OLBookSearchViewController.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OLBookSearchViewController.keyboardWillBeHidden(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }

    
    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(textField: UITextField) {
        self.activeField = nil
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.activeField = textField
    }
    
    func textFieldShouldReturn( textField: UITextField ) -> Bool {
        
        textField.resignFirstResponder()
        if let queryCoordinator = queryCoordinator {
            
            searchKeys = assembleSearchKeys()
            if !searchKeys.isEmpty {
                
                queryCoordinator.newQuery( searchKeys, userInitiated: true, refreshControl: nil )
            }
        }

        performSegueWithIdentifier( "exitBookSearch", sender: self )

        return false
    }
    
    // MARK: Notifications
    func keyboardDidShow(notification: NSNotification) {
        if let activeField = self.activeField, keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            var aRect = self.view.frame
            aRect.size.height -= keyboardSize.size.height
            if (!CGRectContainsPoint(aRect, activeField.frame.origin)) {
                self.scrollView.scrollRectToVisible(activeField.frame, animated: true)
            }
        }
    }
    
    func keyboardWillBeHidden(notification: NSNotification) {
        let contentInsets = UIEdgeInsetsZero
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
    
    func assembleSearchKeys() -> [String: String] {
    
        let fields: [(field: UITextField, key: String)] =
                [( generalSearch, "q" ), (titleSearch, "title"), (authorSearch, "author"),
                 (isbnSearch, "isbn"), (subjectSearch, "subject"), (placeSearch, "place"),
                 (personSearch, "person"), (publisherSearch, "publisher")]
        
        var searchKeys = [String: String]()
        for field in fields {
            
            if let t = field.field.text where !t.isEmpty {
                
                searchKeys[field.key] = t
            }
        }
        
        // don't set the eBooksOnly parameter if no other fields have been set
        if !searchKeys.isEmpty && ebookOnlySwitch.on {
            searchKeys["has_fulltext"] = "true"
        }
    
        return searchKeys
    }
}
