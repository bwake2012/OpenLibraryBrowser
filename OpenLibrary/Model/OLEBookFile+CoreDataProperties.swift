//
//  OLEBookFile+CoreDataProperties.swift
//  
//
//  Created by Bob Wakefield on 5/10/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension OLEBookFile {

    @NSManaged var workKey: String
    @NSManaged var editionKey: String
    @NSManaged var eBookKey: String
    @NSManaged var name: String
    @NSManaged var source: String
    @NSManaged var format: String
    @NSManaged var original: String
    @NSManaged var md5: String
    @NSManaged var mtime: String
    @NSManaged var size: String
    @NSManaged var crc32: String
    @NSManaged var sha1: String
    @NSManaged var ctime: String
    @NSManaged var atime: String
    @NSManaged var originalName: String

}
