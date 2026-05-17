import XCTest
@testable import GalaxySelfie

final class HandPoseClassifierTests: XCTestCase {
    func testStubDoesNotClassifyEmptyPoseAsPalm() {
        let classifier = HandPoseClassifier()
        XCTAssertFalse(classifier.isOpenPalm(HandPose(points: [:])))
    }

    func testOpenPalmIsClassifiedAsPalm() {
        let classifier = HandPoseClassifier()
        XCTAssertTrue(classifier.isOpenPalm(Self.openPalmPose()))
    }

    func testClusteredFingertipsAreRejected() {
        let classifier = HandPoseClassifier()
        var pose = Self.openPalmPose()
        pose.points[.indexTip] = HandJointPoint(x: 0.48, y: 0.72, confidence: 0.9)
        pose.points[.middleTip] = HandJointPoint(x: 0.49, y: 0.73, confidence: 0.9)
        pose.points[.ringTip] = HandJointPoint(x: 0.50, y: 0.72, confidence: 0.9)
        pose.points[.littleTip] = HandJointPoint(x: 0.51, y: 0.73, confidence: 0.9)

        XCTAssertFalse(classifier.isOpenPalm(pose))
    }

    func testFewerThanFourExtendedFingersAreRejected() {
        let classifier = HandPoseClassifier()
        var pose = Self.openPalmPose()
        pose.points[.ringTip] = HandJointPoint(x: 0.58, y: 0.42, confidence: 0.9)
        pose.points[.littleTip] = HandJointPoint(x: 0.66, y: 0.39, confidence: 0.9)

        XCTAssertFalse(classifier.isOpenPalm(pose))
    }

    func testMissingWristIsRejected() {
        let classifier = HandPoseClassifier()
        var pose = Self.openPalmPose()
        pose.points[.wrist] = nil

        XCTAssertFalse(classifier.isOpenPalm(pose))
    }

    func testLowConfidenceJointIsRejected() {
        let classifier = HandPoseClassifier()
        var pose = Self.openPalmPose()
        pose.points[.middleTip] = HandJointPoint(x: 0.50, y: 0.90, confidence: 0.1)
        pose.points[.ringTip] = HandJointPoint(x: 0.58, y: 0.84, confidence: 0.1)

        XCTAssertFalse(classifier.isOpenPalm(pose))
    }

    private static func openPalmPose() -> HandPose {
        HandPose(points: [
            .wrist: HandJointPoint(x: 0.50, y: 0.10, confidence: 0.9),
            .thumbCMC: HandJointPoint(x: 0.38, y: 0.30, confidence: 0.9),
            .thumbMP: HandJointPoint(x: 0.28, y: 0.48, confidence: 0.9),
            .thumbIP: HandJointPoint(x: 0.22, y: 0.62, confidence: 0.9),
            .thumbTip: HandJointPoint(x: 0.14, y: 0.74, confidence: 0.9),
            .indexMCP: HandJointPoint(x: 0.43, y: 0.36, confidence: 0.9),
            .indexPIP: HandJointPoint(x: 0.38, y: 0.58, confidence: 0.9),
            .indexDIP: HandJointPoint(x: 0.35, y: 0.74, confidence: 0.9),
            .indexTip: HandJointPoint(x: 0.32, y: 0.88, confidence: 0.9),
            .middleMCP: HandJointPoint(x: 0.50, y: 0.38, confidence: 0.9),
            .middlePIP: HandJointPoint(x: 0.50, y: 0.62, confidence: 0.9),
            .middleDIP: HandJointPoint(x: 0.50, y: 0.78, confidence: 0.9),
            .middleTip: HandJointPoint(x: 0.50, y: 0.94, confidence: 0.9),
            .ringMCP: HandJointPoint(x: 0.57, y: 0.36, confidence: 0.9),
            .ringPIP: HandJointPoint(x: 0.62, y: 0.57, confidence: 0.9),
            .ringDIP: HandJointPoint(x: 0.65, y: 0.72, confidence: 0.9),
            .ringTip: HandJointPoint(x: 0.68, y: 0.86, confidence: 0.9),
            .littleMCP: HandJointPoint(x: 0.64, y: 0.32, confidence: 0.9),
            .littlePIP: HandJointPoint(x: 0.72, y: 0.50, confidence: 0.9),
            .littleDIP: HandJointPoint(x: 0.77, y: 0.62, confidence: 0.9),
            .littleTip: HandJointPoint(x: 0.82, y: 0.74, confidence: 0.9)
        ])
    }
}
