//
//  ViewController.swift
//  emotion
//
//  Created by Avi Shevin on 02/10/2019.
//  Copyright © 2019 Avi Shevin. All rights reserved.
//

import UIKit
import PhotosUI
import CoreGraphics

class ViewController: UIViewController {
    @IBOutlet weak var choosePhotoBtn: UIButton!
    @IBOutlet weak var takePhotoBtn: UIButton!
    @IBOutlet var busyIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        takePhotoBtn.isHidden =
            !UIImagePickerController.isCameraDeviceAvailable(.front) &&
            !UIImagePickerController.isCameraDeviceAvailable(.rear)
    }

    @IBAction func choosePhotoTap(_ sender: Any) {
        displayImagePicker(using: .photoLibrary)
    }

    @IBAction func takePhotoTap(_ sender: Any) {
        displayImagePicker(using: .camera)
    }

    func displayImagePicker(using source: UIImagePickerController.SourceType) {
        let pvc = UIImagePickerController()
        pvc.sourceType = source
        pvc.delegate = self

        present(pvc, animated: true, completion: nil)
    }

    func display(image: UIImage, result: DetectionResult) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "emotion_result") as? EmotionViewController else {
            return
        }

        // Choosing to crop here is a bit of a judgement call.  The rational is
        // that the destination is given *what* to display, and the cropped
        // image is that thing.
        // It would also be a valid design to pass the raw image and the full
        // detection results, and allow the destination to choose what to do
        // with that information.
        vc.image = image.cropped(to: result.faceRect)
        vc.emotion = result.faceAttributes.emotion

        present(vc, animated: true, completion: nil)
    }

    // There's no product definition for error handling, thus errors are simply
    // displayed in an alert.  No attempt is made to make messages readable.
    func display(error: Error) {
        let err = String(describing: error)

        let ac = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))

        present(ac, animated: true, completion: nil)
    }

    func showBusy() {
        busyIndicator.startAnimating()
        choosePhotoBtn.isEnabled = false
        takePhotoBtn.isEnabled = false
    }

    func showAvailable() {
        busyIndicator.stopAnimating()
        choosePhotoBtn.isEnabled = true
        takePhotoBtn.isEnabled = true
    }

    // Images taken by the camera are not rotated as expected
    func rotate(image: UIImage) -> UIImage {
        let angle: CGFloat
        // The .up and .upMirrored orientations do not require rotation
        switch image.imageOrientation {
        case .down, .downMirrored:
            angle = CGFloat.pi
        case .left, .leftMirrored:
            angle = CGFloat.pi * 1.5
        case .right, .rightMirrored:
            angle = CGFloat.pi / 2
        default:
            angle = 0
        }

        return image.rotated(by: angle)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }

        showBusy()

        detect(rotate(image: image))
            .then(on: .main) { self.display(image: $0.0, result: $0.1) }
            .error(on: .main) { self.display(error: $0) }
            .finally(on: .main) { self.showAvailable() }

        picker.dismiss(animated: true, completion: nil)
    }
}
