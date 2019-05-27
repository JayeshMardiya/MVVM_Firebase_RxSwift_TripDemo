//
//  EmailAuthController.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2018 Jayesh Mardiya. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class EmailAuthController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var backgroundTapGesture: UITapGestureRecognizer!

    fileprivate var viewModel: EmailAuthViewModel?
    fileprivate let disposeBag = DisposeBag()

    var purpose: EmailAuthViewModel.Purpose? {
        willSet {
            guard let value = newValue else { return }
            viewModel = EmailAuthViewModel.create(purpose: value,
                                                  input: (
                                                    email: self.emailTxtField.rx.text.orEmpty.asDriver(),
                                                    password: self.passwordTxtField .rx.text.orEmpty.asDriver(),
                                                    actionTap: actionBtn.rx.tap.asDriver()))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = viewModel?.pageTitle
        actionBtn.setTitle(viewModel?.functionTitle, for: .normal)
        self.rxSetup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func rxSetup() {

        guard let vm = viewModel else { return }

        cancelBtn.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: {
                    self?.view.endEditing(true)
                })
            }).disposed(by: disposeBag)
        
        backgroundTapGesture.rx.event
            .subscribe(onNext: { (tap) in
                self.view.endEditing(true)
            })
            .disposed(by: disposeBag)
        
        vm.emailValidationDrv
            .drive()
            .disposed(by: disposeBag)
        
        vm.passwordValidationDrv
            .drive()
            .disposed(by: disposeBag)
        
        vm.errorPublishDrv
            .flatMap({ (err) in
                self.showAlert(message: err).asDriver(onErrorDriveWith: Driver.never())
            })
            .drive()
            .disposed(by: disposeBag)

        vm.processingDrv
            .drive(onNext: { (flag) in
                
                self.emailTxtField.isEnabled = !flag
                self.passwordTxtField.isEnabled = !flag
                self.actionBtn.isEnabled = !flag
            })
            .disposed(by: disposeBag)

        vm.completionDrv
            .drive()
            .disposed(by: disposeBag)
    }
}
