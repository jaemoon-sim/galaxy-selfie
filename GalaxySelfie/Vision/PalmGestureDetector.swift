import CoreImage
import Foundation
import ImageIO
import Vision

final class PalmGestureDetector {
    private let classifier: HandPoseClassifier

    init(classifier: HandPoseClassifier = HandPoseClassifier()) {
        self.classifier = classifier
    }

    func detectPalm(in pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation) async -> Bool {
        false
    }
}
