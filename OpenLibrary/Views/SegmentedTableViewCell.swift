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
    
    init( indexPath: IndexPath ) {
        
        title = "Title: \((indexPath as NSIndexPath).row)"
        subTitle = "Subtitle: \((indexPath as NSIndexPath).row)"
        author = "Author: \((indexPath as NSIndexPath).row)"
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
    
    static fileprivate var segmentedTableViewCells: [UITableView: SegmentedTableViewCell] = [:]
    static fileprivate var openCells: [UITableView: String] = [:]

    static fileprivate var animating = false
    
    static fileprivate var minimumCellHeight: CGFloat = 0.0
    static fileprivate var tableCellHeightsByKey = [UITableView: [String: CellHeights]]()
    static fileprivate var tableCellKeysByIndexPath = [UITableView: [IndexPath: String]]()

    @IBOutlet weak fileprivate var segmentView0: UIView!
    
    @IBOutlet fileprivate var segmentViews: Array< UIView >!
    @IBOutlet fileprivate var segmentViewTops: Array< NSLayoutConstraint >!
    
//    private var tableView: UITableView?
    
    fileprivate var reversedSegmentViews = [UIView]()
    fileprivate var reversedSegmentViewTops = [NSLayoutConstraint]()
    
    fileprivate var segmentDuration = TimeInterval( 1.0 ) // NSTimeInterval( 0.3 )
    
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
        
        self.segmentViews.sort{ $0.frame.origin.y < $1.frame.origin.y }
        self.segmentViewTops.sort{ $0.constant < $1.constant }
        
        self.reversedSegmentViews = self.segmentViews.reversed()
        self.reversedSegmentViewTops = self.segmentViewTops.reversed()
    }
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        key = ""
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
    
    class func keyForIndexPath( _ tableView: UITableView, indexPath: IndexPath, key: String ) {
        
        SegmentedTableViewCell.tableCellKeysByIndexPath[tableView]?[indexPath] = key
    }
    
    class func isExpanded( _ tableView: UITableView, key: String ) -> Bool {
        
        guard let openCellKey = SegmentedTableViewCell.openCells[tableView] else {
            
            return false
        }
        
        return key == openCellKey
    }
    
    class func estimatedCellHeight( _ tableView: UITableView, key: String ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        if let cellHeights = SegmentedTableViewCell.tableCellHeightsByKey[tableView]![key] {
            
            let isExpanded = SegmentedTableViewCell.isExpanded( tableView, key: key )
            
            height = isExpanded ? cellHeights.open : cellHeights.closed
        }

        return height
    }
    
    class func emptyCellHeights( _ tableView: UITableView ) -> Void {
        
        SegmentedTableViewCell.tableCellHeightsByKey[tableView] = [:]
        SegmentedTableViewCell.tableCellKeysByIndexPath[tableView] = [:]
    }
    
    class func emptyIndexPathToKeyLookup( _ tableView: UITableView ) -> Void {
        
        SegmentedTableViewCell.tableCellKeysByIndexPath[tableView] = [:]
    }
    
    class func setOpen( _ tableView: UITableView, indexPath: IndexPath ) {
        
        if let key = SegmentedTableViewCell.tableCellKeysByIndexPath[tableView]?[indexPath] {
            
            SegmentedTableViewCell.openCells[tableView] = key
        }
    }
    
    class func setClosed( _ tableView: UITableView, indexPath: IndexPath ) {
        
        if let key = SegmentedTableViewCell.tableCellKeysByIndexPath[tableView]?[indexPath] {
            
            if key == SegmentedTableViewCell.openCells[tableView] {
                
                SegmentedTableViewCell.openCells[tableView] = nil
            }
        }
    }
    
    class func closeAllCells( _ tableView: UITableView ) -> Void {
        
        SegmentedTableViewCell.openCells[tableView] = nil
    }
    
    class func cachedHeightForRowAtIndexPath( _ tableView: UITableView, indexPath: IndexPath ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        if let key = SegmentedTableViewCell.tableCellKeysByIndexPath[tableView]?[indexPath] {
            
            if let cellHeights = SegmentedTableViewCell.tableCellHeightsByKey[tableView]?[key] {
                
                let isExpanded = SegmentedTableViewCell.isExpanded( tableView, key: key )
                
                height = isExpanded ? cellHeights.open : cellHeights.closed
            }
        }
        
        return height
    }
    
    fileprivate func segmentZeroHeight() -> CGFloat {
        
        return ceil( ceil( segmentView0.bounds.origin.y ) + ceil( segmentView0.bounds.height ) )
    }
    
    fileprivate func totalSegmentHeight() -> CGFloat {
        
        return ceil( segmentViews.reduce( segmentZeroHeight() ) { $0 + ceil( $1.bounds.height ) } )
    }
    
    func isAnimating() -> Bool {
        
        return SegmentedTableViewCell.animating
    }
    
    func setOpen( _ tableView: UITableView, key: String ) {
        
        SegmentedTableViewCell.openCells[tableView] = key
    }
    
    func setClosed( _ tableView: UITableView ) {
        
        if key == SegmentedTableViewCell.openCells[tableView] {
            
            SegmentedTableViewCell.openCells[tableView] = nil
        }
    }
    
    func height( _ tableView: UITableView ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        assert( nil != SegmentedTableViewCell.tableCellHeightsByKey[tableView] )
        
        let isExpanded = SegmentedTableViewCell.isExpanded( tableView, key: key )
        
        var cellHeights: CellHeights?
        
        if !key.isEmpty {

            cellHeights = SegmentedTableViewCell.tableCellHeightsByKey[tableView]?[key]
        }
        
        if let cellHeights = cellHeights {
            
            height = isExpanded ? cellHeights.open : cellHeights.closed
            
        } else {
            
            height = saveCellHeights( tableView, key: key, isExpanded: isExpanded )
        }
        
        return height
    }
    
    func saveCellHeights( _ tableView: UITableView, key: String, isExpanded: Bool ) -> CGFloat {
        
        bounds = CGRect( x: 0.0, y: 0.0, width: tableView.bounds.width, height: bounds.height )
        layoutIfNeeded()
        
        let closedHeight = segmentZeroHeight()
        let openHeight = totalSegmentHeight()
        
        let height = isExpanded ? openHeight : closedHeight
        
        if !key.isEmpty {

            let cellHeights = CellHeights( closed: closedHeight, open: openHeight )
            SegmentedTableViewCell.tableCellHeightsByKey[tableView]![key] = cellHeights
        }
        
        return height
    }
    
    func saveIndexPath( _ indexPath: IndexPath, inTableView: UITableView, forKey: String ) {
        
        GeneralSearchResultSegmentedTableViewCell.keyForIndexPath( inTableView, indexPath: indexPath, key: key )
    }
    
    func selectedAnimation( _ tableView: UITableView, key: String ) -> Bool {
        
        let shouldBeOpen = SegmentedTableViewCell.isExpanded( tableView, key: key )
        
        _ = selectedAnimation( tableView, key: key, expandCell: shouldBeOpen, animated: false, completion: nil )
        
        return shouldBeOpen
    }

    func selectedAnimation( _ tableView: UITableView, key: String, expandCell: Bool, animated: Bool, completion: ((Void) -> Void)? ) -> Bool {
        
        assert( nil != SegmentedTableViewCell.tableCellHeightsByKey[tableView] )

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
        
        SegmentedTableViewCell.tableCellHeightsByKey[tableView]![key] = cellHeights
        
//        print( "\(indexPath.row) Segment0 top: \(segmentView0.frame.origin.y)")
        
        return expandCell
    }
    
    fileprivate func setSegmementViewAlpha( _ alpha: CGFloat ) {
        
        for view in segmentViews {
            view.alpha = alpha
        }
    }
    
    fileprivate func moveSegmentViewTops( _ yOffsets: [CGFloat] ) {
        
        for (index, segmentViewTop) in segmentViewTops.enumerated() {
            
            segmentViewTop.constant = yOffsets[index]
        }
    }
    
    fileprivate func openTop() -> [CGFloat] {
        
        var result = [CGFloat]( repeating: 0.0, count: self.segmentViews.count )
        
        var yOffset = ceil( segmentView0.frame.origin.y ) + ceil( segmentView0.frame.height )
        for (index, view) in segmentViews.enumerated() {
            
            result[index] = ceil( yOffset )
            
            yOffset += view.frame.height
        }

        return result
    }
    
    fileprivate func closedTop() -> [CGFloat] {
    
        return segmentViews.map { floor( segmentView0.frame.origin.y + ( segmentView0.frame.height - $0.frame.height ) ) }
    }
    
    fileprivate func openAnimation( _ totalDuration: TimeInterval, endY: [CGFloat], completion: ((Void) -> Void)? ) {
        
        let revEndY: [CGFloat] = endY.reversed()
        
        animate(
                reversedSegmentViews,
                segmentViewTops: reversedSegmentViewTops,
                totalDuration: totalDuration,
                endY: revEndY, endAlpha: 1.0
            ) {

                completion?()
            }
    }

    fileprivate func closeAnimation( _ totalDuration: TimeInterval, endY: [CGFloat], completion: ((Void) -> Void)? ) {
        
        animate(
                segmentViews,
                segmentViewTops: segmentViewTops,
                totalDuration: totalDuration,
                endY: endY, endAlpha: 0.0
            ) {

                completion? ()
            }
    }
    
    fileprivate func moveSegmentFrames( _ segmentViews: [UIView], yArray: [CGFloat] ) -> [CGRect] {
        
        var frames = [CGRect]( repeating: CGRect.zero, count: yArray.count )

        for (index,y) in yArray.enumerated() {
            
            frames[index] = segmentViews[index].frame
            frames[index].origin.y = y

        }
        
        return frames
    }
    
    fileprivate func animate(
            _ segmentViews: [UIView],
            segmentViewTops: [NSLayoutConstraint],
            totalDuration: TimeInterval,
            endY: [CGFloat], endAlpha: CGFloat,
            completion: ((Void) -> Void)? ) -> Void {
        
        let segmentViewEndFrames = moveSegmentFrames( segmentViews, yArray: endY )

        var totalHeight = CGFloat( 0.0 )
        for view in segmentViews {
            
            totalHeight += view.frame.height
            view.isHidden = false
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
        
        UIView.animateKeyframes(
            withDuration: totalDuration,
            delay: 0,
            options: .beginFromCurrentState,
            animations: {
                
                () -> Void in
                
                var frameStart: Double = 0.0
                for (index, view) in segmentViews.enumerated() {
                    
                    let dyN = view.frame.height
                    let frameDuration = Double( dyN ) / Double( totalHeight )
                    
                    UIView.addKeyframe( withRelativeStartTime: frameStart, relativeDuration: frameDuration ) {
                        
                        view.frame = segmentViewEndFrames[index]
                        segmentViewTops[index].constant = endY[index]
                    }
                
                    // fade out (or in) the master view top and bottom views
                    // want the fade out animation to happen near the end of the transition
                    // and the fade in animation to happen at the start of the transition
                    let fadeDuration = frameDuration / 2
                    let fadeStartTime = endAlpha != 0.0 ? frameStart : frameStart + fadeDuration
                    UIView.addKeyframe( withRelativeStartTime: fadeStartTime, relativeDuration: fadeDuration ) {
                        
                        () -> Void in

                        self.segmentViews[index].alpha = endAlpha
                    }

                    frameStart += frameDuration
                }

                UIView.addKeyframe( withRelativeStartTime: 0.0, relativeDuration: 100.0 ) {
                    
                    contentView.frame = contentFrame
                }
        }) {
            
            ( finished ) -> Void in
            
            if contentFrame.height != minHeight {
                
                for view in segmentViews {
                    
                    view.isHidden = true
                }
            }
            
            completion?()
        }
    }
}
