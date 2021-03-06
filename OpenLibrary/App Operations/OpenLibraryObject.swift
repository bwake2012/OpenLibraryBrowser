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
    // birth and death dates must be stored as strings

    // time stamps must be converted to NSDate
    // 2011-12-02T18:33:15.439307
    fileprivate static let timestampFormatter: DateFormatter = {
        
        let f = DateFormatter()
        f.locale = Locale( identifier: "en_US_POSIX" )
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        f.timeZone = TimeZone( abbreviation: "UTC" )
        
        return ( f )
    }()
    
    fileprivate static let altTimestampFormatter: DateFormatter = {
        
        let f = DateFormatter()
        f.locale = Locale( identifier: "en_US_POSIX" )
        f.dateFormat = "yyyy-MM-dd' 'HH:mm:ss.SSSSSS"
        f.timeZone = TimeZone( abbreviation: "UTC" )
        
        return ( f )
    }()
    
    static func OLDateStamp( _ dateStamp: AnyObject? ) -> String {
        
        guard let dateStamp = dateStamp as? String else { return "" }
        
        return dateStamp
    }
    
    static func OLTimeStamp( _ timeStamp: AnyObject? ) -> Date? {
        
        guard let timeStamp = timeStamp as? [String: String] , timeStamp["type"] == "/type/datetime" else {
            
            return nil
        }
        
        guard let timeStampString = timeStamp["value"] else { return nil }
        
        var timeStampVal = OpenLibraryObject.timestampFormatter.date( from: timeStampString )
        if nil == timeStampVal {
            
            timeStampVal = OpenLibraryObject.altTimestampFormatter.date( from: timeStampString )
        }
        
        return timeStampVal
    }
    
    static func OLLinks( _ match: [String: AnyObject] ) -> [[String: String]] {
        
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
    static func OLAuthorRole( _ match: AnyObject? ) -> [String] {
        
        var authors = [String]()
        // there is an array of dictionaries under ["authors"]
        if let match = match as? [[String: AnyObject]] {
            
            for author in match {
                
                // each dictionary has an entry under ["type"]
                var authorRole: String?

                // sometimes it's a string
                if let authorType = author["type"] as? String {
                    authorRole = authorType

                // sometimes it's a dictionary, with the value an entry under ["key"]
                } else if let authorType = author["type"] as? [String: String] {
                    authorRole = authorType["key"]
                }

                // The type value must be:
                if let authorRole = authorRole , authorRole == "/type/author_role" {
                    
                    // the author OLID will be in a dictionary under ["author"]
                    if let authorKey = author["author"] as? [String: String] {
                        
                        // with a value under ["key"]
                        if let key = authorKey["key"] {
                            
                            authors.append( key )
                        }
                    }
                }
            }
        }
        
        return authors
    }
    
    // returns array of keyed values
    static func OLKeyedValue( _ match: AnyObject?, key: String ) -> String {

        var valueString = ""
        if let keyedValue = match as? [String: String] {
            if let value = keyedValue[key] {
                
                valueString = value
            }
        }
        
        return valueString
    }
    
    // returns array of keyed values
    static func OLKeyedValueArray( _ match: AnyObject?, key: String ) -> [String] {
        
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
    
    static func OLTableOfContents( _ match: AnyObject? ) -> [[String: AnyObject]] {
        
        var toc = [[String: AnyObject]]()
        
        if let match = match as? [AnyObject] {
            
            for dict in match {
                
                if let dict = dict as? [String: AnyObject] {
                    
                    toc.append( dict )
                }
            }
            
            return toc
        }
        
        return toc
    }
    
    static func OLText( _ match: AnyObject? ) -> String {
        
        var text = ""
        if let match = match as? [String: AnyObject] {
            if let type = match["type"] as? String , type == "/type/text" {
                text = match["value"] as? String ?? ""
            }
        } else if let match = match as? String {
            
            text = match
        }

        return text
    }
    
    static func OLString( _ match: AnyObject? ) -> String {
        
        var string = ""
        if let aString = match as? String {
            
            string = aString
        }
        
        return string
    }
    
    static func OLInt( _ match: AnyObject? ) -> Int {
        
        var value = 0
        if let aValue = match as? Int {
            
            value = aValue
        }
        
        return value
    }
    
    static func OLBool( _ match: AnyObject? ) -> Bool {
        
        var value = false
        if let aValue = match as? Int {
            
            value = 0 != aValue

        } else if let aValue = match as? Bool {
            
            value = aValue
        }
        
        return value
    }
    
    static func OLStringArray( _ match: AnyObject? ) -> [String] {
        
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
    
    static func OLIntArray( _ match: AnyObject? ) -> [Int] {
        
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
    
    static func OLStringDictionaryArray( _ match: AnyObject? ) -> [[String: String]] {
        
        var stringDictArray = [[String:String]]()
        if let elements = match as? [AnyObject] {
            
            for element in elements {
                
                if let element = element as? [String: String] {
                    
                    stringDictArray.append( element )
                }
                
            }
        }
        
        return stringDictArray
    }
    

}
