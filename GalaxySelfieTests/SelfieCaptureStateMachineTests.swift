import XCTest
@testable import GalaxySelfie

final class SelfieCaptureStateMachineTests: XCTestCase {
    @MainActor
    func testIdleStatusTextPromptsForPalm() {
        XCTAssertEqual(SelfieCaptureState.idle.statusText, "Show your palm to start")
    }

    @MainActor
    func testPalmMustBeStableForOneSecond() {
        let viewModel = SelfieCaptureViewModel()
        let start = Date(timeIntervalSince1970: 100)

        viewModel.handlePalmDetection(true, at: start)
        XCTAssertEqual(viewModel.state, .detectingPalm)

        viewModel.handlePalmDetection(true, at: start.addingTimeInterval(0.9))
        XCTAssertEqual(viewModel.state, .detectingPalm)

        viewModel.cancelCountdown()
    }

    @MainActor
    func testStablePalmStartsCountdown() {
        let viewModel = SelfieCaptureViewModel()
        let start = Date(timeIntervalSince1970: 100)

        viewModel.handlePalmDetection(true, at: start)
        viewModel.handlePalmDetection(true, at: start.addingTimeInterval(1.0))

        XCTAssertEqual(viewModel.state, .countingDown(SelfieCaptureViewModel.countdownSeconds))
        viewModel.cancelCountdown()
    }

    @MainActor
    func testPalmLossBeforeStableReturnsToIdle() {
        let viewModel = SelfieCaptureViewModel()
        let start = Date(timeIntervalSince1970: 100)

        viewModel.handlePalmDetection(true, at: start)
        viewModel.handlePalmDetection(false, at: start.addingTimeInterval(0.4))

        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testCancelCountdownReturnsToIdle() {
        let viewModel = SelfieCaptureViewModel()
        let start = Date(timeIntervalSince1970: 100)

        viewModel.handlePalmDetection(true, at: start)
        viewModel.handlePalmDetection(true, at: start.addingTimeInterval(1.0))
        viewModel.cancelCountdown()

        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor
    func testDuplicatePalmDoesNotRestartActiveCountdown() {
        let viewModel = SelfieCaptureViewModel()
        let start = Date(timeIntervalSince1970: 100)

        viewModel.handlePalmDetection(true, at: start)
        viewModel.handlePalmDetection(true, at: start.addingTimeInterval(1.0))
        viewModel.handlePalmDetection(true, at: start.addingTimeInterval(3.0))

        XCTAssertEqual(viewModel.state, .countingDown(SelfieCaptureViewModel.countdownSeconds))
        viewModel.cancelCountdown()
    }

    func testCaptureProgressStatusText() {
        XCTAssertEqual(SelfieCaptureState.capturing(3, total: 10).statusText, "3/10")
    }
}
