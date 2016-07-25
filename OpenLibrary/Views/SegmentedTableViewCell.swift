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

class SegmentedTableViewCell: OLTableViewCell {
    
    struct CellHeights {
        
        var closed:     CGFloat = 0.0
        var open:       CGFloat = 0.0
        var isExpanded: Bool    = false
    }
    
    static private var segmentedTableViewCells: [UITableView: SegmentedTableViewCell] = [:]

    static private var animating = false
    
    static private var minimumCellHeight: CGFloat = 0.0
    static private var tableCellHeights = [UITableView: [NSIndexPath: CellHeights]]()

    @IBOutlet weak private var segmentView0: UIView!
    
    @IBOutlet private var segmentViews: Array< UIView >!
    @IBOutlet private var segmentViewTops: Array< NSLayoutConstraint >!
    
    private var tableView: UITableView?
    
    private var reversedSegmentViews = [UIView]()
    private var reversedSegmentViewTops = [NSLayoutConstraint]()
    
    private var segmentDuration = NSTimeInterval( 1.0 ) // NSTimeInterval( 0.3 )
    
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

        self.segmentViews.sortInPlace{ $0.frame.origin.y < $1.frame.origin.y }
        self.segmentViewTops.sortInPlace{ $0.constant < $1.constant }
        
