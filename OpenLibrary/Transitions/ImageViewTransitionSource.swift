//
//  TransitionRectangleSource.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 4/12/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

protocol TransitionSourceImage {
    
    func transitionSourceRectImageView() -> UIImageView?
}

protocol TransitionSourceCell {
    
    func transitionSourceRectCellView() -> UITableViewCell?
}


protocol UncoverBottomTransitionSource {
    
    func uncoverSourceRectangle() -> UIView?
}