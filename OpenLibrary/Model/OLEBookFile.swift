//
//  OLEBookFile.swift
//  
//
//  Created by Bob Wakefield on 5/10/16.
//
//

import Foundation
import CoreData

//import BNRCoreDataStack

enum EBookTag: String {
    
    case tagUnknown      = "unknown"
    case tagfiles        = "files"
    case tagfile         = "file"
    case tagformat       = "format"
    case tagoriginal     = "original"
    case tagmd5          = "md5"
    case tagmtime        = "mtime"
    case tagsize         = "size"
    case tagcrc32        = "crc32"
    case tagsha1         = "sha1"
    case tagctime        = "ctime"
    case tagatime        = "atime"
    case tagoriginalName = "original-name"
}

enum EBookAttr: String {
    
    case attrname        = "name"
    case attrsource      = "source"
}

private struct ParsedResult {
    
    var name:         String = ""
    var source:       String = ""
    var format:       String = ""
    var original:     String = ""
    var md5:          String = ""
    var mtime:        String = ""
    var size:         String = ""
    var crc32:        String = ""
    var sha1:         String = ""
    var ctime:        String = ""
    var atime:        String = ""
    var originalName: String = ""
}

private class XMLParser: NSObject, XMLParserDelegate {
    
    var parser   = Foundation.XMLParser()
    var element: EBookTag = .tagUnknown
    
    var parsedResult = ParsedResult()
    var resultArray = [ParsedResult]()
    
    func beginParsing( _ stream: InputStream ) -> [ParsedResult] {
        
        parser = Foundation.XMLParser( stream: stream )
        parser.delegate = self
        parser.parse()
        
        if let error = parser.parserError {
            print( "line:\(parser.lineNumber) \(parser.columnNumber)\n\(error)" )
        }
        
        return resultArray
    }
    
    func beginParsing( urlString: String ) -> [ParsedResult] {
        if let url = URL( string: urlString ) {
            
            return beginParsing( localURL: url )
        }
        
        return resultArray
    }
    
    func beginParsing( localURL: URL ) -> [ParsedResult] {
        
        do {
            let xmlString = try String( contentsOf: localURL )
            
            return beginParsing( xmlString: xmlString )
        }
        catch {
            
        }

        return resultArray
    }
    
    func beginParsing( xmlString: String ) -> [ParsedResult] {
        
        if let data = xmlString.data( using: String.Encoding.utf8 ) {
            parser = Foundation.XMLParser( data: data )
            parser.delegate = self
            parser.parse()
            
            if let error = parser.parserError {
                print( "line:\(parser.lineNumber) \(parser.columnNumber)\n\(error)" )
            }
            
        }
        
        return resultArray
    }
    
    @nonobjc func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
                        namespaceURI: String?,
                        qualifiedName qName: String?,
                                      attributes attributeDict: [String : String]
        ) {
        
        if let startElement = EBookTag( rawValue: elementName ) {
            
            if startElement == .tagfile {
                
                parsedResult = ParsedResult()
                
                if let name   = attributeDict[EBookAttr.attrname.rawValue],
                    let source = attributeDict[EBookAttr.attrsource.rawValue] {
                    
                    parsedResult.name = name
                    parsedResult.source = source
                }
            }
            
            self.element = startElement
            
        } else {
            
            self.element = .tagUnknown
        }
    }
    
    @nonobjc func parser( _ parser: XMLParser, foundCharacters string: String )
    {
        switch element {
        case .tagUnknown:
            break
        case .tagfiles:
            break
        case .tagfile:
            break
        case .tagformat:
            parsedResult.format += string
        case .tagoriginal:
            parsedResult.original += string
        case .tagmd5:
            parsedResult.md5 += string
        case .tagmtime:
            parsedResult.mtime += string
        case .tagsize:
            parsedResult.size += string
        case .tagcrc32:
            parsedResult.crc32 += string
        case .tagsha1:
            parsedResult.sha1 += string
        case .tagctime:
            parsedResult.ctime += string
        case .tagatime:
            parsedResult.atime += string
        case .tagoriginalName:
            parsedResult.originalName += string
        }
    }
    
    @nonobjc func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
                      namespaceURI: String?,
                      qualifiedName qName: String?
        )
    {
        if let endElement = EBookTag( rawValue: elementName ) {
            
            if endElement == .tagfile {
                
                resultArray.append ( parsedResult )
                parsedResult = ParsedResult()
            }
            
        }
        
        element = .tagUnknown
    }
    
}

class OLEBookFile: OLManagedObject {

    // Insert code here to add functionality to your managed object subclass
    static let entityName = "EBookFile"

    fileprivate class func saveParsedResults( _ eBookKey: String, parsedResults:[ParsedResult], moc: NSManagedObjectContext ) -> Int {
        
        var count = 0
        
        let existingItem: OLEBookItem? = OLEBookItem.findObject( eBookKey, entityName: OLEBookItem.entityName, keyFieldName: "eBookKey", moc: moc )
        
        if let existingItem = existingItem {
            for result in parsedResults {
                
                if !result.name.isEmpty && !result.format.isEmpty && !result.source.isEmpty {

                    var newObject: OLEBookFile? = findObject( result.name, entityName: entityName, keyFieldName: "name", moc: moc )
                    
                    if nil == newObject {
                        newObject =
                            NSEntityDescription.insertNewObject(
                                forEntityName: OLEBookFile.entityName, into: moc
                                ) as? OLEBookFile
                    }
                    
                    if let newObject = newObject {
                        
                        newObject.retrieval_date = Date()
                        
                        newObject.eBookKey      = eBookKey
                        newObject.workKey       = existingItem.workKey
                        newObject.editionKey    = existingItem.editionKey
                        
                        newObject.name          = result.name
                        newObject.source        = result.source
                        newObject.format        = result.format
                        newObject.original      = result.original
                        newObject.md5           = result.md5
                        newObject.mtime         = result.mtime
                        newObject.size          = result.size
                        newObject.crc32         = result.crc32
                        newObject.sha1          = result.sha1
                        newObject.ctime         = result.ctime
                        newObject.atime         = result.atime
                        newObject.originalName  = result.originalName
                        
                        count += 1
                    }
                }
            }
        }
        
        return count
    }
    
    class func parseXML( _ eBookKey: String, localURL: URL, moc: NSManagedObjectContext ) -> Int {
        
        let xmlParser = XMLParser()
        let parsedResults = xmlParser.beginParsing( localURL: localURL )
        
        return saveParsedResults(
                eBookKey, parsedResults: parsedResults, moc: moc
            )
    }

    
}

extension OLEBookFile {
    
    class func buildFetchRequest() -> NSFetchRequest< OLEBookFile > {
        
        return NSFetchRequest( entityName: OLEBookFile.entityName )
    }
}
