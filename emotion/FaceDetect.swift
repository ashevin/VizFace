//
//  FaceDetect.swift
//  emotion
//
//  Created by Avi Shevin on 02/10/2019.
//  Copyright © 2019 Avi Shevin. All rights reserved.
//

import UIKit

private let apiKey = "bf84aac353a34ef19a5687ebce41d9eb"
private let ep = URL(string: "https://vizface.cognitiveservices.azure.com/face/v1.0/detect?returnFaceLandmarks=true&returnFaceAttributes=emotion")!

enum Emotion {
    case sadness
    case anger
    case happiness
    case fear
    case neutral
    case contempt
    case disgust
    case surprise
}

// This struct takes advantage of the fact that extra fields in a decodable stream
// are ignored when decoding.  Only objects relevant to the app are decoded.
struct DetectionResult: Decodable {
    struct FaceAttributes: Decodable {
        struct Emotions: Decodable {
            let sadness: Double
            let anger: Double
            let happiness: Double
            let fear: Double
            let neutral: Double
            let contempt: Double
            let disgust: Double
            let surprise: Double

            var dominant: Emotion {
                var emotions = [(Emotion, Double)]()
                emotions.append((.sadness, sadness))
                emotions.append((.anger, anger))
                emotions.append((.happiness, happiness))
                emotions.append((.fear, fear))
                emotions.append((.neutral, neutral))
                emotions.append((.contempt, contempt))
                emotions.append((.disgust, disgust))
                emotions.append((.surprise, surprise))

                return emotions.max(by: { $0.1 < $1.1 })!.0
            }
        }

        let emotion: Emotions
    }

    struct FaceRectangle: Decodable {
        let top: Int
        let left: Int
        let width: Int
        let height: Int
    }

    let faceAttributes: FaceAttributes
    let faceRectangle: FaceRectangle

    var faceRect: CGRect {
        CGRect(x: faceRectangle.left,
               y: faceRectangle.top,
               width: faceRectangle.width,
               height: faceRectangle.height)
    }
}

struct ErrorResult: Error, Decodable {
    struct Result: Error, Decodable {
        let code: String
        let message: String
    }

    let error: Result
}

enum FaceDetectError: Error {
    case dataConversionFailed
    case emptyResult
    case noData
}

func detect(_ image: UIImage) -> Promise<(UIImage, DetectionResult)> {
    guard let data = image.jpegData(compressionQuality: 1.0) else {
        return Promise(FaceDetectError.dataConversionFailed)
    }

    let promise = Promise<(UIImage, DetectionResult)>()

    var req = URLRequest(url: ep)
    req.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
    req.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    req.httpMethod = "POST"
    req.httpBody = data

    let session = URLSession(configuration: .default)

    session.dataTask(with: req) { (data, response, error) in
        if let error = error {
            promise.signal(error)

            return
        }

        guard let data = data else {
            promise.signal(FaceDetectError.noData)

            return
        }

        do {
            if let err = try? JSONDecoder().decode(ErrorResult.self, from: data) {
                promise.signal(err)

                return
            }

            let results = try JSONDecoder().decode([DetectionResult].self, from: data)

            guard let result = results.first else {
                promise.signal(FaceDetectError.emptyResult)

                return
            }

            promise.signal((image, result))
        }
        catch {
            promise.signal(error)
        }
    }
    .resume()

    return promise
}
