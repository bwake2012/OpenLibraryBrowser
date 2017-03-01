//
//  OLHeaderView.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 11/25/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import UIKit

@objc protocol OLHeaderViewDelegate {
    
    func performSegue( segueName: String, sender: Any? )
}

private struct SummaryLine {

    weak var label: UILabel!
    weak var button: UIButton!
    var segueName: String
    var textStyle: UIFontTextStyle
}

fileprivate let standardSpacing: CGFloat = 8.0
fileprivate let noSpacing: CGFloat = 0.0

@IBDesignable
class OLHeaderView: UIView {

    // MARK: Public Properties
    
    @IBOutlet weak var headerViewDelegate: OLHeaderViewDelegate?
    
    @IBInspectable var image: UIImage? {

        set {
            
            let imageWasNil = contentStack.arrangedSubviews.first != imageParentView
            imageView.image = newValue
            zoomImage.isEnabled = nil != newValue
            imageZoomSegueName = nil == newValue ? "" : "zoomLargeImage"
            if nil == newValue && !imageWasNil {
                
                contentStack.removeArrangedSubview( imageParentView )
                
            } else if nil != newValue && imageWasNil {
                
                contentStack.insertArrangedSubview( imageParentView, at: 0 )
            }
        }

        get {
            
            return imageView.image
        }
    }

    // MARK: Private UI Properties
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentStack: UIStackView!
    @IBOutlet weak var imageParentView: UIView!
    @IBOutlet weak var imageView: AspectRatioImageView!
    @IBOutlet weak var zoomImage: UIButton!
    @IBOutlet weak var summaryStack: UIStackView!
    
    // MARK: Private UI Actions
    @IBAction func zoomTheImage( sender: UIButton ) {

        assert( !imageZoomSegueName.isEmpty )
        if !imageZoomSegueName.isEmpty {
            
            headerViewDelegate?.performSegue( segueName: imageZoomSegueName, sender: sender )
        }
    }
    
    @IBAction func summaryLineTapped( sender: UIButton ) {
        
        if let delegate = headerViewDelegate {
            let summaryLine = summaryLines.reduce( nil ) {
                
                found, summaryLine -> SummaryLine? in
                
                if nil != found {
                    return found
                } else {
                    
                    return sender != summaryLine.button ? nil : summaryLine
                }
            }
            
            if let summaryLine = summaryLine, !summaryLine.segueName.isEmpty {

                delegate.performSegue( segueName: summaryLine.segueName, sender: sender )
            }
        }
    }
    
    // MARK: Private internal Properties
    private var summaryLines: [SummaryLine] = []
    private var imageZoomSegueName: String = ""
    
    // MARK: init
    override init(frame: CGRect) {
        // 1. setup any properties here
        
        // 2. call super.init(frame:)
        super.init(frame: frame)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // 1. setup any properties here
        
        // 2. call super.init(coder:)
        super.init(coder: aDecoder)
        
        // 3. Setup view from .xib file
        xibSetup()
    }
    
    func xibSetup() {
        contentView = loadViewFromNib()
        
        // Adding custom subview on top of our view (over any custom drawing > see note below)
        addSubview(contentView)
        
        // use bounds not frame or it'll be offset
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.frame = bounds
        
        // Make the view stretch with containing view
        NSLayoutConstraint( item: contentView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0 ).isActive = true
        
        NSLayoutConstraint( item: contentView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0 ).isActive = true
        
        NSLayoutConstraint( item: contentView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0 ).isActive = true
        
        NSLayoutConstraint( item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0 ).isActive = true
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nibName = String( describing: OLHeaderView.self )
        let nib = UINib(nibName: nibName, bundle: bundle)
        
        // Assumes UIView is top level and only object in CustomView.xib file
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
    }

    // MARK: Header Functionality
    func clearHeader() -> Void {
        
        imageView.image = nil
        
        clearSummary()
    }
    
    func clearSummary() -> Void {
        
        for line in summaryLines {
            
            line.label.removeFromSuperview()
            line.button?.removeFromSuperview()
        }
        
        summaryLines = []
    }
    
    func insertSummaryLine( index: Int, text: String, style: UIFontTextStyle, segueName: String ) {
        
        assert( index >= 0 && index <= summaryLines.count )
        assert( index >= 0 && index <= summaryStack.arrangedSubviews.count )
        
        let label = UILabel()
        let button = UIButton()
        summaryLines.insert(
                SummaryLine(
                    label: label,
                    button: button,
                    segueName: segueName,
                    textStyle: style
                ),
                at: index
            )
        
        summaryStack.insertArrangedSubview( label, at: index )
        label.attributedText = makeAttributedString( string: text, style: style )
        label.textColor = segueName.isEmpty ? UIColor.darkText : self.tintColor
        label.backgroundColor = self.contentView.backgroundColor
        label.isOpaque = true
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority( 1000, for: .vertical )
        label.numberOfLines = 0

        button.backgroundColor = UIColor.clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget( self, action: #selector( summaryLineTapped ), for: .touchUpInside )
        button.isEnabled = !segueName.isEmpty
        summaryStack.addSubview( button )

        NSLayoutConstraint( item: button, attribute: .leading, relatedBy: .equal, toItem: label, attribute: .leading, multiplier: 1.0, constant: 0.0 ).isActive = true
        
        NSLayoutConstraint( item: button, attribute: .trailing, relatedBy: .equal, toItem: label, attribute: .trailing, multiplier: 1.0, constant: 0.0 ).isActive = true
        
        NSLayoutConstraint( item: button, attribute: .top, relatedBy: .equal, toItem: label, attribute: .top, multiplier: 1.0, constant: 0.0 ).isActive = true
        
        NSLayoutConstraint( item: button, attribute: .bottom, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1.0, constant: 0.0 ).isActive = true
    }
    
    func addSummaryLine( text: String, style: UIFontTextStyle, segueName: String ) {
        
        insertSummaryLine(index: summaryLines.count, text: text, style: style, segueName: segueName )
    }

    func setSummaryLine( index: Int, text: String, style: UIFontTextStyle, segueName: String ) {

        assert( index >= 0 && index <= summaryLines.count )
        assert( index >= 0 && index <= summaryStack.arrangedSubviews.count )
        
        if index == summaryLines.count {
            
            addSummaryLine( text: text, style: style, segueName: segueName )
            
        } else if index < 0 || index > summaryLines.count {

            fatalError( "Error: Header Summary Lineindex \(index) out of range 0..\(summaryLines.count)" )
            
        } else {
            
            summaryLines[index].label.attributedText = makeAttributedString( string: text, style: style )
            summaryLines[index].label.textColor = segueName.isEmpty ? UIColor.darkText : self.tintColor
            summaryLines[index].button.isEnabled = !text.isEmpty && !segueName.isEmpty
            summaryLines[index].segueName = segueName
            summaryLines[index].textStyle = style
        }
    }
    
    // MARK: Utility
    func makeAttributedString( string: String, style: UIFontTextStyle ) -> NSAttributedString {

        let attributes = [NSFontAttributeName: UIFont.preferredFont( forTextStyle: style )]
        
        let attributedString = NSMutableAttributedString( string: string, attributes: attributes )
        
        return attributedString
    }
}

extension OLHeaderView: TransitionSourceImage {
    
    func transitionSourceRectImageView() -> UIImageView? {
        
        return imageView
    }
}

