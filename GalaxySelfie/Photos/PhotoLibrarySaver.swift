import Foundation
import Photos

struct PhotoSaveResult: Equatable {
    var savedCount: Int
    var failedCount: Int
}

final class PhotoLibrarySaver {
    func requestAddOnlyAccess() async -> Bool {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return status == .authorized || status == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func save(photoData: [Data]) async -> PhotoSaveResult {
        var savedCount = 0
        var failedCount = 0

        for data in photoData {
            do {
                try await saveSinglePhoto(data)
                savedCount += 1
            } catch {
                failedCount += 1
            }
        }

        return PhotoSaveResult(savedCount: savedCount, failedCount: failedCount)
    }

    private func saveSinglePhoto(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: PhotoLibrarySaveError.saveFailed)
                }
            }
        }
    }
}

enum PhotoLibrarySaveError: Error, Equatable {
    case saveFailed
}
