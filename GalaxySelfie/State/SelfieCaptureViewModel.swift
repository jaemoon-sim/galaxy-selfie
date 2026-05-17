import Foundation

@MainActor
final class SelfieCaptureViewModel: ObservableObject {
    static let palmHoldDuration: TimeInterval = 1
    static let countdownSeconds = 5
    static let captureCount = 10

    @Published private(set) var state: SelfieCaptureState = .idle
    @Published private(set) var isPalmCurrentlyDetected = false

    var statusText: String {
        state.statusText
    }

    func handlePalmDetection(_ detected: Bool, at date: Date = Date()) {
        isPalmCurrentlyDetected = detected
    }

    func cancelCountdown() {
        state = .idle
    }
}

enum SelfieCaptureState: Equatable {
    case idle
    case detectingPalm
    case countingDown(Int)
    case capturing(Int, total: Int)
    case saving
    case completed(savedCount: Int)
    case failed(String)

    var statusText: String {
        switch self {
        case .idle:
            return "Show your palm to start"
        case .detectingPalm:
            return "Palm detected"
        case let .countingDown(seconds):
            return "\(seconds)"
        case let .capturing(current, total):
            return "\(current)/\(total)"
        case .saving:
            return "Saving"
        case let .completed(savedCount):
            return "Saved \(savedCount) photos"
        case let .failed(message):
            return message
        }
    }
}
