import SwiftUI
import Photos
import UIKit
import AVKit
import os.log

// MARK: - SaveOptions 구조체
struct SaveOptions {
    var quality: CGFloat = 1.0
}

// MARK: - ImageEditView
struct ImageEditView: View {
    // MARK: Properties
    @State private var image: UIImage?
    @State private var processedImage: UIImage?
    @State private var videoURL: URL?
    @State private var player: AVPlayer?
    @State private var saveSuccess = false
    @State private var saveResultMessage = ""
    @State private var showingSaveResult = false
    @State private var isSaving = false
    
    let saveOptions = SaveOptions()
    
    // MARK: Body
    var body: some View {
        VStack {
            if let videoURL = videoURL {
                VideoPlayer(player: player)
                    .onAppear {
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                    }
            } else if let image = processedImage ?? image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            
            Button("저장") {
                checkPhotoLibraryPermission()
            }
            .disabled(isSaving)
        }
        .alert("저장 결과", isPresented: $showingSaveResult) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(saveResultMessage)
        }
    }
    
    // MARK: Initialization
    init(image: UIImage? = nil, videoURL: URL? = nil) {
        self._image = State(initialValue: image)
        self._videoURL = State(initialValue: videoURL)
        if let videoURL = videoURL {
            self._player = State(initialValue: AVPlayer(url: videoURL))
        }
    }
}

// MARK: - ImageEditView Extension
extension ImageEditView {
    /// 포토 라이브러리 권한 확인 및 요청
    private func checkPhotoLibraryPermission() {
        let writeStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if writeStatus == .notDetermined {
            // 권한 미결정인 경우 실제로 요청
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.performSave()
                    } else {
                        self.showSettingsAlert()
                    }
                }
            }
            return
        }
        
        switch writeStatus {
        case .authorized, .limited:
            performSave()
        case .denied, .restricted:
            showSettingsAlert()
        @unknown default:
            break
        }
    }
    
    /// 설정으로 이동 알림 표시
    private func showSettingsAlert() {
        let alert = UIAlertController(
            title: "권한 필요",
            message: "편집한 이미지를 갤러리에 저장하기 위해서는 사진 저장 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    /// 저장 실행 (비디오와 이미지 분기)
    private func performSave() {
        if videoURL != nil {
            saveVideo()
        } else {
            saveImage()
        }
    }
    
    /// 이미지 저장 함수
    private func saveImage() {
        guard let imageToSave = processedImage ?? image else {
            print("저장할 이미지가 없습니다.")
            return
        }
        guard let imageData = imageToSave.jpegData(compressionQuality: saveOptions.quality),
              let optimizedImage = UIImage(data: imageData) else {
            print("이미지 데이터를 생성할 수 없습니다.")
            saveSuccess = false
            saveResultMessage = "이미지 처리 중 오류가 발생했습니다."
            showingSaveResult = true
            return
        }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: optimizedImage)
        }) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("저장 오류: \(error.localizedDescription)")
                }
                self.saveSuccess = success
                self.saveResultMessage = success ? "이미지가 갤러리에 저장되었습니다." : (error?.localizedDescription ?? "저장 실패")
                self.showingSaveResult = true
            }
        }
    }

    
    /// 비디오 저장 함수
    private func saveVideo() {
        guard let player = player,
              let playerItem = player.currentItem,
              let videoComposition = playerItem.videoComposition else {
            saveSuccess = false
            saveResultMessage = "비디오 처리 중 오류가 발생했습니다."
            showingSaveResult = true
            return
        }
        isSaving = true
        player.pause()
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let outputURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        guard let asset = playerItem.asset as? AVURLAsset else {
            isSaving = false
            player.play()
            saveSuccess = false
            saveResultMessage = "비디오 에셋을 가져올 수 없습니다."
            showingSaveResult = true
            return
        }
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            isSaving = false
            player.play()
            saveSuccess = false
            saveResultMessage = "비디오 내보내기 세션을 생성할 수 없습니다."
            showingSaveResult = true
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition
        
        Task {
            do {
                try await exportSession.exportAsynchronously()
            } catch {
                DispatchQueue.main.async {
                    self.isSaving = false
                    self.player?.play()
                    self.saveSuccess = false
                    self.saveResultMessage = error.localizedDescription
                    self.showingSaveResult = true
                    try? FileManager.default.removeItem(at: outputURL)
                }
                return
            }
            
            await MainActor.run {
                switch exportSession.status {
                case .completed:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
                    }) { success, error in
                        try? FileManager.default.removeItem(at: outputURL)
                        DispatchQueue.main.async {
                            self.isSaving = false
                            self.player?.play()
                            self.saveSuccess = success
                            self.saveResultMessage = success ? "필터가 적용된 비디오가 갤러리에 저장되었습니다." : (error?.localizedDescription ?? "저장 실패")
                            self.showingSaveResult = true
                        }
                    }
                case .failed:
                    self.isSaving = false
                    self.player?.play()
                    self.saveSuccess = false
                    self.saveResultMessage = exportSession.error?.localizedDescription ?? "비디오 내보내기 실패"
                    self.showingSaveResult = true
                    try? FileManager.default.removeItem(at: outputURL)
                case .cancelled:
                    self.isSaving = false
                    self.player?.play()
                    self.saveSuccess = false
                    self.saveResultMessage = "비디오 내보내기가 취소되었습니다."
                    self.showingSaveResult = true
                    try? FileManager.default.removeItem(at: outputURL)
                default:
                    self.isSaving = false
                    self.player?.play()
                    break
                }
            }
        }
    }
}
