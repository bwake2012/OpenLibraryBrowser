//
//  NSURLSession+JSONTasks.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 8/23/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

private let httpHeaderAccept = "Accept"

let jsonMIMEType = "application/json"
let xmlMIMEType  = "application/xml"

let htmlMIMEType = "text/html"
let textMIMEType = "text/plain"

let pngMIMEType  = "image/png"
let jpegMIMEType = "image/jpeg"
let jpgMIMEType  = "image/jpg"

extension NSURLSession {
    
    func mimeTypeDownloadTaskWithURL( mimeType: String, url: NSURL, completionHandler: ( NSURL?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDownloadTask {
        
        let request = NSMutableURLRequest( URL: url )
        request.setValue( mimeType, forHTTPHeaderField: httpHeaderAccept )
        
        let task = NSURLSession.sharedSession().downloadTaskWithURL( url, completionHandler: completionHandler )
        
        return task
    }
    
    func mimeTypeDataTaskWithURL( mimeType: String, url: NSURL, completionHandler: ( NSData?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDataTask {
        
        let request = NSMutableURLRequest( URL: url )
        request.setValue( mimeType, forHTTPHeaderField: httpHeaderAccept )
        let task = NSURLSession.sharedSession().dataTaskWithRequest( request, completionHandler: completionHandler )

        return task
    }

    func jsonDownloadTaskWithURL( url: NSURL, completionHandler: ( NSURL?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( jsonMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func jsonDataTaskWithURL( url: NSURL, completionHandler: ( NSData?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( jsonMIMEType, url: url, completionHandler: completionHandler )
    }

    func xmlDownloadTaskWithURL( url: NSURL, completionHandler: ( NSURL?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( xmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func xmlDataTaskWithURL( url: NSURL, completionHandler: ( NSData?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( xmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func htmlDownloadTaskWithURL( url: NSURL, completionHandler: ( NSURL?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( htmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func htmlDataTaskWithURL( url: NSURL, completionHandler: ( NSData?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( htmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func pngDownloadTaskWithURL( url: NSURL, completionHandler: ( NSURL?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( pngMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func pngDataTaskWithURL( url: NSURL, completionHandler: ( NSData?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( pngMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func jpgDownloadTaskWithURL( url: NSURL, completionHandler: ( NSURL?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( jpgMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func jpgDataTaskWithURL( url: NSURL, completionHandler: ( NSData?, NSURLResponse?, NSError? ) -> Void ) -> NSURLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( jpgMIMEType, url: url, completionHandler: completionHandler )
    }
    

}