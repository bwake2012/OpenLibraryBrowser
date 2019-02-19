//
//  TransitionRectangleSource.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/12/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

protocol TransitionImage {
    
    var transitionRectImageView: UIImageView? { get }
}

protocol TransitionCell {
    
    func transitionRectCellView() -> UITableViewCell?
}


protocol UncoverBottomTransitionSource {
    
    func uncoverSourceRectangle() -> UIView?
}
