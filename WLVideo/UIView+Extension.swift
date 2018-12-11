//
//  UIView+Extension.swift
//  IOS-Project
//
//  Created by Mr.wang on 2018/11/19.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit

extension UIView {
    
    func removeAllSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
    }
    
    public var x: CGFloat{
        get{
            return self.frame.origin.x
        }
        set{
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    
    public var y: CGFloat{
        get {
            return self.frame.origin.y
        }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    
    public var width: CGFloat{
        get {
            return self.frame.size.width
        }
        set{
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    
    public var height: CGFloat{
        get {
            return self.frame.size.height
        }
        set{
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    public var right: CGFloat{
        get {
            return self.frame.origin.x + self.frame.size.width
        }
    }
    
    public var bottom: CGFloat{
        get {
            return self.frame.origin.y+self.frame.size.height
        }
    }
    
}
