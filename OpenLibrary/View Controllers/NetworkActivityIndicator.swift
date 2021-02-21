//
//  NetworkActivityIndicator.swift
//  OpenLibrary
//
//  Created by Bob Wakefield on 2/21/21.
//  Copyright © 2021 Bob Wakefield. All rights reserved.
//

import UIKit

protocol NetworkActivityIndicator {

    var activityView: UIActivityIndicatorView! { get set }

    func coordinatorIsBusy() -> Void
    func coordinatorIsNoLongerBusy() -> Void
}

extension NetworkActivityIndicator {

    // MARK: query in progress

    func coordinatorIsBusy() -> Void {

        assert(nil != activityView)

        activityView?.startAnimating()
    }

    func coordinatorIsNoLongerBusy() -> Void {

        assert(nil != activityView)

        activityView?.stopAnimating()
    }

}
