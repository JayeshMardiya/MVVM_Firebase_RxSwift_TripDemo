//
//  StoryboardUtils.swift
//  TripDemo
//
//  Created by Jayesh Mardiya on 24/05/19.
//  Copyright © 2018 Jayesh Mardiya. All rights reserved.
//

import Foundation
import UIKit

// MARK: UIStoryBoards identifiers
extension UIStoryboard {
    
    enum Storyboard: String {
        
        case AddTripViewController
        case TripListViewController
        
        // Real filename
        var filename: String { return rawValue }
    }
    
    /// Retrieve `UIStoryboard` for given `Storyboard` enum
    class func storyboard(_ storyboard: Storyboard, bundle: Bundle? = nil) -> UIStoryboard {
        return UIStoryboard(name: storyboard.filename, bundle: bundle)
    }
    
    /// Instantiate view controller with generics
    func instantiate<T: UIViewController>() -> T {
        guard let viewController = self.instantiateViewController(withIdentifier: T.storyboardIdentifier) as? T else {
            
            self.fatalError(message: "Can't instantiate view controller with identifier: \(T.storyboardIdentifier)", event: .nullPointer)
        }
        return viewController
    }
    
    func fatalError(message:    String,
                                 event:      LogEvent,
                                 fileName:   String      = #file,
                                 line:       Int         = #line,
                                 funcName:   String      = #function) -> Never {
        /// Print message
        Swift.fatalError("\(event.rawValue)[\(funcName)] → \"\(message)\"")
    }
}

public enum LogEvent: String {
    case info           = "[ℹ️]"
    case warning        = "[⚠️]"
    case error          = "[🛑]"
    case success        = "[✅]"
    case nullPointer    = "[❓]"
    case emptyArray     = "[📭]"
}

// MARK: UIViewControllers identifiers
/// Protocol to give any class that conform it a static variable `storyboardIdentifier`
protocol StoryboardIdentifiable {
    static var storyboardIdentifier: String { get }
}
/// Protocol extension to implement `storyboardIdentifier` variable only when `Self` is of type `UIViewController`
extension StoryboardIdentifiable where Self: UIViewController {
    static var storyboardIdentifier: String { return String(describing: self) }
}
/// Create `UIViewController` extension to conform to `StoryboardIdentifiable`
extension UIViewController: StoryboardIdentifiable {}
