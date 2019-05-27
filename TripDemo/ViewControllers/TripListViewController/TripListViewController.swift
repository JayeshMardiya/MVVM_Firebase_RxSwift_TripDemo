//
//  TripListTableViewController.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxGesture

class TripListViewController: UIViewController {

    @IBOutlet weak var tripTableView: UITableView!
    fileprivate var tripTableViewDataSrc: RxTableViewSectionedReloadDataSource<SectionModel<String, TripRecord>>?
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Trips"
        
        self.rxSetup()
    }

    fileprivate func rxSetup() {

        let vm = TripListViewModel()
        tripTableViewDataSrc = RxTableViewSectionedReloadDataSource<SectionModel<String, TripRecord>>(
            configureCell: { (dataSrc, cv, indexPath, item) -> UITableViewCell in
                switch dataSrc[indexPath] {
                case .record(let recordVM):
                    let cell = cv.dequeueReusableCell(withIdentifier: "TripRecordCell", for: indexPath) as! TripRecordCell
                    recordVM.infoDrv
                        .drive(cell.rx.info)
                        .disposed(by: cell.disposeBag)
                    cell.controlState()
                        .drive(cell.rx.controlState)
                        .disposed(by: cell.disposeBag)
                    cell.deleteBtn.rx.tap
                        .flatMap({ _ -> Observable<Int> in
                            return self.showAlert(title: "Delete Record?",
                                                  message: "Confirm to delete this entry? ",
                                                  actions: [.cancel(title: "Cancel"), .option(title: "Delete")])
                        })
                        .skipWhile { $0 == 0 }
                        .map { _ in return () }
                        .bind(to: recordVM.deletionSubject)
                        .disposed(by: cell.disposeBag)
                    recordVM.deletionDrv
                        .flatMap({ (error) -> Driver<Int> in
                            guard let err = error else { return Driver.empty() }
                            return self.showAlert(message: err).asDriver(onErrorDriveWith: Driver.never())
                        })
                        .drive()
                        .disposed(by: cell.disposeBag)
                    recordVM.deletionProgressDrv
                        .drive(cell.loadingSpinner.rx.isAnimating)
                        .disposed(by: cell.disposeBag)
                    return cell
                    
                case .error(_):
                    let cell = cv.dequeueReusableCell(withIdentifier: "TripRecordCell", for: indexPath) as! TripRecordCell
                    return cell
                    
                case .empty:
                    return cv.dequeueReusableCell(withIdentifier: "TripRecordCell", for: indexPath)
                }
        })
        
        vm.loggedInDrv
            .drive(onNext: { (flag) in
                self.dismiss(animated: true, completion: nil)
                if flag != true {
                    self.performSegue(withIdentifier: "segue_requestAuth", sender: nil)
                }
            })
            .disposed(by: disposeBag)
        
        vm.errResponseDrv
            .flatMap({ (msg) in
                self.showAlert(message: msg).asDriver(onErrorDriveWith: Driver.never())
            })
            .drive()
            .disposed(by: disposeBag)
        
        vm.recordsDrv
            .map({ (records) -> [SectionModel<String, TripRecord>] in
                return [SectionModel(model: "", items: records)]
            })
            .drive(tripTableView.rx.items(dataSource: tripTableViewDataSrc!))
            .disposed(by: disposeBag)
    }
    
    @IBAction func addTripButtonPressed(_ sender: UIBarButtonItem) {
        
        let controller = UIStoryboard.storyboard(.AddTripViewController).instantiateViewController(withIdentifier: "AddTripViewController") as! AddTripViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
