//
//  SignInViewController.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 25/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import GoogleSignIn

class SignInViewController: UIViewController {

    @IBOutlet weak var googleSignInBtn: UIButton!
    @IBOutlet weak var emailSignInBtn: UIButton!
    @IBOutlet weak var emailSignUpBtn: UIButton!
    
    fileprivate var emailAuthController: EmailAuthController?
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        GIDSignIn.sharedInstance().uiDelegate = self
        self.rxSetup()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let identifier = segue.identifier else { return }
        
        switch identifier {
        case "segue_emailAuth":
            emailAuthController = segue.destination as? EmailAuthController
        default:
            break
        }
    }
    
    func rxSetup() {
        
        let vm = SignInViewModel(withGoogleSignInOnTap: googleSignInBtn.rx.tap.asDriver())
        
        vm.googleSignedInDrv
            .drive()
            .disposed(by: disposeBag)
        
        vm.processingDrv
            .drive(onNext: { (flag) in
                self.googleSignInBtn.isEnabled = !flag
            })
            .disposed(by: disposeBag)
        
        vm.errResponseDrv
            .flatMap({ (err) in
                self.showAlert(message: err).asDriver(onErrorDriveWith: Driver.never())
            })
            .drive()
            .disposed(by: disposeBag)
        
        emailSignInBtn.rx.tap
            .asObservable()
            .subscribe(onNext: { _ in
                self.performSegue(withIdentifier: "segue_emailAuth", sender: nil)
                guard let authCtrl = self.emailAuthController else { return }
                authCtrl.purpose = .signIn
            })
            .disposed(by: disposeBag)
        
        emailSignUpBtn.rx.tap
            .asObservable()
            .subscribe(onNext: { _ in
                self.performSegue(withIdentifier: "segue_emailAuth", sender: nil)
                guard let authCtrl = self.emailAuthController else { return }
                authCtrl.purpose = .signUp
            })
            .disposed(by: disposeBag)
    }
}

extension SignInViewController: GIDSignInUIDelegate {
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        present(viewController, animated: true, completion: nil)
    }
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        dismiss(animated:  true, completion: nil)
    }
}

