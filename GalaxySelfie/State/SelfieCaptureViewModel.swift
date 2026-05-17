import Foundation

@MainActor
final class SelfieCaptureViewModel: ObservableObject {
    @Published private(set) var state: SelfieCaptureState = .idle

    var statusText: String {
        state.statusText
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
