//
//  TableViewCell.swift
//  SegmentedTableViewCell
//
//  Created by Bob Wakefield on 6/29/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIView {
    
    class var nameOfClass: String {
        return NSStringFromClass(self).componentsSeparatedByString(".").last!
    }
    
    var nameOfClass: String {
        return NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!
    }
    
    private class func registerCell( tableView: UITableView, className: String ) {
        
        let nib = UINib( nibName: className, bundle: nil )
        
        tableView.registerNib( nib, forCellReuseIdentifier: className )
    }
    
    class func registerCell( tableView: UITableView ) {
        
        registerCell( tableView, className: nameOfClass )
    }

    class func createFromNib() -> UIView? {
        
        guard let view = NSBundle.mainBundle().loadNibNamed( nameOfClass, owner: nil, options: nil ).last as? UIView else { return nil }
        
        return view
    }

}


