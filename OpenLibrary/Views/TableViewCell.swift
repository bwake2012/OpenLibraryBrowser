//
//  TableViewCell.swift
//  SegmentedTableViewCell
//
//  Created by Bob Wakefield on 6/29/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

extension UIView {
    
    fileprivate class func registerCell( _ tableView: UITableView, className: String ) {
        
        let nib = UINib( nibName: className, bundle: nil )
        
        tableView.register( nib, forCellReuseIdentifier: className )
    }
    
    class func registerCell( _ tableView: UITableView ) {
        
        registerCell( tableView, className: nameOfClass )
    }

    class func createFromNib() -> UIView? {
        
        guard let view = Bundle.main.loadNibNamed( nameOfClass, owner: nil, options: nil )?.last as? UIView else { return nil }
        
        return view
    }
}
