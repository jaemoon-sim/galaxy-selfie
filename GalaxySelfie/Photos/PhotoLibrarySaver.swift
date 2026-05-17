import Foundation
import Photos

struct PhotoSaveResult: Equatable {
    var savedCount: Int
    var failedCount: Int
}

final class PhotoLibrarySaver {
    func requestAddOnlyAccess() async -> Bool {
        true
    }

    func save(photoData: [Data]) async -> PhotoSaveResult {
        PhotoSaveResult(savedCount: 0, failedCount: photoData.count)
    }
}
