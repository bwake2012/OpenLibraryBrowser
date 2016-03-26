//
//  OpenLibraryObject.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/9/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import Foundation

class OpenLibraryObject {
    
    // MARK: Static Properties
    // birth and death dates must be converted to NSDate
    private static let datestampFormatter: NSDateFormatter = {
        
        let f = NSDateFormatter()
        f.locale = NSLocale( localeIdentifier: "en_US_POSIX" )
        f.dateFormat = "dd' 'MMMM' 'yyyy"
        f.timeZone = NSTimeZone( abbreviation: "UTC" )
        
        return ( f )
    }()
    
    // time stamps must be converted to NSDate
    // 2011-12-02T18:33:15.439307
    private static let timestampFormatter: NSDateFormatter = {
        
        let f = NSDateFormatter()
        f.locale = NSLocale( localeIdentifier: "en_US_POSIX" )
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        f.timeZone = NSTimeZone( abbreviation: "UTC" )
        
        return ( f )
    }()
    
    static func OLDateStamp( dateStamp: AnyObject? ) -> NSDate? {
        
        guard let dateStamp = dateStamp as? String else { return nil }
        
        return OpenLibraryObject.datestampFormatter.dateFromString( dateStamp )
    }
    
    static func OLTimeStamp( timeStamp: AnyObject? ) -> NSDate? {
        
        guard let timeStamp = timeStamp as? [String: String] where timeStamp["type"] == "/type/datetime" else {
            
            return nil
        }
        
        guard let timeStampString = timeStamp["value"] else { return nil }
        
        return OpenLibraryObject.timestampFormatter.dateFromString( timeStampString )
    }
    
    static func OLLinks( match: [String: AnyObject] ) -> [[String: String]] {
        
        var links = [[String: String]]()
        if let linkArray = match["links"] as? [AnyObject] {
            
            for link in linkArray {
                
                if let link = link as? [String: AnyObject] {
                    
                    var newLink = [String: String]()
                    for item in link {
                        
                        // we know what type
                        if item.0 != "type" {
                            
                            newLink[item.0] = item.1 as? String
                        }
                    }
                    links.append( newLink )
                }
            }
        }

        return links
    }
    
    // returns array of author object keys
    static func OLAuthorRole( match: AnyObject? ) -> [String] {
        
        var authors = [String]()
        if let match = match as? [[String: AnyObject]] {
            
            for author in match {
                
                if let authorRole = author["type"] as? [String: String] {
                    if let type = authorRole["key"] where type == "/type/author_role" {
                        if let authorKey = author["author"] as? [String: String] {
                            
                            if let key = authorKey["key"] {
                                
                                authors.append( key )
                            }
                        }
                    }
                }
            }
        }
        
        return authors
    }
    
    // returns array of keyed values
    static func OLKeyedValue( match: AnyObject?, key: String ) -> String {

        var valueString = ""
        if let keyedValue = match as? [String: String] {
            if let value = keyedValue[key] {
                
                valueString = value
            }
        }
        
        return valueString
    }
    
    // returns array of keyed values
    static func OLKeyedValueArray( match: AnyObject?, key: String ) -> [String] {
        
        var valueArray = [String]()
        if let match = match as? [[String: AnyObject]] {
            
            for keyedValue in match {
                
                if let keyedValue = keyedValue as? [String: String] {
                    if let value = keyedValue[key] {
                        
                            valueArray.append( value )
                    }
                }
            }
        }
        
        return valueArray
    }
    
    static func OLStringStringDictionaryArray( match: AnyObject? ) -> [[String: String]] {
        
        var arrayOfDictionaries = [[String: String]]()
        
        if let match = match as? [AnyObject] {
            
            for dict in match {
                
                if let dict = dict as? [String: String] {
                    
                    arrayOfDictionaries.append( dict )
                }
            }
        }
        
        return arrayOfDictionaries
    }
    
    static func OLText( match: AnyObject? ) -> String {
        
        var text = ""
        if let match = match as? [String: AnyObject] {
            if let type = match["type"] as? String where type == "/type/text" {
                text = match["value"] as? String ?? ""
            }
        }

        return text
    }
    
    static func OLString( match: AnyObject? ) -> String {
        
        var string = ""
        if let aString = match as? String {
            
            string = aString
        }
        
        return string
    }
    
    static func OLInt( match: AnyObject? ) -> Int {
        
        var value = 0
        if let aValue = match as? Int {
            
            value = aValue
        }
        
        return value
    }
    
    static func OLBool( match: AnyObject? ) -> Bool {
        
        var value = false
        if let aValue = match as? Int {
            
            value = 0 != aValue

        } else if let aValue = match as? Bool {
            
            value = aValue
        }
        
        return value
    }
    
    static func OLStringArray( match: AnyObject? ) -> [String] {
        
        var stringArray = [String]()
        if let strings = match as? [AnyObject] {
            
            for string in strings {
                
                if let string = string as? String {
                    
                    stringArray.append( string )
                }
            }
        }
        
        return stringArray
    }
    
    static func OLIntArray( match: AnyObject? ) -> [Int] {
        
        var intArray = [Int]()
        if let matchedInts = match as? [AnyObject] {
            
            for aMatchedInt in matchedInts {
                
                if let anInt = aMatchedInt as? Int {
                    
                    intArray.append( anInt )
                }
            }
        }
        
        return intArray
    }
}