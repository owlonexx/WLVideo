//
//  WLImageRotate.swift
//  WLVideo
//
//  Created by Mr.wang on 2018/12/11.
//  Copyright © 2018 Mr.wang. All rights reserved.
//

import UIKit

class WLImageRotate {

    static func rotateImage(_ image: UIImage, withAngle angle: Double) -> UIImage {
        if angle.truncatingRemainder(dividingBy: 360) == 0 { return image }
        
        let imageRect = CGRect(origin: .zero, size: image.size)
        let radian = CGFloat(angle / 180 * .pi)
        let rotatedTransform = CGAffineTransform.identity.rotated(by: radian)
        var rotatedRect = imageRect.applying(rotatedTransform)
        rotatedRect.origin.x = 0
        rotatedRect.origin.y = 0
        
        UIGraphicsBeginImageContext(rotatedRect.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.translateBy(x: rotatedRect.width / 2, y: rotatedRect.height / 2)
        context?.rotate(by: radian)
        context?.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)
        image.draw(at: .zero)
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return rotatedImage!
    }
    
}
