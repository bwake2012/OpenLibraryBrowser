//
//  SegmentedTableViewCell.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 6/27/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

private let kCloseButton = "34-circle.minus.png"
private let kOpenButton  = "33-circle-plus.png"


struct CellInfo {
    
    let title: String
    let subTitle: String
    let author: String
    
    init( indexPath: NSIndexPath ) {
        
        title = "Title: \(indexPath.row)"
        subTitle = "Subtitle: \(indexPath.row)"
        author = "Author: \(indexPath.row)"
    }
    
    init( title: String, subTitle: String, author: String ) {
        
        self.title = title
        self.subTitle = subTitle
        self.author = author
    }
}

class SegmentedTableViewCell: UITableViewCell {
    
    struct CellHeights {
        
        var closed:     CGFloat = 0.0
        var open:       CGFloat = 0.0
    }
    
    static private var segmentedTableViewCells: [UITableView: SegmentedTableViewCell] = [:]
    static private var openCells: [UITableView: String] = [:]

    static private var animating = false
    
    static private var minimumCellHeight: CGFloat = 0.0
    static private var tableCellHeights = [UITableView: [String: CellHeights]]()
    static private var tableCellKeys = [UITableView: [NSIndexPath: String]]()

    @IBOutlet weak private var segmentView0: UIView!
    
    @IBOutlet private var segmentViews: Array< UIView >!
    @IBOutlet private var segmentViewTops: Array< NSLayoutConstraint >!
    
//    private var tableView: UITableView?
    
    private var reversedSegmentViews = [UIView]()
    private var reversedSegmentViewTops = [NSLayoutConstraint]()
    
    private var segmentDuration = NSTimeInterval( 1.0 ) // NSTimeInterval( 0.3 )
    
    var key: String = ""

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    deinit {
        
        self.segmentViews = [UIView]()
        self.segmentViewTops = [NSLayoutConstraint]()
        
        self.reversedSegmentViews = self.segmentViews
        self.reversedSegmentViewTops = self.segmentViewTops
    }
        
    override func awakeFromNib() {

        super.awakeFromNib()
        
        for view in segmentViews {
            
            view.removeFromSuperview()
        }
        
        self.segmentViewTops = []

        self.segmentViews.sortInPlace{ $0.frame.origin.y < $1.frame.origin.y }
        self.segmentViewTops.sortInPlace{ $0.constant < $1.constant }
        
        self.reversedSegmentViews = self.segmentViews.reverse()
        self.reversedSegmentViewTops = self.segmentViewTops.reverse()
    }
        
//    @IBAction private func expandTapped( sender: UIButton, withEvent event: UIEvent ) {
//        
//        if !SegmentedTableViewCell.animating {
//
//            if let tableView = tableView, delegate = tableView.delegate {
//            
//                // [[[event touchesForView: button] anyObject] locationInView: self.tableView]]
//                if let indexPath = tableView.indexPathForRowAtPoint( sender.superview!.convertPoint( sender.center, toView: tableView ) ) {
//                
//                    delegate.tableView!( tableView, accessoryButtonTappedForRowWithIndexPath: indexPath )
//                }
//            }
//        }
//    }
    
    class func animationInProgress() -> Bool {
        
        let result = SegmentedTableViewCell.animating

        SegmentedTableViewCell.animating = true
        
        return result
    }
    
    class func animationComplete() -> Void {
        
        SegmentedTableViewCell.animating = false
    }
    
    class var estimatedCellHeight: CGFloat {
        
        // return 60.0 + 1
        
        return 101 + 1
    }
    
    class func keyForIndexPath( tableView: UITableView, indexPath: NSIndexPath, key: String ) {
        
        SegmentedTableViewCell.tableCellKeys[tableView]?[indexPath] = key
    }
    
    class func isExpanded( tableView: UITableView, key: String ) -> Bool {
        
        guard let openCellKey = SegmentedTableViewCell.openCells[tableView] else {
            
            return false
        }
        
        return key == openCellKey
    }
    
    class func estimatedCellHeight( tableView: UITableView, key: String ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        if let cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]![key] {
            
            let isExpanded = SegmentedTableViewCell.isExpanded( tableView, key: key )
            
            height = isExpanded ? cellHeights.open : cellHeights.closed
        }

