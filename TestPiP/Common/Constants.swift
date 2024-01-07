//
//  Constants.swift
//  TestPiP
//
//  Created by Licious on 07/01/24.
//

import Foundation
import UIKit

struct Constants {
    static let disablePiPInBackground: Bool = true
    static let autoResumePiPOnForeground: Bool = false
}

extension UIView {
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}

var appDelegate: AppDelegate? {
    return UIApplication.shared.delegate as? AppDelegate
}
