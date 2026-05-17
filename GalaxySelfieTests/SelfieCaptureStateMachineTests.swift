import XCTest
@testable import GalaxySelfie

final class SelfieCaptureStateMachineTests: XCTestCase {
    func testIdleStatusTextPromptsForPalm() {
        XCTAssertEqual(SelfieCaptureState.idle.statusText, "Show your palm to start")
    }
}