        return height
    }
    
    class func emptyCellHeights( tableView: UITableView ) -> Void {
        
        SegmentedTableViewCell.tableCellHeights[tableView] = [:]
        SegmentedTableViewCell.tableCellKeys[tableView] = [:]
    }
    
    class func setOpen( tableView: UITableView, indexPath: NSIndexPath ) {
        
        if let key = SegmentedTableViewCell.tableCellKeys[tableView]?[indexPath] {
            
            SegmentedTableViewCell.openCells[tableView] = key
        }
    }
    
    class func setClosed( tableView: UITableView, indexPath: NSIndexPath ) {
        
        if let key = SegmentedTableViewCell.tableCellKeys[tableView]?[indexPath] {
            
            if key == SegmentedTableViewCell.openCells[tableView] {
                
                SegmentedTableViewCell.openCells[tableView] = nil
            }
        }
    }
    
    class func closeAllCells( tableView: UITableView ) -> Void {
        
        SegmentedTableViewCell.openCells[tableView] = nil
    }
    
    class func cachedHeightForRowAtIndexPath( tableView: UITableView, indexPath: NSIndexPath ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        if let key = SegmentedTableViewCell.tableCellKeys[tableView]?[indexPath] {
            
            if let cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]?[key] {
                
                let isExpanded = SegmentedTableViewCell.isExpanded( tableView, key: key )
                
                height = isExpanded ? cellHeights.open : cellHeights.closed
            }
        }
        
        return height
    }
    
    private func segmentZeroHeight() -> CGFloat {
        
        return ceil( ceil( segmentView0.bounds.origin.y ) + ceil( segmentView0.bounds.height ) )
    }
    
    private func totalSegmentHeight() -> CGFloat {
        
        return ceil( segmentViews.reduce( segmentZeroHeight() ) { $0 + ceil( $1.bounds.height ) } )
    }
    
    func isAnimating() -> Bool {
        
        return SegmentedTableViewCell.animating
    }
    
    func setOpen( tableView: UITableView, key: String ) {
        
        SegmentedTableViewCell.openCells[tableView] = key
    }
    
    func setClosed( tableView: UITableView ) {
        
        if key == SegmentedTableViewCell.openCells[tableView] {
            
            SegmentedTableViewCell.openCells[tableView] = nil
        }
    }
    
    func height( tableView: UITableView ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
        
        let isExpanded = SegmentedTableViewCell.isExpanded( tableView, key: key )
        if let cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]?[key] {
            
            height = isExpanded ? cellHeights.open : cellHeights.closed
            
        } else {
            
            height = saveCellHeights( tableView, key: key, isExpanded: isExpanded )
        }
        
        return height
    }
    
    func saveCellHeights( tableView: UITableView, key: String, isExpanded: Bool ) -> CGFloat {
        
        bounds = CGRectMake( 0.0, 0.0, tableView.bounds.width, bounds.height )
        layoutIfNeeded()
        
        let closedHeight = segmentZeroHeight()
        let openHeight = totalSegmentHeight()
        
        let cellHeights = CellHeights( closed: closedHeight, open: openHeight )
        SegmentedTableViewCell.tableCellHeights[tableView]![key] = cellHeights
        
        let height = isExpanded ? cellHeights.open : cellHeights.closed
        
        return height
    }
    
    func selectedAnimation( tableView: UITableView, key: String ) -> Bool {
        
        let shouldBeOpen = SegmentedTableViewCell.isExpanded( tableView, key: key )
        
        selectedAnimation( tableView, key: key, expandCell: shouldBeOpen, animated: false, completion: nil )
        
        return shouldBeOpen
    }

    func selectedAnimation( tableView: UITableView, key: String, expandCell: Bool, animated: Bool, completion: (Void -> Void)? ) -> Bool {
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )

        if expandCell {
            
            let openY = openTop()

            if animated {

                openAnimation( segmentDuration, endY: openY ) {

                    completion?()
                }
                
            } else  {

                setSegmementViewAlpha( 1 )
                moveSegmentViewTops( openY )
            }
            
        } else {

            let closedY = closedTop()
            if animated {
                closeAnimation( segmentDuration, endY: closedY ) {

                     completion?()
                }
            } else {

                setSegmementViewAlpha( 0 )
                self.moveSegmentViewTops( closedY )
             }
        }
        
        let cellHeights =
            CellHeights(
                closed: segmentZeroHeight(),
                open: totalSegmentHeight()
            )
        
        SegmentedTableViewCell.tableCellHeights[tableView]![key] = cellHeights
        
