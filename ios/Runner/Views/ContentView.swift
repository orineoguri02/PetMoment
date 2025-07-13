import SwiftUI
import PhotosUI
import AVKit

struct ContentView: View {
    @State private var selectedImage: UIImage?
    @State private var selectedVideoURL: URL?
    @State private var mediaType: ImagePicker.MediaType = .none
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingEditView = false
    @State private var showingPermissionAlert = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    var body: some View {
        NavigationView {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                } else if let videoURL = selectedVideoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(height: 400)
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("미디어를 선택해주세요")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        sourceType = .camera
                        checkCameraPermission()
                    }) {
                        Label("카메라", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: {
                        sourceType = .photoLibrary
                        checkAndRequestPermissions()
                    }) {
                        Label("갤러리", systemImage: "photo.fill.on.rectangle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Pet Moment")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, videoURL: $selectedVideoURL, mediaType: $mediaType)
                    .onDisappear {
                        if mediaType != .none {
                            showingEditView = true
                        }
                    }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CustomCameraView(image: $selectedImage, showingCamera: $showingCamera)
                    .onDisappear {
                        if selectedImage != nil {
                            mediaType = .image
                            showingEditView = true
                        }
                    }
            }
            .fullScreenCover(isPresented: $showingEditView) {
                if let image = selectedImage {
                    ImageEditView(image: image, videoURL: nil)
                } else if let videoURL = selectedVideoURL {
                    ImageEditView(image: nil, videoURL: videoURL)
                }
            }
            .alert("권한 필요", isPresented: $showingPermissionAlert) {
                Button("설정으로 이동") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("미디어 접근을 위해 권한이 필요합니다.")
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func checkAndRequestPermissions() {
        let readStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch readStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        self.showingImagePicker = true
                    } else {
                        self.showingPermissionAlert = true
                    }
                }
            }
        case .restricted, .denied:
            showingPermissionAlert = true
        case .authorized, .limited:
            showingImagePicker = true
        @unknown default:
            break
        }
    }
}
