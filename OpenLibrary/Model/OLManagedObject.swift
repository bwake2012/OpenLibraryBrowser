//
//  OLManagedObject.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 3/19/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import CoreData

//import BNRCoreDataStack
import Down

typealias ObjectResultClosure = ( _ objectID: NSManagedObjectID ) -> Void

typealias ImageDisplayClosure = ( _ localURL: URL ) -> Bool

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

enum DeluxeDetail: Int {
    
    case unknown                = 0
    case inline                 = 1
    case block                  = 2
    case link                   = 3
    case heading                = 4
    case subheading             = 5
    case body                   = 6
    case imageAuthor            = 7
    case imageBook              = 8
    case html                   = 9
    case downloadBook           = 10
    case borrowBook             = 11
    case buyBook                = 12
    
    var captionNotDisplayed: Bool {
        
        return self == .imageAuthor || self == .imageBook || self == .link
    }
    
    var captionIsDisplayed: Bool {
        
        return self != .imageAuthor && self != .imageBook && self != .link
    }
    
    var reuseIdentifier: String {
        
        switch self {
        
        case .unknown:
            return "unknown"
        case .inline:
            return DeluxeDetailInlineTableViewCell.nameOfClass
        case .block:
            return DeluxeDetailBlockTableViewCell.nameOfClass
        case .link:
            return DeluxeDetailLinkTableViewCell.nameOfClass
        case .heading:
            return DeluxeDetailHeadingTableViewCell.nameOfClass
        case .subheading:
            return DeluxeDetailSubheadingTableViewCell.nameOfClass
        case .body:
            return DeluxeDetailBodyTableViewCell.nameOfClass
        case .imageAuthor:
            return DeluxeDetailImageTableViewCell.nameOfClass
        case .imageBook:
            return DeluxeDetailImageTableViewCell.nameOfClass
        case .html:
            return DeluxeDetailHTMLTableViewCell.nameOfClass
        case .downloadBook:
            return DeluxeDetailBookDownloadTableViewCell.nameOfClass
        case .borrowBook:
            return DeluxeDetailBookDownloadTableViewCell.nameOfClass
        case .buyBook:
            return DeluxeDetailBookDownloadTableViewCell.nameOfClass
        }
    }
}

struct DeluxeData {
    
    let type: DeluxeDetail
    let caption: String
    let value: String
    let extraValue: String
    let attributedValue: NSAttributedString
    
    init( type: DeluxeDetail, caption: String, value: String, extraValue: String ) {
        
        self.type = type
        self.caption = type.captionIsDisplayed ? NSLocalizedString( caption, comment: "" ) : caption
        self.value = value
        self.extraValue = extraValue
        self.attributedValue = NSAttributedString( string: "" )
    }

    init( type: DeluxeDetail, caption: String, value: String ) {
        
        self.type = type
        self.caption = type.captionIsDisplayed ? NSLocalizedString( caption, comment: "" ) : caption
        self.value = value
        self.extraValue = ""
        self.attributedValue = NSAttributedString( string: "" )
    }

    init( type: DeluxeDetail, caption: String, value: NSAttributedString ) {
        
        self.type = type
        self.caption = type.captionIsDisplayed ? NSLocalizedString( caption, comment: "" ) : caption
        self.value = ""
        self.extraValue = ""
        self.attributedValue = value
    }
}

class OLManagedObject: NSManagedObject {
    
    fileprivate static var countryLookup = OLCountryLookup()
    
    fileprivate static var languageLookup = [String: String]()
    
    fileprivate static var authorCache = NSCache< NSString, NSString >()
    
    func findLanguage( forKey key: String ) -> String? {
        
        return OLManagedObject.languageLookup[key]
    }
    
    func findCountryName( forCode code: String ) -> String {
        
        return OLManagedObject.countryLookup.findName( forCode: code )
    }
    
    func cachedAuthor( _ authorKey: String ) -> String? {
        
        if let name = OLManagedObject.authorCache.object( forKey: authorKey as NSString ) as? String {
            
            return name
            
        } else if let moc = managedObjectContext {
            
            let author: OLAuthorDetail? = OLManagedObject.findObject( authorKey, entityName: OLAuthorDetail.entityName, moc: moc )
            
            if let author = author {
                
                OLManagedObject.authorCache.setObject( author.name as NSString, forKey: authorKey as NSString )
                return author.name
            }
        }
        
        return nil
    }