//        print( "\(indexPath.row) Segment0 top: \(segmentView0.frame.origin.y)")
        
        return expandCell
    }
    
    private func setSegmementViewAlpha( alpha: CGFloat ) {
        
        for view in segmentViews {
            view.alpha = alpha
        }
    }
    
    private func moveSegmentViewTops( yOffsets: [CGFloat] ) {
        
        for (index, segmentViewTop) in segmentViewTops.enumerate() {
            
            segmentViewTop.constant = yOffsets[index]
        }
    }
    
    private func openTop() -> [CGFloat] {
        
        var result = [CGFloat]( count: self.segmentViews.count, repeatedValue: 0.0 )
        
        var yOffset = ceil( segmentView0.frame.origin.y ) + ceil( segmentView0.frame.height )
        for (index, view) in segmentViews.enumerate() {
            
            result[index] = ceil( yOffset )
            
            yOffset += view.frame.height
        }

        return result
    }
    
    private func closedTop() -> [CGFloat] {
    
        return segmentViews.map { floor( segmentView0.frame.origin.y + ( segmentView0.frame.height - $0.frame.height ) ) }
    }
    
    private func openAnimation( totalDuration: NSTimeInterval, endY: [CGFloat], completion: (Void -> Void)? ) {
        
        let revEndY: [CGFloat] = endY.reverse()
        
        animate(
                reversedSegmentViews,
                segmentViewTops: reversedSegmentViewTops,
                totalDuration: totalDuration,
                endY: revEndY, endAlpha: 1.0
            ) {

                completion?()
            }
    }

    private func closeAnimation( totalDuration: NSTimeInterval, endY: [CGFloat], completion: (Void -> Void)? ) {
        
        animate(
                segmentViews,
                segmentViewTops: segmentViewTops,
                totalDuration: totalDuration,
                endY: endY, endAlpha: 0.0
            ) {

                completion? ()
            }
    }
    
    private func moveSegmentFrames( segmentViews: [UIView], yArray: [CGFloat] ) -> [CGRect] {
        
        var frames = [CGRect]( count: yArray.count, repeatedValue: CGRectZero )

        for (index,y) in yArray.enumerate() {
            
            frames[index] = segmentViews[index].frame
            frames[index].origin.y = y

        }
        
        return frames
    }
    
    private func animate(
            segmentViews: [UIView],
            segmentViewTops: [NSLayoutConstraint],
            totalDuration: NSTimeInterval,
            endY: [CGFloat], endAlpha: CGFloat,
            completion: (Void -> Void)? ) -> Void {
        
        let segmentViewEndFrames = moveSegmentFrames( segmentViews, yArray: endY )

        var totalHeight = CGFloat( 0.0 )
        for view in segmentViews {
            
            totalHeight += view.frame.height
            view.hidden = false
        }
        
        setSegmementViewAlpha( 1.0 )
        
        let minHeight = self.segmentView0.frame.height
        var contentFrame = self.contentView.frame
        var contentSize = contentFrame.size
        if contentFrame.height > minHeight {
            
            contentSize.height = minHeight
        
        } else {
            
            contentSize.height = totalHeight
        }
        
        contentFrame.size = contentSize
        let contentView = self.contentView
        
        UIView.animateKeyframesWithDuration(
            totalDuration,
            delay: 0,
            options: .BeginFromCurrentState,
            animations: {
                
                () -> Void in
                
                var frameStart: Double = 0.0
                for (index, view) in segmentViews.enumerate() {
                    
                    let dyN = view.frame.height
                    let frameDuration = Double( dyN ) / Double( totalHeight )
                    
                    UIView.addKeyframeWithRelativeStartTime( frameStart, relativeDuration: frameDuration ) {
                        
                        view.frame = segmentViewEndFrames[index]
                        segmentViewTops[index].constant = endY[index]
                    }
                
                    // fade out (or in) the master view top and bottom views
                    // want the fade out animation to happen near the end of the transition
                    // and the fade in animation to happen at the start of the transition
                    let fadeDuration = frameDuration / 2
                    let fadeStartTime = endAlpha != 0.0 ? frameStart : frameStart + fadeDuration
                    UIView.addKeyframeWithRelativeStartTime( fadeStartTime, relativeDuration: fadeDuration ) {
                        
                        () -> Void in

                        self.segmentViews[index].alpha = endAlpha
                    }

                    frameStart += frameDuration
                }

                UIView.addKeyframeWithRelativeStartTime( 0.0, relativeDuration: 100.0 ) {
                    
                    contentView.frame = contentFrame
                }
        }) {
            
            ( finished ) -> Void in
            
            if contentFrame.height != minHeight {
                
                for view in segmentViews {
                    
                    view.hidden = true
                }
            }
            
            completion?()
        }
    }
}
