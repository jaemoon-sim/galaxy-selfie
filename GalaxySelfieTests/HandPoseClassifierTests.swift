import XCTest
@testable import GalaxySelfie

final class HandPoseClassifierTests: XCTestCase {
    func testStubDoesNotClassifyEmptyPoseAsPalm() {
        let classifier = HandPoseClassifier()
        XCTAssertFalse(classifier.isOpenPalm(HandPose(points: [:])))
    }
}
