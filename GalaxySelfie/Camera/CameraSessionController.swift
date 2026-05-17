import AVFoundation
import Foundation
import ImageIO

final class CameraSessionController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()

    @Published private(set) var authorizationState: CameraAuthorizationState = .notDetermined
    var onFrame: ((CameraFrame) -> Void)?

    func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await MainActor.run { authorizationState = .authorized }
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run { authorizationState = granted ? .authorized : .denied }
            return granted
        case .denied, .restricted:
            await MainActor.run { authorizationState = .denied }
            return false
        @unknown default:
            await MainActor.run { authorizationState = .denied }
            return false
        }
    }

    func configure() throws {
    }

    func start() {
    }

    func stop() {
    }
}

struct CameraFrame {
    var pixelBuffer: CVPixelBuffer
    var orientation: CGImagePropertyOrientation
}

enum CameraAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
}

enum CameraSessionError: Error, Equatable {
    case frontCameraUnavailable
    case cannotAddInput
    case cannotAddVideoOutput
    case cannotAddPhotoOutput
}
