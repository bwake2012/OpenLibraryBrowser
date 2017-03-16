//
//  LoginPostOperation.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 12/11/16.
//  Copyright © 2016 Bob Wakefield. All rights reserved.
//

import PSOperations

class LoginPostOperation: PSOperations.GroupOperation {

    // MARK: Properties
    
    let userName = ""
    let passWord = ""
    init() {
        
        super.init( operations: [] )
        
        // declare parameter as a dictionary which contains string as key and value combination.
        let parameters = ["username": userName, "password": passWord]
        
        let url: URL = URL( string: "https://openlibrary.org/account/login" )!
        
        var request = URLRequest( url: url )
        request.httpMethod = "POST"

        do {
            // pass dictionary to nsdata object and set it as request body
            request.httpBody = try JSONSerialization.data( withJSONObject: parameters, options: .prettyPrinted )
            
        } catch let error {
            
            print( error.localizedDescription )
        }

        request.setValue( "application/json", forHTTPHeaderField: "Content-Type" )
        request.setValue( "*/*", forHTTPHeaderField: "Accept" )
        
        let task = URLSession.shared.dataTask( with: request, completionHandler: downloadFinished )
        
        let taskOperation = URLSessionTaskOperation( task: task )
        
        let reachabilityCondition = ReachabilityCondition( host: url )
        taskOperation.addCondition( reachabilityCondition )
        
        let networkObserver = NetworkObserver()
        taskOperation.addObserver( networkObserver )
        
        addOperation(taskOperation)
    }
    
    func downloadFinished( data: Data?, response: URLResponse?, error: Error? ) {
        
        if let error = error {
            
            dump( error )
        }
        
        if let response = response {
            
            dump( response )
        }
        
    }
}
