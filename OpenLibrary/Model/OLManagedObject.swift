//
//  OLManagedObject.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

import BNRCoreDataStack

typealias ObjectResultClosure = ( objectID: NSManagedObjectID ) -> Void

typealias ImageDisplayClosure = ( localURL: NSURL ) -> Bool

enum HasPhoto: Int {
    case unknown = -1
    case none = 0
    case local = 1
    case olid = 2
    case id = 3
    case authorDetail = 4
    
    func label() -> String {
        
        switch( self ) {
        case .unknown:
            return( "unknown" )
        case .none:
            return( "none" )
        case .local:
            return( "local" )
        case .olid:
            return( "olid" )
        case .id:
            return( "id" )
        case .authorDetail:
            return( "author detail" )
        }
    }
}

enum FullText: Int {
    
    case unknown = -1
    case none = 0
    case available = 1

    func label() -> String {
        
        switch( self ) {
        case .unknown:
            return( "unknown" )
        case .none:
            return( "none" )
        case .available:
            return( "available" )
        }
    }
}

enum DeluxeDetail: String {
    
    case unknown     = "unknown"
    case inline      = "DeluxeDetailInlineTableViewCell"
    case block       = "DeluxeDetailBlockTableViewCell"
    case link        = "DeluxeDetailLinkTableViewCell"
    case heading     = "DeluxeDetailHeadingTableViewCell"
    case subheading  = "DeluxeDetailSubheadingTableViewCell"
    case body        = "DeluxeDetailBodyTableViewCell"
    case imageAuthor = "DeluxeDetailImageAuthorTableViewCell"
    case imageBook   = "DeluxeDetailImageBookTableViewCell"
    case html        = "DeluxeDetailHTMLTableViewCell"
}

struct DeluxeData {
    
    let type: DeluxeDetail
    let caption: String
    let value: String
    let extraValue: String
    
    init( type: DeluxeDetail, caption: String, value: String, extraValue: String ) {
        
        self.type = type
        self.caption = caption
        self.value = value
        self.extraValue = extraValue
    }

    init( type: DeluxeDetail, caption: String, value: String ) {
        
        self.type = type
        self.caption = caption
        self.value = value
        self.extraValue = ""
    }
}


class OLManagedObject: NSManagedObject {
    
    var heading: String {
        
        return ""
    }
    
    var subheading: String {
        
        return ""
    }
    
    var defaultImageName: String {
        
        return "961-book-32.png"
    }

    var deluxeData: [[DeluxeData]] {
        
        let data = self.buildDeluxeData()
        
        return data
    }
    
    var isProvisional: Bool {
        
        return false
    }
    
    lazy var hasDeluxeData: Bool = {
        
        return 1 < self.deluxeData.count || ( 1 == self.deluxeData.count && 1 < self.deluxeData[0].count )
    }()
    
    class func findObject<T: OLManagedObject>( key: String, entityName: String, keyFieldName: String = "key", moc: NSManagedObjectContext ) -> [T]? {
        
        let fetchRequest = NSFetchRequest( entityName: entityName )
        
        fetchRequest.predicate = NSPredicate( format: "\(keyFieldName)==%@", "\(key)" )
        
        fetchRequest.sortDescriptors =
            [NSSortDescriptor(key: "retrieval_date", ascending: false)]
        
        var results = [T]?()
        do {
            results = try moc.executeFetchRequest( fetchRequest ) as? [T]
        }
        catch {
            
            return nil
        }
        
//        print( "findObject: key:\(key) entity:\(entityName) keyFieldName:\(keyFieldName) moc:\(moc.name ?? "")" )
        
        return results
    }
    
    class func findObject<T: OLManagedObject>( key: String, entityName: String, keyFieldName: String = "key", moc: NSManagedObjectContext ) -> T? {
        
        let results: [T]? = findObject( key, entityName: entityName, keyFieldName: keyFieldName, moc: moc )
        
        if "key" == keyFieldName {
            
            let count = results?.count
            assert( 1 >= count )
        }
        
        return results?.first
    }
    //
    
    var hasImage: Bool { return true }
    var firstImageID: Int { return 0 }
    
    var imageType: String { return "" }
    
    private static var cacheMarkdown: Markdown?
    var fancyMarkdown: Markdown {
        
        get {
            if nil == OLWorkDetail.cacheMarkdown {
                
                var options = MarkdownOptions()
                options.autoHyperlink = false
                options.autoNewlines = true
                options.emptyElementSuffix = ">"
                options.encodeProblemUrlCharacters = true
                options.linkEmails = false
                options.strictBoldItalic = true
                
                OLWorkDetail.cacheMarkdown = Markdown( options: options )
            }
            
            return OLWorkDetail.cacheMarkdown!
        }
        
        set {
            
            OLWorkDetail.cacheMarkdown = newValue
        }
    }
    
    func localURL( key:String, size: String, index: Int = 0 ) -> NSURL {
        
        let docFolder = try! NSFileManager.defaultManager().URLForDirectory( .DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false )
        
        let imagesFolder = docFolder.URLByAppendingPathComponent( "images" )
        
        let parts = key.componentsSeparatedByString( "/" )
        let goodParts = parts.filter { (x) -> Bool in !x.isEmpty }
        
        let imagesSubFolder = imagesFolder.URLByAppendingPathComponent( goodParts[0] )
        
        var fileName = "\(goodParts[1])-\(size)"
        if 0 < index {
            fileName += "\(index)"
        }
        fileName += ".jpg"
        let url = imagesSubFolder.URLByAppendingPathComponent( fileName )
        
        return url
    }
    
    func imageID( index: Int ) -> Int {
        
        return 0
    }
    
    func localURL( size: String, index: Int = 0 ) -> NSURL {
        
        return NSURL()
    }
    
    func populateObject( parsed: OpenLibraryObject ) {
    }
    
    func buildDeluxeData() -> [[DeluxeData]] {
        
        let deluxeData = [[DeluxeData]]()

        return deluxeData
    }
}


