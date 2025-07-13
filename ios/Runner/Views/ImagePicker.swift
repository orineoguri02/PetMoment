// 갤러리에서 사진을 선택했을 때

import SwiftUI
import PhotosUI
import AVKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var videoURL: URL?
    @Binding var mediaType: MediaType
    
    enum MediaType {
        case image
        case video
        case none
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        // 이미지와 비디오 모두 선택 가능하도록 설정
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else {
                return
            }
            
            // 이미지 처리
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self?.parent.image = image
                            self?.parent.mediaType = .image
                            self?.parent.videoURL = nil
                        }
                    }
                }
            }
            // 비디오 처리
            else if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    if let error = error {
                        print("Error loading video: \(error)")
                        return
                    }
                    
                    guard let url = url else { return }
                    
                    // 임시 URL에서 앱의 documents 디렉토리로 비디오 파일 복사
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let uniqueFileName = "video_\(UUID().uuidString).mov"
                    let destinationURL = documentsDirectory.appendingPathComponent(uniqueFileName)
                    
                    do {
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }
                        try FileManager.default.copyItem(at: url, to: destinationURL)
                        
                        DispatchQueue.main.async {
                            self?.parent.videoURL = destinationURL
                            self?.parent.mediaType = .video
                            self?.parent.image = nil
                        }
                    } catch {
                        print("Error copying video file: \(error)")
                    }
                }
            }
        }
    }
} 
