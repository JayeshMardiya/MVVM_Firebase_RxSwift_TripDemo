//
//  TripRecordCell.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import RxGesture

class TripRecordCell: UITableViewCell {
    
    enum ControlState {
        case normal, transforming, delete
        
        fileprivate var snapPoint: CGFloat {
            switch self {
            case .normal:   return 0.0
            case .delete:   return 80.0
            default:        return CGFloat.leastNormalMagnitude
            }
        }
        
        fileprivate var offsetThreshold: CGFloat {
            switch self {
            case .transforming: return 20.0
            case .delete:       return 72.0
            default:            return CGFloat.leastNormalMagnitude
            }
        }
    }
    
    @IBOutlet weak var infoContainer: UIView!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var tripNameLbl: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var infoContainerLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoContainerTrailingConstraint: NSLayoutConstraint!
    
    fileprivate static let SnapAnimationLength: TimeInterval = 0.2
    fileprivate var state: ControlState = .normal
    fileprivate var gestureOffsetAnchor: CGFloat?
    fileprivate var gestureOffset: CGFloat = 0
    private(set) var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func controlState() -> Driver<ControlState> {
        return self.infoContainer.rx
            .anyGesture(
                .tap(),
                .pan(configuration: { gesture, delegate in
                    delegate.simultaneousRecognitionPolicy = .custom({ (gesture, otherGesture) -> Bool in
                        guard let scrollPan = otherGesture as? UIPanGestureRecognizer else { return true }
                        let velocity = scrollPan.velocity(in: self)
                        return abs(velocity.y) > abs(velocity.x)
                    })
                    delegate.beginPolicy = .custom({ gesture -> Bool in
                        guard let pan = gesture as? UIPanGestureRecognizer else { return true }
                        return abs(pan.translation(in: pan.view).y) <= 0
                    })
                })
            )
            .map({ (gesture) -> (initial: CGFloat?, current: CGFloat?)? in
                guard let pan = gesture as? UIPanGestureRecognizer else { return nil }
                let location = pan.location(in: self)
                switch pan.state {
                case .began:    return (location.x, location.x)
                case .changed:  return (nil, location.x)
                case .ended:    return (nil, CGFloat.greatestFiniteMagnitude)
                default:        return nil
                }
            })
            .map { (gestureLocation) -> ControlState in
                guard let location = gestureLocation else {
                    return .normal
                }
                if let anchor =  location.initial {
                    self.gestureOffsetAnchor = (self.state == .delete) ?
                        (anchor + TripRecordCell.ControlState.transforming.offsetThreshold + self.state.snapPoint) : anchor
                }
                guard let anchor = self.gestureOffsetAnchor, let current = location.current else {
                    return .normal
                }
                guard current != CGFloat.greatestFiniteMagnitude else {
                    if self.gestureOffset > ControlState.delete.offsetThreshold {
                        return .delete
                    }
                    return .normal
                }
                self.gestureOffset = (anchor - current)
                if self.gestureOffset > ControlState.transforming.offsetThreshold {
                    self.infoContainerLeadingConstraint.constant = -self.gestureOffset + ControlState.transforming.offsetThreshold
                    self.infoContainerTrailingConstraint.constant = self.gestureOffset - ControlState.transforming.offsetThreshold
                    return .transforming
                }
                return .normal
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .normal)
    }
}

extension Reactive where Base: TripRecordCell {
    
    var controlState: Binder<TripRecordCell.ControlState> {
        return Binder(base, binding: { (cell, newState) in
            cell.state = newState
            guard cell.state != .transforming else { return }
            
            let gap = TripRecordCell.ControlState.transforming.offsetThreshold
            let durationRatio = (cell.gestureOffset > TripRecordCell.ControlState.delete.offsetThreshold) ?
                abs(cell.gestureOffset - gap - TripRecordCell.ControlState.delete.snapPoint) / TripRecordCell.ControlState.delete.snapPoint :
                abs(cell.gestureOffset - gap) / TripRecordCell.ControlState.delete.snapPoint
            let duration = TripRecordCell.SnapAnimationLength * Double(min(durationRatio, 1.0))
            
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
                cell.infoContainerLeadingConstraint.constant = -newState.snapPoint
                cell.infoContainerTrailingConstraint.constant = newState.snapPoint
                cell.layoutIfNeeded()
            })
        })
    }
    
    var info: Binder<(timestamp: String, trip_name: String, trip_type: String, startDate: String, endDate: String)> {
        return Binder(base, binding: { (cell, info) in
            
            cell.dateLbl.text = "\(info.startDate)-\(info.endDate)"
            cell.tripNameLbl.text = "\(info.trip_name)"
        })
    }
}