    class func addAuthorToCache( _ authorKey: String, authorName: String ) -> Void {
        
        OLManagedObject.authorCache.setObject( authorName as NSString, forKey: authorKey as NSString )
    }
    
    func addAuthorToCache( _ authorKey: String, authorName: String ) -> Void {
        
        OLManagedObject.addAuthorToCache( authorKey, authorName: authorName )
    }
    
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
        
        get {

            return self.buildDeluxeData()
        }
    }
    
    var isProvisional: Bool {
        
        return false
    }
    
    var hasDeluxeData: Bool {
        
        return true
    }
    
    class func saveLoadedLanguages( _ loadedLanguages: [String: String] ) {
        
        OLManagedObject.languageLookup = loadedLanguages
    }
    
    class func findObject<T: OLManagedObject>( _ key: String, entityName: String, keyFieldName: String = "key", moc: NSManagedObjectContext ) -> [T]? {
        
        let fetchRequest = NSFetchRequest< T >( entityName: entityName )
        
        fetchRequest.predicate = NSPredicate( format: "\(keyFieldName)==%@", key )
        
        fetchRequest.sortDescriptors =
            [NSSortDescriptor(key: "retrieval_date", ascending: false)]
        fetchRequest.fetchBatchSize = 100
        
        var results: [T] = []
        do {
            results = try moc.fetch( fetchRequest )
        }
        catch {
            
            return nil
        }
        
        return results
    }
    
    class func findObject<T: OLManagedObject>( _ key: String, entityName: String, keyFieldName: String = "key", moc: NSManagedObjectContext ) -> T? {
        
        let results: [T]? = findObject( key, entityName: entityName, keyFieldName: keyFieldName, moc: moc )
        
        if let results = results {

            if "key" == keyFieldName {
                
                let count = results.count
                assert( 1 >= count )
            }
        }
        
        return results?.first
    }
    //
    
    var hasImage: Bool { return true }
    var firstImageID: Int { return 0 }
    
    var imageType: String { return "" }

//    fileprivate static var cacheMarkdown: Markdown?
//    var fancyMarkdown: Markdown {
//        
//        get {
//            if nil == OLWorkDetail.cacheMarkdown {
//                
//                var options = MarkdownOptions()
//                options.autoHyperlink = false
//                options.autoNewlines = true
//                options.emptyElementSuffix = ">"
//                options.encodeProblemUrlCharacters = true
//                options.linkEmails = false
//                options.strictBoldItalic = true
//                
//                OLWorkDetail.cacheMarkdown = Markdown( options: options )
//            }
//            
//            return OLWorkDetail.cacheMarkdown!
//        }
//        
//        set {
//            
//            OLWorkDetail.cacheMarkdown = newValue
//        }
//    }
    
//    func convertMarkdownToHTML( markdown: String ) -> String {
//        
//        let down = Down( markdownString: markdown )
//        
//        let html = try? down.toHTML( DownOptions.ValidateUTF8 )
//        
//        return html ?? ""
//    }
    
    func convertMarkdownToAttributedString( markdown: String ) -> NSAttributedString {
        
        let down = Down( markdownString: markdown )
        
        var attributedString: NSAttributedString?
            
        do {
            attributedString = try down.toAttributedString( DownOptions.ValidateUTF8 )
        }
        catch {}
        
        return attributedString ?? NSAttributedString( string: "" )
    }
    
    func localURL( _ imageID:Int, size: String ) -> URL {
        
        let docFolder = try! FileManager.default.url( for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false )
        
        let imagesFolder = docFolder.appendingPathComponent( "images" )
        
        let imageIDString = String( imageID )
       
        var fileName = "\(imageIDString)-\(size)"
        fileName += ".jpg"
        let url = imagesFolder.appendingPathComponent( fileName )
        
        return url
    }
    
    func imageID( _ index: Int ) -> Int {
        
        return 0
    }
    
    func localURL( _ size: String, index: Int = 0 ) -> URL {
        
        return URL( fileURLWithPath: "" )
    }
    
    func populateObject( _ parsed: OpenLibraryObject ) {
    }
    
    func buildDeluxeData() -> [[DeluxeData]] {
        
        let deluxeData = [[DeluxeData]]()

        return deluxeData
    }
    
}

extension OLManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OLManagedObject> {
        return NSFetchRequest<OLManagedObject>( entityName: "ManagedObject" )
    }
}

