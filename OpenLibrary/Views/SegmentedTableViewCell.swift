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
    @IBOutlet weak fileprivate var segmentView0Content: UIView!
    
    @IBOutlet fileprivate var segmentViews: [UIView]!
    @IBOutlet fileprivate var segmentViewOpen: [NSLayoutConstraint]!
    @IBOutlet fileprivate var segmentViewClosed: [NSLayoutConstraint]!
    
//    private var tableView: UITableView?
    
//    fileprivate var reversedSegmentViews = [UIView]()
//    fileprivate var reversedSegmentViewTops = [NSLayoutConstraint]()
    
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
        self.segmentViewOpen = [NSLayoutConstraint]()
        self.segmentViewClosed = [NSLayoutConstraint]()
    }
        
    override func awakeFromNib() {

        super.awakeFromNib()
        
        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        for constraint in segmentViewOpen {
            
            constraint.isActive = false
        }
        
        for constraint in segmentViewClosed {
            
            constraint.isActive = true
        }
        
        layoutIfNeeded()
        
        key = ""
    }

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
        
        return 92 + 1
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
    
    class func emptyCellHeights( _ tableView: UITableView? ) -> Void {

        guard let tableView = tableView else { return }
        
        SegmentedTableViewCell.tableCellHeightsByKey[tableView] = [:]
        SegmentedTableViewCell.tableCellKeysByIndexPath[tableView] = [:]
    }
    
    class func emptyIndexPathToKeyLookup( _ tableView: UITableView? ) -> Void {
        
        guard let tableView = tableView else { return }

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
    
    func isExpanded( in tableView: UITableView ) -> Bool {
        
        return key == SegmentedTableViewCell.openCells[tableView]
    }
    
    fileprivate func segmentZeroHeight() -> CGFloat {
        
        return ceil( segmentView0.bounds.height )
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
        
        SegmentedTableViewCell.keyForIndexPath( inTableView, indexPath: indexPath, key: key )
    }
    
    func selectedAnimation( _ tableView: UITableView, key: String ) -> Bool {
        
        let shouldBeOpen = SegmentedTableViewCell.isExpanded( tableView, key: key )
        
        _ = selectedAnimation( tableView, key: key, expandCell: shouldBeOpen, animated: false, completion: nil )
        
        return shouldBeOpen
    }

    func selectedAnimation( _ tableView: UITableView, key: String, expandCell: Bool, animated: Bool, completion: (() -> Void)? ) -> Bool {
        
        assert( nil != SegmentedTableViewCell.tableCellHeightsByKey[tableView] )

        var cellHeights = SegmentedTableViewCell.tableCellHeightsByKey[tableView]![key]
        
        if expandCell {

            if animated {

                openAnimation( segmentDuration ) {

                    completion?()
                }
                
            } else  {

                openSegments()
                setSegmementViewAlpha( 1 )
            }
            
        } else {

            if animated {

                closeAnimation( segmentDuration ) {

                     completion?()
                }
            } else {

                setSegmementViewAlpha( 0 )
                closeSegments()
             }

            cellHeights =
                CellHeights(
                    closed: segmentZeroHeight(),
                    open: totalSegmentHeight()
                )
        
        }
        
        SegmentedTableViewCell.tableCellHeightsByKey[tableView]![key] = cellHeights
        
//        print( "\(indexPath.row) Segment0 top: \(segmentView0.frame.origin.y)")
        
        return expandCell
    }
    
    fileprivate func setSegmementViewAlpha( _ alpha: CGFloat ) {
        
        for view in segmentViews {
            view.alpha = alpha
        }
    }
    
    fileprivate func openSegments() -> Void {
        
        for constraint in segmentViewOpen {
            
            constraint.isActive = true
        }
        
        for constraint in segmentViewClosed {
            
            constraint.isActive = false
        }
        
    }
    
    fileprivate func closeSegments() -> Void {
        
        for constraint in segmentViewOpen {
            
            constraint.isActive = false
        }
        
        for constraint in segmentViewClosed {
            
            constraint.isActive = true
        }
        
    }
    
    fileprivate func openFrames() -> [CGRect] {
        
        var result: [CGRect] = []
        
        segmentView0.layoutIfNeeded()
        
        var yOffset = ceil( segmentView0.frame.origin.y ) + ceil( segmentView0.frame.height )
        for view in segmentViews {
            
            view.layoutIfNeeded()

            var newRect = view.frame
            newRect.origin.y = ceil( yOffset )
            result.append( newRect )
            
            yOffset += view.frame.height
        }
        
        layoutIfNeeded()
        
        return result
    }
    
    fileprivate func closedFrames() -> [CGRect] {
        
        var result: [CGRect] = []
        
        segmentView0.layoutIfNeeded()
        
        let segmentView0Bottom = floor( segmentView0.frame.origin.y + segmentView0.frame.height )
        for view in segmentViews {
            
            view.layoutIfNeeded()

            var newRect = view.frame
            newRect.origin.y = ceil( segmentView0Bottom - newRect.height )
            result.append( newRect )
        }
        
        layoutIfNeeded()
        
        return result
    }

    fileprivate func openAnimation( _ totalDuration: TimeInterval, completion: (() -> Void)? ) {
        
        animateOpen(
                totalDuration: totalDuration
            ) {

                completion?()
            }
    }

    fileprivate func closeAnimation( _ totalDuration: TimeInterval, completion: (() -> Void)? ) {
        
        animateClosed(
                totalDuration: totalDuration
            ) {

                completion? ()
            }
    }
    
    fileprivate func animateOpen(
            totalDuration: TimeInterval,
            completion: (() -> Void)? ) -> Void {
        
        let segmentViews: [UIView] = self.segmentViews.reversed()
        let segmentViewEndFrames: [CGRect] = openFrames().reversed()
        let segmentViewOpen: [NSLayoutConstraint] = self.segmentViewOpen.reversed()
        let segmentViewClosed: [NSLayoutConstraint] = self.segmentViewClosed.reversed()

        let totalHeight = totalSegmentHeight()
        
        let endAlpha: CGFloat = 1.0
        setSegmementViewAlpha( 1.0 )
        
        UIView.animateKeyframes(
            withDuration: totalDuration,
            delay: 0,
            options: .beginFromCurrentState,
            animations: {
                
                () -> Void in
                
                var frameStart: Double = 0.0
                for (segmentIndex, view) in segmentViews.enumerated() {

                    let dyN = view.frame.height
                    let frameDuration = Double( dyN ) / Double( totalHeight )
                    
                    let endFrame: CGRect = segmentViewEndFrames[segmentIndex]
                    UIView.addKeyframe( withRelativeStartTime: frameStart, relativeDuration: frameDuration ) {
                        
                        view.frame = endFrame
                        segmentViewOpen[segmentIndex].isActive = true
                        segmentViewClosed[segmentIndex].isActive = false
                    }
                
                    // fade out (or in) the master view top and bottom views
                    // want the fade out animation to happen near the end of the transition
                    // and the fade in animation to happen at the start of the transition
                    let fadeDuration = frameDuration / 4
                    let fadeStartTime = frameStart
                    UIView.addKeyframe( withRelativeStartTime: fadeStartTime, relativeDuration: fadeDuration ) {
                        
                        () -> Void in

                        view.alpha = endAlpha
                    }

                    frameStart += frameDuration
                }

        }) {
            
            ( finished ) -> Void in
            
            completion?()
        }
    }

    fileprivate func animateClosed(
        totalDuration: TimeInterval,
        completion: (() -> Void)? ) -> Void {
        
        let segmentViews: [UIView] = self.segmentViews.reversed()
        let segmentViewEndFrames: [CGRect] = openFrames().reversed()
        let segmentViewOpen: [NSLayoutConstraint] = self.segmentViewOpen
        let segmentViewClosed:  [NSLayoutConstraint] = self.segmentViewClosed
        
        setSegmementViewAlpha( 1.0 )
        let endAlpha: CGFloat = 0.0
        
        let totalHeight = totalSegmentHeight()

        UIView.animateKeyframes(
            withDuration: totalDuration,
            delay: 0,
            options: .beginFromCurrentState,
            animations: {
                
                () -> Void in
                
                var frameStart: Double = 0.0
                for (segmentIndex, view) in segmentViews.enumerated() {
                    
                    let dyN = view.frame.height
                    let frameDuration = Double( dyN ) / Double( totalHeight )
                    
                    UIView.addKeyframe( withRelativeStartTime: frameStart, relativeDuration: frameDuration ) {
                        
                        view.frame = segmentViewEndFrames[segmentIndex]
                        segmentViewOpen[segmentIndex].isActive = false
                        segmentViewClosed[segmentIndex].isActive = true
                    }
                    
                    // fade out (or in) the master view top and bottom views
                    // want the fade out animation to happen near the end of the transition
                    // and the fade in animation to happen at the start of the transition
                    let fadeDuration = frameDuration / 4
                    let fadeStartTime = ( frameStart + frameDuration ) - fadeDuration
                    UIView.addKeyframe( withRelativeStartTime: fadeStartTime, relativeDuration: fadeDuration ) {
                        
                        () -> Void in
                        
                        self.segmentViews[segmentIndex].alpha = endAlpha
                    }
                    
                    frameStart += frameDuration
                }
                
        }) {
            
            ( finished ) -> Void in
            
            completion?()
        }
    }

}
