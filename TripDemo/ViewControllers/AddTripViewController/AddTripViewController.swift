//
//  AddTripViewController.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class AddTripViewController: UIViewController {

    @IBOutlet weak var txtTripName: UITextField!
    @IBOutlet weak var txtStartDate: UITextField!
    @IBOutlet weak var txtEndDate: UITextField!
    @IBOutlet weak var btnAddTrip: UIButton!
    
    fileprivate let disposeBag  = DisposeBag()
    fileprivate var activeTextField = UITextField()
    fileprivate var startDate: Date? = nil
    fileprivate var endDate: Date? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add Trip"

        let vm = AddTripViewModel(input: (tripname: self.txtTripName.rx.text.orEmpty.asDriver(), startDate: self.txtStartDate.rx.text.orEmpty.asDriver(), endDate: self.txtEndDate.rx.text.orEmpty.asDriver(), confirm: self.btnAddTrip.rx.tap.asDriver()))
        
        vm.submissionDrv
            .drive(onNext: { (result) in
                if result {
                    self.navigationController?.popViewController(animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    @objc func datePickerValueChanged(sender: UIDatePicker) {

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.timeStyle = .none
        
        if self.activeTextField == self.txtStartDate {
            self.startDate = sender.date
        } else  if self.activeTextField == self.txtEndDate {
            self.endDate = sender.date
        }
        
        self.activeTextField.text = dateFormatter.string(from: sender.date)
    }
}

extension AddTripViewController: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.activeTextField = textField
        
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePicker.Mode.date
        textField.inputView = datePickerView
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.timeStyle = .none
        
        if self.activeTextField == self.txtStartDate {
            textField.text = dateFormatter.string(from: Date())
            self.startDate = Date()
        } else {
            if let date = self.startDate {
                datePickerView.minimumDate = date
                textField.text = dateFormatter.string(from: date)
            }
        }
        
        datePickerView.addTarget(self, action: #selector(datePickerValueChanged), for: UIControlEvents.valueChanged)
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
}
