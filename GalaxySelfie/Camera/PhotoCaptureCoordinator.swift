import AVFoundation
import Foundation

struct CapturedPhotoBatch {
    var photoData: [Data]
    var failures: [Error]
}

final class PhotoCaptureCoordinator: NSObject {
    private let delegateLock = NSLock()
    private var delegates: [UUID: SinglePhotoCaptureDelegate] = [:]

    func captureBatch(
        count: Int,
        using output: AVCapturePhotoOutput,
        progress: ((Int) -> Void)? = nil
    ) async -> CapturedPhotoBatch {
        guard count > 0 else {
            return CapturedPhotoBatch(photoData: [], failures: [])
        }

        var photoData: [Data] = []
        var failures: [Error] = []

        for index in 0..<count {
            do {
                let data = try await capturePhoto(using: output)
                photoData.append(data)
            } catch {
                failures.append(error)
            }

            progress?(index + 1)

            if index < count - 1 {
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
        }

        return CapturedPhotoBatch(photoData: photoData, failures: failures)
    }

    private func capturePhoto(using output: AVCapturePhotoOutput) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let id = UUID()
            let delegate = SinglePhotoCaptureDelegate { [weak self] result in
                self?.removeDelegate(id)
                continuation.resume(with: result)
            }

            storeDelegate(delegate, id: id)

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            if output.maxPhotoQualityPrioritization.rawValue >= AVCapturePhotoOutput.QualityPrioritization.speed.rawValue {
                settings.photoQualityPrioritization = .speed
            }

            output.capturePhoto(with: settings, delegate: delegate)
        }
    }

    private func storeDelegate(_ delegate: SinglePhotoCaptureDelegate, id: UUID) {
        delegateLock.lock()
        delegates[id] = delegate
        delegateLock.unlock()
    }

    private func removeDelegate(_ id: UUID) {
        delegateLock.lock()
        delegates[id] = nil
        delegateLock.unlock()
    }
}

private final class SinglePhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<Data, Error>) -> Void
    private var completed = false
    private var data: Data?

    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            finish(.failure(error))
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            finish(.failure(PhotoCaptureError.missingPhotoData))
            return
        }

        self.data = data
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
        error: Error?
    ) {
        if let error {
            finish(.failure(error))
            return
        }

        guard let data else {
            finish(.failure(PhotoCaptureError.missingPhotoData))
            return
        }

        finish(.success(data))
    }

    private func finish(_ result: Result<Data, Error>) {
        guard !completed else {
            return
        }
        completed = true
        completion(result)
    }
}

enum PhotoCaptureError: Error, Equatable {
    case missingPhotoData
}
