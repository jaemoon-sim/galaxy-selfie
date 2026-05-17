import AVFoundation
import CoreMedia
import Foundation
import ImageIO
import QuartzCore

final class CameraSessionController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "galaxy-selfie.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "galaxy-selfie.camera.video-output")
    private var isConfigured = false
    private var lastFrameDeliveryTime: CFTimeInterval = 0
    private let minimumFrameInterval: CFTimeInterval = 0.12

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
        try sessionQueue.sync {
            guard !isConfigured else {
                return
            }

            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .front
            ) else {
                throw CameraSessionError.frontCameraUnavailable
            }

            let input = try AVCaptureDeviceInput(device: camera)

            session.beginConfiguration()
            session.sessionPreset = .photo
            defer { session.commitConfiguration() }

            guard session.canAddInput(input) else {
                throw CameraSessionError.cannotAddInput
            }
            session.addInput(input)

            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

            guard session.canAddOutput(videoOutput) else {
                throw CameraSessionError.cannotAddVideoOutput
            }
            session.addOutput(videoOutput)

            if let videoConnection = videoOutput.connection(with: .video) {
                videoConnection.automaticallyAdjustsVideoMirroring = false
                if videoConnection.isVideoMirroringSupported {
                    videoConnection.isVideoMirrored = true
                }
                if videoConnection.isVideoRotationAngleSupported(90) {
                    videoConnection.videoRotationAngle = 90
                }
            }

            guard session.canAddOutput(photoOutput) else {
                throw CameraSessionError.cannotAddPhotoOutput
            }
            session.addOutput(photoOutput)

            if let photoConnection = photoOutput.connection(with: .video) {
                photoConnection.automaticallyAdjustsVideoMirroring = false
                if photoConnection.isVideoMirroringSupported {
                    photoConnection.isVideoMirrored = true
                }
                if photoConnection.isVideoRotationAngleSupported(90) {
                    photoConnection.videoRotationAngle = 90
                }
            }

            isConfigured = true
        }
    }

    func start() {
        sessionQueue.async { [session] in
            guard !session.isRunning else {
                return
            }
            session.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            guard session.isRunning else {
                return
            }
            session.stopRunning()
        }
    }
}

extension CameraSessionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = CACurrentMediaTime()
        guard now - lastFrameDeliveryTime >= minimumFrameInterval else {
            return
        }
        lastFrameDeliveryTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        onFrame?(CameraFrame(pixelBuffer: pixelBuffer, orientation: .leftMirrored))
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
