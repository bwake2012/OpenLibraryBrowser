/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This file shows how to present an alert as part of an operation.
*/

import UIKit

import PSOperations

class AlertOperation: PSOperation {
    // MARK: Properties

    var title: String?
    var message: String?

    fileprivate var actions: [UIAlertAction] = []
    // MARK: Initialization
    
    init(presentationContext: UIViewController? = nil) {

        super.init()
        
        addCondition(AlertPresentation())
        
        /*
            This operation modifies the view controller hierarchy.
            Doing this while other such operations are executing can lead to
            inconsistencies in UIKit. So, let's make them mutally exclusive.
        */
        addCondition(MutuallyExclusive<UIViewController>())
    }
    
    func addAction(_ title: String, style: UIAlertAction.Style = .default, handler: @escaping (AlertOperation) -> Void = { _ in }) {

        let action = UIAlertAction(title: title, style: style) { [weak self] _ in

            guard let self = self else { return }

            handler(self)

            self.finish()
        }
        
        self.actions.append(action)
    }
    
    override func execute() {

        guard let presentationContext = UIApplication.topViewController()
        else {

            finish()

            return
        }

        DispatchQueue.main.async { [weak self] in

            guard let self = self else { return }

            if self.actions.isEmpty {
                self.addAction("OK")
            }

            let alertController =
                UIAlertController(
                        title: self.title,
                        message: self.message,
                        preferredStyle: .alert
                    )

            for action in self.actions {

                alertController.addAction(action)
            }
            
            presentationContext.present(
                alertController,
                animated: true,
                completion: self.presentationComplete
            )
        }
    }
    
    func presentationComplete() -> Void {
        
        finish()
    }
}
