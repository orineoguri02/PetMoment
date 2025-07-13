import UIKit
import Photos

class ImageSaver: NSObject {
    func saveImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        // 권한 체크 먼저 수행
        if PHPhotoLibrary.authorizationStatus(for: .addOnly) == .authorized {
            // 권한이 있으면 바로 저장
            saveToGallery(image, completion: completion)
        } else {
            // 권한 요청
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    self.saveToGallery(image, completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            }
        }
    }
    
    private func saveToGallery(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
} 