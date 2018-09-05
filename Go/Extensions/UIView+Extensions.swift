//
//  UIView+Extensions.swift
//  Go
//
//  Created by Victor Idongesit on 04/09/2018.
//  Copyright © 2018 Victor Idongesit. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    public func addShadows(offset: CGFloat, radius: CGFloat, opacity: Float) {
        self.layer.shadowColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        self.layer.shadowRadius = radius
        self.layer.shadowOffset = CGSize(width: offset, height: offset)
        self.layer.shadowOpacity = opacity
    }
    
    public func addShadowAndCurve(offset: CGFloat, radius: CGFloat, opacity: Float, cornerRadius: CGFloat) {
        
        
    }
}
