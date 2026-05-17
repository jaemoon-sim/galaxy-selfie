import AVFoundation
import Foundation

struct CapturedPhotoBatch {
    var photoData: [Data]
    var failures: [Error]
}

final class PhotoCaptureCoordinator: NSObject {
    func captureBatch(count: Int, using output: AVCapturePhotoOutput) async -> CapturedPhotoBatch {
        CapturedPhotoBatch(photoData: [], failures: [])
    }
}
