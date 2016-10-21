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
            
            var nameText = ""
            if let name = entry["name"] as? [String: String] {
                
                nameText = name["__text"] ?? ""
            }
            if !nameText.isEmpty {
                
                if let code = entry["code"] as? String {
                    
                    countryLookup[code] = nameText

                } else if let codeArray = entry["code"] as? [AnyObject] {
                        
                    if let code = codeArray[0] as? String {
                        
                        countryLookup[code] = nameText
                    }
                }
            }
        }
        
        return countryLookup.isEmpty ? nil : countryLookup
    }
    
    init() {

        let mainBundle = NSBundle.mainBundle()
        guard let countriesPath = mainBundle.pathForResource( "countries", ofType: "json" ) else {
            
            fatalError( "OLCountryLookup could not retrieve countries.json" )
        }
        
        let url = NSURL.fileURLWithPath( countriesPath )
        guard let stream = NSInputStream( URL: url ) else {

            fatalError( "OLCountryLookup could not open \(url.absoluteString)" )
        }
        
        stream.open()
        
        defer {
            stream.close()
        }
        
        do {
            if let json = try NSJSONSerialization.JSONObjectWithStream(stream, options: []) as? [String: AnyObject] {
                
                countryLookup = parse( json )
                if nil == countryLookup {
                    
                    fatalError( "Could not parse countries.json")
                }
            }
            else {
                
                fatalError( "Could not serialize countries.json" )
            }
        }
        catch let jsonError as NSError {
            
            fatalError( "\(jsonError.debugDescription)" )
        }
    }
    
    func findName( forCode code: String ) -> String {
        
        guard let countryLookup = countryLookup else {
            
            assert( false )
            return "***** Country Lookup not initialized. *****"
        }
        
        if var name = countryLookup[code] {
            
            if 3 == code.characters.count {
                
                if let lastChar = code.characters.last {

                    switch String( lastChar ) {
                        
                        case "a":
                            name += ", Australia"
                        case "u":
                            name += ", USA"
                        case "k":
                            name += ", United Kingdom"
                        case "c":
                            name += ", Canada"
                        default:
                            break
                    }
                }
            }
            
            return name
        
        } else if let name = countryLookup[ "-" + code ] {
            
            return name
            
        } else {
            
            return "Name for code \"\(code)\" not found."
        }
    }
}