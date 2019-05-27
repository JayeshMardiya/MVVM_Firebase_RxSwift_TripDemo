//
//  SignInViewModel.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 25/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import GoogleSignIn

class SignInViewModel {
    
    let processingDrv: Driver<Bool>
    let googleSignedInDrv: Driver<User?>
    let errResponseDrv: Driver<String>
    
    init(withGoogleSignInOnTap googleSignInOnTap: Driver<Void>) {
        
        let errRespSubject = PublishSubject<String>()
        let activityIndicator = ActivityIndicator()
        
        processingDrv = activityIndicator.asDriver()
        errResponseDrv = errRespSubject.asDriver(onErrorDriveWith: Driver.never())
        
        googleSignedInDrv = googleSignInOnTap
            .asObservable()
            .map {
                GIDSignIn.sharedInstance().signIn()
            }
            .flatMap({ _ -> Observable<AuthCredential?> in
                return TripService.signInViaGoogle()
                    .map({ (response) -> AuthCredential? in
                        switch response {
                        case .success(let resp):
                            return resp
                        case .fail(let err):
                            let codes: [GIDSignInErrorCode] = [.canceled, .noSignInHandlersInstalled]
                            errRespSubject.onNext(err.description)
                            return nil
                        }
                    })
                    .trackActivity(activityIndicator)
            })
            .skipWhile { $0 == nil }
            .flatMap({ (credential) -> Observable<User?> in
                guard let cred = credential else {
                    return Observable.just(nil)
                }
                return TripService.signIn(withCredential: cred)
                    .map({ (response) -> User? in
                        switch response {
                        case .success(let resp):
                            return resp
                        case .fail(let err):
                            errRespSubject.onNext(err.description)
                            return nil
                        }
                    })
                    .trackActivity(activityIndicator)
            })
            .asDriver(onErrorJustReturn: nil)
    }
}
