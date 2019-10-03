//
//  UIImage+extensions.swift
//  emotion
//
//  Created by Avi Shevin on 03/10/2019.
//  Copyright © 2019 Avi Shevin. All rights reserved.
//

import UIKit

extension UIImage {
    func cropped(to rect: CGRect) -> UIImage {
        let cgImage = self.cgImage!
        let croppedCGImage = cgImage.cropping(to: rect)

        return UIImage(cgImage: croppedCGImage!)
    }

    // Images taken by the camera are not rotated as expected
    func rotated(by angle: CGFloat) -> UIImage {
        let ciImage = CIImage(image: self)

        let filter = CIFilter(name: "CIAffineTransform")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setDefaults()

        let newAngle = angle * CGFloat(-1)

        var transform = CATransform3DIdentity
        transform = CATransform3DRotate(transform, CGFloat(newAngle), 0, 0, 1)

        let affineTransform = CATransform3DGetAffineTransform(transform)

        filter?.setValue(NSValue(cgAffineTransform: affineTransform), forKey: "inputTransform")

        let contex = CIContext(options: [CIContextOption.useSoftwareRenderer:true])

        let outputImage = filter?.outputImage
        let cgImage = contex.createCGImage(outputImage!, from: (outputImage?.extent)!)

        let result = UIImage(cgImage: cgImage!)
        return result
    }
}
