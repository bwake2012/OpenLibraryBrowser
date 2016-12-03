# OpenLibraryBrowser

This is a mobile front end for the OpenLibrary book database. It's a universal app, but the interface is not optimized for the iPad. It sends JSON queries and stores the results locally in Core Data.

It leans heavily on the NSOperation based classes originally developed by Apple for their WWDC app and published with their WWDC 2015 sample Advanced NSOperations, as adapted by Pluralsight in their version named [PSOperations](https://github.com/pluralsight/PSOperations).

It builds its Core Data stack with the [Big Nerd Ranch Core Data stack](https://github.com/bignerdranch/CoreDataStack). 

It converts markdown text directly into NSAttributedText with [Down](https://github.com/iwasrobbed/Down) by Rob Phillips.