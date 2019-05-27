//
//  UIViewController+Common.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2018 Jayesh Mardiya. All rights reserved.
//

import UIKit
import RxSwift

extension UIViewController {

    func showAlert(title: String? = "Oops!", message: String, actions: [UIAlertController.AlertAction] = [.cancel(title: "OK")]) -> Observable<Int> {
        return UIAlertController.present(in: self,
                                         title: title,
                                         message: message,
                                         style: .alert,
                                         actions: actions)
    }
}