        self.reversedSegmentViews = self.segmentViews.reverse()
        self.reversedSegmentViewTops = self.segmentViewTops.reverse()
    }
    
    func configureCell( tableView: UITableView, indexPath: NSIndexPath ) -> Void {
        
        self.tableView = tableView
    }
    
    func configure( tableView: UITableView, indexPath: NSIndexPath, withData data: AnyObject? ) {
        
        configureCell( tableView, indexPath: indexPath )
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
        
        return 100 + 1
    }
    
    class func estimatedCellHeight( tableView: UITableView, indexPath: NSIndexPath ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
        
        if let cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] {
            
            height = cellHeights.isExpanded ? cellHeights.open : cellHeights.closed
        }

        return height
    }
    
    class func cellHeight( tableView: UITableView, indexPath: NSIndexPath, withData data: AnyObject? ) -> CGFloat {
        
        var height = SegmentedTableViewCell.estimatedCellHeight
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
        
        if let cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] {
            
            height = cellHeights.isExpanded ? cellHeights.open : cellHeights.closed

            print( "\(indexPath.row): \(cellHeights.open) \(cellHeights.closed) \(cellHeights.isExpanded)" )

        } else {

            var staticCell: SegmentedTableViewCell? = SegmentedTableViewCell.segmentedTableViewCells[tableView]
        
            if nil == staticCell {

                let nameOfClass = self.nameOfClass
                staticCell =
                    NSBundle.mainBundle().loadNibNamed( nameOfClass, owner: self, options: nil ).first as? SegmentedTableViewCell

                SegmentedTableViewCell.segmentedTableViewCells[tableView] = staticCell
            }
            
            if let staticCell = staticCell {
                
                staticCell.configure( tableView, indexPath: indexPath, withData: data )
                
                staticCell.bounds = CGRectMake( 0.0, 0.0, tableView.bounds.width, staticCell.bounds.height )
                staticCell.layoutIfNeeded()
                
                var openHeight: CGFloat = 0.0
                for segment in staticCell.segmentViews {
                    
                    openHeight += segment.systemLayoutSizeFittingSize( UILayoutFittingCompressedSize ).height
                }
                let closedHeight = staticCell.segmentView0.systemLayoutSizeFittingSize( UILayoutFittingCompressedSize ).height
                
                let cellHeights = CellHeights(
                    closed: closedHeight,
                    open: openHeight,
                    isExpanded: false
                )
                SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] = cellHeights
                
                height = cellHeights.isExpanded ? cellHeights.open : cellHeights.closed
                
                print( "\(indexPath.row): \(cellHeights.open) \(cellHeights.closed) \(cellHeights.isExpanded)" )
            }
        }
        
        return height
    }
    
    class func emptyCellHeights( tableView: UITableView ) -> Void {
        
        SegmentedTableViewCell.tableCellHeights[tableView] = [:]
    }
    
    class func purgeCellHeights( tableView: UITableView ) -> Void {
        
        SegmentedTableViewCell.tableCellHeights[tableView] = nil
    }
    
    class func setOpen( tableView: UITableView, indexPath: NSIndexPath ) {
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
            
        var cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]?[indexPath]
        
        assert( nil != cellHeights )
        
        cellHeights!.isExpanded = true
        
        SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] = cellHeights!
    }
    
    class func setClosed( tableView: UITableView, indexPath: NSIndexPath ) {
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
        
        var cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]?[indexPath]
        
        assert( nil != cellHeights )
        
        cellHeights!.isExpanded = false
        SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] = cellHeights!
    }
    
    class func closeAllCells( tableView: UITableView ) -> Void {
        
        if nil == SegmentedTableViewCell.tableCellHeights[tableView] {
            
            emptyCellHeights( tableView )
            
        } else {

            for (k,v) in SegmentedTableViewCell.tableCellHeights[tableView]! {
                
                SegmentedTableViewCell.tableCellHeights[tableView]![k] =
                    CellHeights( closed: v.closed, open: v.open, isExpanded: false  )
            }
        }
    }
    
    private func segmentZeroHeight() -> CGFloat {
        
        return ceil( ceil( segmentView0.bounds.origin.y ) + ceil( segmentView0.bounds.height ) )
    }
    
    private func totalSegmentHeight() -> CGFloat {
        
        return ceil( segmentZeroHeight() + segmentViews.reduce( 0.0 ) { $0 + ceil( $1.bounds.height ) } )
    }
    
    func isAnimating() -> Bool {
        
        return SegmentedTableViewCell.animating
    }
    
    func isOpen( tableView: UITableView, indexPath: NSIndexPath ) -> Bool {
        
        return SegmentedTableViewCell.tableCellHeights[tableView]?[indexPath]?.isExpanded ?? false
    }
    
    func setOpen( tableView: UITableView, indexPath: NSIndexPath ) {
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
        
        let cellHeights =
            CellHeights(
                    closed: segmentZeroHeight(),
                    open: totalSegmentHeight(),
                    isExpanded: true
                )
        
        SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] = cellHeights
    }
    
    func setClosed( tableView: UITableView, indexPath: NSIndexPath ) {
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
        
        let cellHeights =
            CellHeights(
                closed: segmentZeroHeight(),
                open: totalSegmentHeight(),
                isExpanded: false
        )
        
        SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] = cellHeights
    }

    func adjustCellHeights( tableView: UITableView, indexPath: NSIndexPath ) -> CellHeights {
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )
        
        var isExpanded = false
        if let cellHeights = SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] {
            isExpanded = cellHeights.isExpanded
        }
        
        let cellHeights =
            CellHeights(
                    closed: segmentZeroHeight(),
                    open: totalSegmentHeight(),
                    isExpanded: isExpanded
                )
        
        SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] = cellHeights
        
        return cellHeights
    }
    
    func selectedAnimation( tableView: UITableView, indexPath: NSIndexPath ) -> Bool {
        
        let shouldBeOpen = isOpen( tableView, indexPath: indexPath )
        
        selectedAnimation( tableView, indexPath: indexPath, expandCell: shouldBeOpen, animated: false, completion: nil )
        
        return shouldBeOpen
    }

    func selectedAnimation( tableView: UITableView, indexPath: NSIndexPath, expandCell: Bool, animated: Bool, completion: (Void -> Void)? ) -> Bool {
        
        assert( nil != SegmentedTableViewCell.tableCellHeights[tableView] )

        adjustCellHeights( tableView, indexPath: indexPath )
        
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
                open: totalSegmentHeight(),
                isExpanded: expandCell
            )
        
        SegmentedTableViewCell.tableCellHeights[tableView]![indexPath] = cellHeights
        
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
        
//        for view in reversedSegmentViews { view.hidden = false }
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
//                for view in self.segmentViews { view.hidden = true }

                completion? ()
            }
    }
    
    private func moveSegmentFrames( segmentViews: [UIView], yArray: [CGFloat] ) -> [CGRect] {
        
        var frames = [CGRect]( count: yArray.count, repeatedValue: CGRectZero )

        for (index,y) in yArray.enumerate() {
            
            frames[index] = segmentViews[index].frame
            frames[index].origin.y = y

//            print( "\(index): \(y) \(frames[index])")
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

        let totalHeight: Double = segmentViews.reduce( 0.0 ) { $0 + Double( $1.frame.height ) }
        
        setSegmementViewAlpha( 1.0 )
        
        UIView.animateKeyframesWithDuration(
            totalDuration,
            delay: 0,
            options: .BeginFromCurrentState,
            animations: {
                
                () -> Void in
                
                var frameStart: Double = 0.0
                for (index, view) in segmentViews.enumerate() {
                    
                    let dyN = view.frame.height
                    let frameDuration = Double(dyN) / totalHeight
                    
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

        }) {
            
            ( finished ) -> Void in
            
            completion?()
        }
    }
}
