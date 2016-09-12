//  ImageDownloadOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/2/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//
//  Modified from code in the Apple sample app Earthquakes in the Advanced NSOperations project

import Foundation
import ImageIO

import PSOperations

class ImageDownloadOperation: GroupOperation {
    
    // MARK: Properties
    let localImageURL: NSURL
    let remoteImageURL: NSURL
    
    let displaySize: CGSize?

    // MARK: Initialization
    
    /// - parameter cacheFile: The file `NSURL` to which the earthquake feed will be downloaded.
    init( stringID: String, imageKeyName: String, size: String, type: String, imageURL: NSURL, displaySize: CGSize? ) {

        self.localImageURL = imageURL
        self.displaySize = displaySize

        /*
            If this server is out of our control and does not offer a secure
            communication channel, use the http version of the URL and add
            the domain to the "NSExceptionDomains" value in the
            app's Info.plist file. When you communicate with your own servers,
            or when the services you use offer secure communication options, you
            should always prefer to use https.
        */
        let urlString = "https://covers.openlibrary.org/\(type)/\(imageKeyName)/\(stringID)-\(size).jpg?default=false"
        remoteImageURL = NSURL( string: urlString )!

        super.init(operations: [])
        name = "Download Image"
        
        let task = NSURLSession.sharedSession().jpgDownloadTaskWithURL( remoteImageURL ) {
            
            url, response, error in
            
            self.downloadFinished( url, response: response as? NSHTTPURLResponse, error: error)
        }
        
        let taskOperation = URLSessionTaskOperation(task: task)
        
        let reachabilityCondition = ReachabilityCondition(host: remoteImageURL)
        taskOperation.addCondition(reachabilityCondition)

        let networkObserver = NetworkObserver()
        taskOperation.addObserver(networkObserver)
        
        addOperation(taskOperation)
    }
    
    func downloadFinished( url: NSURL?, response: NSHTTPURLResponse?, error: NSError? ) {
        
        if let error = error {

            aggregateError( error )

        } else if let downloadURL = url {
            
            do {
                /*
                    If we already have a file at this location, just delete it.
                    Also, swallow the error, because we don't really care about it.
                */
                try NSFileManager.defaultManager().removeItemAtURL( self.localImageURL )
            }
            catch {}
            
            if let directoryURL = self.localImageURL.URLByDeletingLastPathComponent {

                do {
                    try NSFileManager.defaultManager().createDirectoryAtURL( directoryURL, withIntermediateDirectories: true, attributes: nil )
                }
                catch let error as NSError {
                    print( "\(error)" )
                }
            }

            if let error = validateStreamMIMEType( [jpegMIMEType,jpgMIMEType], response: response, url: localImageURL ) {
                
                var userInfo = error.userInfo

                userInfo[hostURLKey] = remoteImageURL.absoluteString
                
                aggregateError( NSError( domain: error.domain, code: error.code, userInfo: userInfo ) )

            } else {
                
                if nil == displaySize {
                
                    do {
                        
                        try NSFileManager.defaultManager().moveItemAtURL( downloadURL, toURL: localImageURL )
                    }
                    catch let error as NSError {
                        aggregateError(error)
                    }

                } else if let displaySize = displaySize {
                    
                    let options: [NSString: NSObject] = [
                        kCGImageSourceThumbnailMaxPixelSize: max(displaySize.width, displaySize.height),
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceTypeIdentifierHint: "public.jpeg"
                    ]
                    if let imageSource = CGImageSourceCreateWithURL( downloadURL, options ) {
                        
                        if let scaledImage = CGImageSourceCreateThumbnailAtIndex( imageSource, 0, options ) {
                        
                            if let imageDest = CGImageDestinationCreateWithURL( self.localImageURL, "public.jpeg", 1, nil ) {
                                
                                let options: [NSString: NSObject] = [kCGImageDestinationLossyCompressionQuality: 1.0]
                                
                                CGImageDestinationAddImage( imageDest, scaledImage, options )
                                CGImageDestinationFinalize( imageDest )
                            }
                        }
                    }
                }
            }
            
            
        }
        else {
            // Do nothing, and the operation will automatically finish.
        }
    }
    
//    - (void) writeCGImage: (CGImageRef) image toURL: (NSURL*) url withType: (CFStringRef) imageType andOptions: (CFDictionaryRef) options
//    {
//    CGImageDestinationRef myImageDest = CGImageDestinationCreateWithURL((CFURLRef)url, imageType, 1, nil);
//    CGImageDestinationAddImage(myImageDest, image, options);
//    CGImageDestinationFinalize(myImageDest);
//    CFRelease(myImageDest);
//    }
    
    private func writeCGImage( image: CGImageRef, toURL: NSURL, imageType: String, options: [NSString: NSObject] ) -> Void {
        
        if let myImageDest = CGImageDestinationCreateWithURL( toURL, imageType, 1, nil ) {
            
            CGImageDestinationAddImage( myImageDest, image, options )
            CGImageDestinationFinalize( myImageDest )
        }
    }
    
}
