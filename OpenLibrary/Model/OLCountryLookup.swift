//
//  OLCountryLookup.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 10/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

class OLCountryLookup {
    
    private var countryLookup: [String: String]?
    
    private func parse( json: [String: AnyObject] ) -> [String: String]? {
    
        guard let countries = json["countries"] as? [String: AnyObject] else {
            return nil
        }
    
        guard let country = countries["country"] as? [[String: AnyObject]] else {
            
            return nil
        }
        
        var countryLookup = [String: String]()
        
        for entry in country {
            
            if let code = entry["code"] as? String {
                
                if let name = entry["name"] as? [String: String] {
                    
                    if let nameText = name["__text"] {
                        
                        countryLookup[code] = nameText
                    }
                }
            }
        }
        
        return countryLookup.isEmpty ? nil : countryLookup
    }
    
    init?() {

        var scratchURL: NSURL?
        do {

            let dataFolder =
                try NSFileManager.defaultManager().URLForDirectory(
                            .ApplicationSupportDirectory,
                            inDomain: .UserDomainMask,
                            appropriateForURL: nil,
                            create: true
                        )
            scratchURL = dataFolder.URLByAppendingPathComponent( "countries.json", isDirectory: false )
        }
        catch let urlError as NSError {
            
            print( "\(urlError.debugDescription)" )
            return nil
        }
        
        guard let url = scratchURL else {
            return nil
        }
        guard let stream = NSInputStream( URL: url ) else {
            return nil
        }
        
        stream.open()
        
        defer {
            stream.close()
        }
        
        do {
            if let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? [String: AnyObject] {
                
                countryLookup = parse( json )
                if nil == countryLookup {
                    
                    return nil
                }
            }
            else {
                return nil
            }
        }
        catch let jsonError as NSError {
            
            print( "\(jsonError.debugDescription)" )
            return nil
        }
    }
}