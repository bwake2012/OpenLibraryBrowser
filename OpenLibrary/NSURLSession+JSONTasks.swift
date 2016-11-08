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

extension URLSession {
    
    func mimeTypeDownloadTaskWithURL( _ mimeType: String, url: URL, completionHandler: @escaping ( URL?, URLResponse?, Error? ) -> Void ) -> URLSessionDownloadTask {
        
        let request = NSMutableURLRequest( url: url )
        request.setValue( mimeType, forHTTPHeaderField: httpHeaderAccept )
        
        let task = URLSession.shared.downloadTask( with: url, completionHandler: completionHandler )
        
        return task
    }
    
    func mimeTypeDataTaskWithURL( _ mimeType: String, url: URL, completionHandler: @escaping ( Data?, URLResponse?, Error? ) -> Void ) -> URLSessionDataTask {
        
        let request = NSMutableURLRequest( url: url )
        request.setValue( mimeType, forHTTPHeaderField: httpHeaderAccept )
        let task = URLSession.shared.dataTask( with: request as URLRequest, completionHandler: completionHandler )

        return task
    }

    func jsonDownloadTaskWithURL( _ url: URL, completionHandler: @escaping ( URL?, URLResponse?, Error? ) -> Void ) -> URLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( jsonMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func jsonDataTaskWithURL( _ url: URL, completionHandler: @escaping ( Data?, URLResponse?, Error? ) -> Void ) -> URLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( jsonMIMEType, url: url, completionHandler: completionHandler )
    }

    func xmlDownloadTaskWithURL( _ url: URL, completionHandler: @escaping ( URL?, URLResponse?, Error? ) -> Void ) -> URLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( xmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func xmlDataTaskWithURL( _ url: URL, completionHandler: @escaping ( Data?, URLResponse?, Error? ) -> Void ) -> URLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( xmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func htmlDownloadTaskWithURL( _ url: URL, completionHandler: @escaping ( URL?, URLResponse?, Error? ) -> Void ) -> URLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( htmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func htmlDataTaskWithURL( _ url: URL, completionHandler: @escaping ( Data?, URLResponse?, Error? ) -> Void ) -> URLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( htmlMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func pngDownloadTaskWithURL( _ url: URL, completionHandler: @escaping ( URL?, URLResponse?, Error? ) -> Void ) -> URLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( pngMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func pngDataTaskWithURL( _ url: URL, completionHandler: @escaping ( Data?, URLResponse?, Error? ) -> Void ) -> URLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( pngMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func jpgDownloadTaskWithURL( _ url: URL, completionHandler: @escaping ( URL?, URLResponse?, Error? ) -> Void ) -> URLSessionDownloadTask {
        
        return mimeTypeDownloadTaskWithURL( jpgMIMEType, url: url, completionHandler: completionHandler )
    }
    
    func jpgDataTaskWithURL( _ url: URL, completionHandler: @escaping ( Data?, URLResponse?, Error? ) -> Void ) -> URLSessionDataTask {
        
        return mimeTypeDataTaskWithURL( jpgMIMEType, url: url, completionHandler: completionHandler )
    }
    

}
