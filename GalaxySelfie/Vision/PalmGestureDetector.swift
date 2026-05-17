import CoreImage
import Foundation
import Vision

final class PalmGestureDetector {
    private let classifier: HandPoseClassifier

    init(classifier: HandPoseClassifier = HandPoseClassifier()) {
        self.classifier = classifier
    }

    func detectPalm(in pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) -> Bool {
        false
    }
}
