//
//  AddTripViewModel.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class AddTripViewModel {
    
    let tripnameErrorDrv: Driver<String>
    let startDateErrorDrv: Driver<String>
    let endDateErrorDrv: Driver<String>
    let submissionDrv: Driver<Bool>
    let submissionErrDrv: Driver<String>
    let submitProgressDrv: Driver<Bool>
    
    init(input: (tripname: Driver<String>,
        startDate: Driver<String>,
        endDate: Driver<String>,
        confirm: Driver<Void>)) {
        
        let tripNameErrorSubject = PublishSubject<String>()
        tripnameErrorDrv = tripNameErrorSubject.asDriver(onErrorDriveWith: Driver.never())
        
        let validateTripname = input.confirm
            .withLatestFrom(input.tripname)
            .map { (content) -> String? in
                guard !content.isEmpty else {
                    tripNameErrorSubject.onNext("Please specify trip name")
                    return nil
                }
                
                tripNameErrorSubject.onNext("")
                return content
            }
            .asDriver()
        
        let startDateErrorSubject = PublishSubject<String>()
        startDateErrorDrv = startDateErrorSubject.asDriver(onErrorDriveWith: Driver.never())
        
        let validateStartDate = input.confirm
            .withLatestFrom(input.startDate)
            .map { (content) -> String? in
                guard !content.isEmpty else {
                    startDateErrorSubject.onNext("Please specify trip start date")
                    return nil
                }
                startDateErrorSubject.onNext("")
                return content
            }
            .asDriver()
        
        let endDateErrorSubject = PublishSubject<String>()
        endDateErrorDrv = endDateErrorSubject.asDriver(onErrorDriveWith: Driver.never())
        
        let validateEndDate = input.confirm
            .withLatestFrom(input.endDate)
            .map { (content) -> String? in
                guard !content.isEmpty else {
                    endDateErrorSubject.onNext("Please specify trip end date")
                    return nil
                }
                endDateErrorSubject.onNext("")
                return content
            }
            .asDriver()
        
        let errSubject = PublishSubject<String>()
        submissionErrDrv = errSubject.asDriver(onErrorDriveWith: Driver.never())
        let activityIndicator = ActivityIndicator()
        submitProgressDrv = activityIndicator.asDriver()
        
        submissionDrv = Driver.combineLatest([validateTripname, validateStartDate, validateEndDate])
            .asObservable()
            .map({ (pair) -> (tripname: String, startDate: String, endDate: String)? in
                guard let tripname = pair[0], let startDate = pair[1], let endDate = pair[2] else { return nil }
                return (tripname, startDate, endDate)
            })
            .skipWhile { $0 == nil }
            .flatMapLatest({ (entry) -> Observable<Bool> in
                errSubject.onNext("")
                guard let tripname = entry?.tripname, let startDate = entry?.startDate, let endDate = entry?.endDate else {
                    return Observable.never()
                }
                return TripService.createRecord(trip_name: tripname, trip_type: "upcoming", startDate: startDate, endDate: endDate)
                    .map({ (response) -> Bool in
                        switch response {
                        case .success:
                            return true
                        case .fail(let err):
                            errSubject.onNext(err.description)
                            return false
                        }
                    })
                    .trackActivity(activityIndicator)
            })
            .asDriver(onErrorJustReturn: false)
    }
}
