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
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 2

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
            return (request.results ?? []).contains { observation in
                guard let pose = HandPose(observation: observation) else {
                    return false
                }
                return classifier.isOpenPalm(pose)
            }
        } catch {
            return false
        }
    }
}

private extension HandPose {
    init?(observation: VNHumanHandPoseObservation) {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
            return nil
        }

        var points: [HandJoint: HandJointPoint] = [:]

        for (visionJoint, handJoint) in Self.jointMapping {
            guard let recognizedPoint = recognizedPoints[visionJoint] else {
                continue
            }

            points[handJoint] = HandJointPoint(
                x: recognizedPoint.location.x,
                y: recognizedPoint.location.y,
                confidence: recognizedPoint.confidence
            )
        }

        guard !points.isEmpty else {
            return nil
        }

        self.init(points: points)
    }

    static var jointMapping: [VNHumanHandPoseObservation.JointName: HandJoint] {
        [
            .wrist: .wrist,
            .thumbCMC: .thumbCMC,
            .thumbMP: .thumbMP,
            .thumbIP: .thumbIP,
            .thumbTip: .thumbTip,
            .indexMCP: .indexMCP,
            .indexPIP: .indexPIP,
            .indexDIP: .indexDIP,
            .indexTip: .indexTip,
            .middleMCP: .middleMCP,
            .middlePIP: .middlePIP,
            .middleDIP: .middleDIP,
            .middleTip: .middleTip,
            .ringMCP: .ringMCP,
            .ringPIP: .ringPIP,
            .ringDIP: .ringDIP,
            .ringTip: .ringTip,
            .littleMCP: .littleMCP,
            .littlePIP: .littlePIP,
            .littleDIP: .littleDIP,
            .littleTip: .littleTip
        ]
    }
}
