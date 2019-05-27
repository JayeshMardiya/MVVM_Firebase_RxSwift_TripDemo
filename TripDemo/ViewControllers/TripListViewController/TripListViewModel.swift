//
//  TripListViewModel.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import FirebaseAuth
import FirebaseDatabase

enum TripRecord {
    case record(viewModel: TripRecordCellViewModel)
    case error(err: String?)
    case empty
}

class TripRecordCellViewModel {
    
    let infoDrv: Driver<(timestamp: String, trip_name: String, trip_type: String, startDate: String, endDate: String)>
    let deletionSubject: PublishSubject<Void> = .init()
    let deletionDrv: Driver<String?>
    let deletionProgressDrv: Driver<Bool>
    
    init(stamp: String, trip_name: String, trip_type: String, startDate: String, endDate: String) {
        
        infoDrv = Driver.just((stamp, trip_name, trip_type, startDate, endDate))
        
        let activity = ActivityIndicator()
        deletionProgressDrv = activity.asDriver(onErrorDriveWith: Driver.never())
        
        deletionDrv = deletionSubject
            .flatMap({ _ -> Observable<String?> in
                return TripService.deleteRecord(stamp)
                    .map({ (response) -> String? in
                        switch response {
                        case .success:
                            return nil
                        case .fail(let err):
                            return err.description
                        }
                    })
                    .trackActivity(activity)
            })
            .asDriver(onErrorJustReturn: nil)
    }
}

class TripListViewModel {
    
    let loggedInDrv: Driver<Bool>
    let recordsDrv: Driver<[TripRecord]>
    let newEntryEnabledDrv: Driver<Bool>
    let errResponseDrv: Driver<String>
    let reloadSubject: PublishSubject<Void> = .init()
    let reloadProgressDrv: Driver<Bool>
    
    init() {
        let errRespSubject = PublishSubject<String>()
        errResponseDrv = errRespSubject.asDriver(onErrorDriveWith: Driver.never())
        
        loggedInDrv = TripService.authStateChanged()
            .map({ (response) -> User? in
                switch response {
                case .success(let resp):
                    return resp
                case .fail(let err):
                    errRespSubject.onNext(err.description)
                    return nil
                }
            })
            .map { $0 != nil }
            .asDriver(onErrorJustReturn: false)
        
        let loggedInAndReload = Driver.combineLatest(
            self.loggedInDrv,
            reloadSubject.startWith(())
                .asDriver(onErrorJustReturn: ())) {
                    (logged: $0, reload: $1 )
        }
        
        let reloadActIndicator = ActivityIndicator()
        reloadProgressDrv = reloadActIndicator.asDriver()
        
        recordsDrv = loggedInAndReload
            .asObservable()
            .flatMap({ _ -> Observable<[TripRecord]> in
                
                return TripService.fetchRecords()
                    .map({ (response) -> (records: [TripService.Record]?, err: String?) in
                        switch response {
                        case .success(let resp):
                            return (resp, nil)
                        case .fail(let err):
                            return (nil, err)
                        }
                    })
                    .map({ (result) -> [TripRecord] in
                        guard let records = result.records else {
                            return [TripRecord.error(err: result.err?.description ?? "")]
                        }
                        if records.isEmpty {
                            return [TripRecord.empty]
                        }
                        return records.map({ (serviceRecord) -> TripRecord in
                            return TripRecord.record(viewModel: TripRecordCellViewModel(stamp: serviceRecord.timestamp, trip_name: serviceRecord.trip_name, trip_type: serviceRecord.trip_type, startDate: serviceRecord.startDate, endDate: serviceRecord.endDate))
                        })
                    })
                    .trackActivity(reloadActIndicator)
            })
            .asDriver(onErrorJustReturn: [])
        
        newEntryEnabledDrv = recordsDrv
            .map({ (records) -> Bool in
                guard records.count == 1, case .error = records[0] else {
                    return true
                }
                return false
            })
    }
}
