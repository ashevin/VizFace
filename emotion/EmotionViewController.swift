//
//  EmotionViewController.swift
//  emotion
//
//  Created by Avi Shevin on 02/10/2019.
//  Copyright © 2019 Avi Shevin. All rights reserved.
//

import UIKit

class EmotionViewController: UIViewController {
    @IBOutlet weak var faceImage: UIImageView!
    @IBOutlet weak var emotionText: UITextView!

    var image: UIImage!
    var emotion: DetectionResult.FaceAttributes.Emotions!

    let emojis = [
        Emotion.sadness: "😥",
        Emotion.anger: "😡",
        Emotion.happiness: "😀",
        Emotion.fear: "😱",
        Emotion.neutral: "😐",
        Emotion.contempt: "🙄",
        Emotion.disgust: "",
        Emotion.surprise: "😮",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        faceImage.image = image
        emotionText.text = String(describing: emotion.dominant) +
            "\n\n" + emojis[emotion.dominant]!
    }

    @IBAction func doneTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
