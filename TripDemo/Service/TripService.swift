//
//  TripService.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase
import GoogleSignIn

class TripService {
    
    enum Response<E> {
        case success(resp: E)
        case fail(err: String)
    }
    
    enum Err: Error {
        case empty
        case unauthenticated
        case auth(code: AuthErrorCode, msg: String)
        case gAuth(code: GIDSignInErrorCode, msg: String)
        case storage(code: StorageErrorCode, msg: String)
        case service(msg: String)
        
        var description: String {
            switch self {
            case .empty:                return "Please enter something"
            case .unauthenticated:      return "Invalid user"
            case let .auth(_, msg):     return msg
            case let .gAuth(_, msg):    return msg
            case let .storage(_, msg):  return msg
            case let .service(msg):     return msg
            }
        }
    }
    
    typealias Record = (timestamp: String, trip_name: String, trip_type: String, startDate: String, endDate: String)
}

extension Reactive where Base: Auth {
    
    func authStateDidChange() -> Observable<(Auth, User?)> {
        
        return Observable.create({ (observer: AnyObserver<(Auth, User?)>) -> Disposable in
            let listener = self.base.addStateDidChangeListener({ (auth, user) in
                observer.onNext((auth, user))
            })
            return Disposables.create(with: {
                self.base.removeStateDidChangeListener(listener)
            })
        })
    }
    
    func createUser(email: String, password: String) -> Observable<User?> {
        
        return Observable.create({ (observer: AnyObserver<(User?)>) -> Disposable in
            self.base.createUser(withEmail: email, password: password, completion: { (authResult, error) in
                if let err = error {
                    observer.onError(err)
                } else  {
                    observer.onNext(authResult?.user)
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        })
    }
    
    func signIn(email: String, password: String) -> Observable<User?> {
        
        return Observable.create({ (observer: AnyObserver<(User?)>) -> Disposable in
            self.base.signIn(withEmail: email, password: password, completion: { (authResult, error) in
                if let err = error {
                    observer.onError(err)
                } else  {
                    observer.onNext(authResult?.user)
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        })
    }
    
    func signIn(credential: AuthCredential) -> Observable<User?> {
        
        return Observable.create({ (observer: AnyObserver<(User?)>) -> Disposable in
            self.base.signInAndRetrieveData(with: credential, completion: { (authResult, error) in
                if let err = error {
                    observer.onError(err)
                } else  {
                    observer.onNext(authResult?.user)
                    observer.onCompleted()
                }
            })
            return Disposables.create()
        })
    }
    
    func signInForData(credential: AuthCredential) -> Observable<AuthDataResult?> {
        
        return Observable.create({ (observer: AnyObserver<AuthDataResult?>) -> Disposable in
            self.base.signInAndRetrieveData(with: credential) { (data, error) in
                if let err = error {
                    observer.onError(err)
                } else {
                    observer.onNext(data)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        })
    }
    
    func signOut() -> Observable<Void> {
        
        return Observable.create({ (observer: AnyObserver<Void>) -> Disposable in
            do {
                try self.base.signOut()
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        })
    }
}

// MARK: - BMI Record Operations
extension TripService {
    
    static func authStateChanged() -> Observable<Response<User?>> {
        
        return Auth.auth().rx
            .authStateDidChange()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (authResult) -> Response<User?> in
                return .success(resp: authResult.1)
            })
            .catchError({ (error) -> Observable<Response<User?>> in
                return Observable.just(.fail(err: "Error"))
            })
    }
    
    static func signInViaGoogle() -> Observable<Response<AuthCredential?>> {
        
        return GIDSignIn.sharedInstance().rx.didSignIn
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (result) -> Response<AuthCredential?> in
                if result.error != nil {
                    return .fail(err: "Error")
                }
                guard let authentication = result.user.authentication,
                    let idToken = authentication.idToken,
                    let accessToken = authentication.accessToken else {
                        return .fail(err: "Error")
                }
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                return .success(resp: credential)
            })
            .take(1)
    }
    
    static func signIn(withCredential cred: AuthCredential) -> Observable<Response<User?>> {
        
        return Auth.auth().rx
            .signIn(credential: cred)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (user) -> Response<User?> in
                guard let user = user else { return .fail(err: "Error") }
                return .success(resp: user)
            })
            .catchError({ (error) -> Observable<Response<User?>> in
                return Observable.just(.fail(err: "Error"))
            })
    }
    
    static func signIn(withEmail email: String, password: String) -> Observable<Response<User?>> {
        
        return Auth.auth().rx
            .signIn(email: email, password: password)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (user) -> Response<User?> in
                guard let user = user else { return .fail(err: "Error") }
                return .success(resp: user)
            })
            .catchError({ (error) -> Observable<Response<User?>> in
                return Observable.just(.fail(err: "Error"))
            })
    }
    
    static func createUser(withEmail email: String, password: String) -> Observable<Response<User?>> {
        
        return Auth.auth().rx
            .createUser(email: email, password: password)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (user) -> Response<User?> in
                guard let user = user else { return .fail(err: "Error") }
                return .success(resp: user)
            })
            .catchError({ (error) -> Observable<Response<User?>> in
                return Observable.just(.fail(err: "Error"))
            })
    }
    
    static func fetchRecords() -> Observable<Response<[Record]>> {
        
        return Database.database().reference().child("trips")
            .queryOrderedByKey()
            .rx
            .observeEvent(.value)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (snapshot) -> Response<[Record]> in
                let records =  snapshot.children
                    .reversed()
                    .map({ (child) -> Record in
                        let childSnapshot = child as! DataSnapshot
                        let entries = childSnapshot.value as! [String: String]
                        return (childSnapshot.key,
                                entries["trip_name"] ?? "",
                                entries["trip_type"] ?? "",
                                entries["startDate"] ?? "",
                                entries["endDate"] ?? "")
                    })
                return .success(resp: records)
            })
            .catchError({ (error) -> Observable<Response<[Record]>> in
                return Observable.just(.fail(err: "Error"))
            })
    }
    
    static func createRecord(trip_name: String, trip_type: String, startDate: String, endDate: String) -> Observable<Response<Void>> {
        
        let userRecordRef = Database.database().reference().child("trips")
        let timestamp = String(format: "%.0f", Date().timeIntervalSince1970 * 1000)
        return userRecordRef
            .child(timestamp)
            .rx
            .setValue(["trip_name": trip_name, "trip_type": trip_type, "startDate": startDate, "endDate": endDate])
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (ref) -> Response<Void> in
                return .success(resp: ())
            })
            .catchError({ (error) -> Observable<TripService.Response<Void>> in
                return Observable.just(.fail(err: "Error"))
            })
    }
    
    static func deleteRecord(_ timestamp: String) -> Observable<Response<Void>> {
        
        guard let user = Auth.auth().currentUser else {
            return Observable.just(.fail(err: "Error"))
        }
        let userRecordRef = Database.database().reference().child("trips")
        return userRecordRef
            .child(timestamp)
            .rx
            .removeValue()
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .utility))
            .map({ (ref) -> Response<Void> in
                return .success(resp: ())
            })
            .catchError({ (error) -> Observable<TripService.Response<Void>> in
                return Observable.just(.fail(err: "Error"))
            })
    }
}

