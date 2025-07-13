// 카메라의 전체적인 화면 UI

import SwiftUI
import AVFoundation
import Photos

struct CustomCameraView: View {
    @Binding var image: UIImage?
    @Binding var showingCamera: Bool
    @EnvironmentObject private var cubeManager: CubeManager
    
    @StateObject private var camera: CameraController
    @State private var currentFilter: CubeManager.CubeFile?
    @State private var filterIntensity: Float = 0.75
    
    @State private var isGrainApplied = false
    @State private var isMistApplied = false
    @State private var grainIntensity: Float = 0.15
    @State private var mistIntensity: Float = 0.5
    @State private var showGrainSlider = false
    @State private var showMistSlider = false
    
    @State private var showingPreview = false
    @State private var capturedImage: UIImage?
    @State private var hasUserSelectedFilter = false // 필터를 눌렀는지에 대한 bool 값
    
    @State private var customred = Color(UIColor.systemRed)
    private let customRed: Color = Color(hex: "E94A39")
    @State private var galleryPreviewImage: UIImage? = nil
    
    @State private var isPreviewActive = false // 프리뷰가 안정적으로 실행되었는지 여부를 나타내는 변수
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showToast = false
    @State private var toastMessage = ""    // 스낵바
    
    
    var onPhotoCaptured: (String) -> Void = { _ in }
    
    init(image: Binding<UIImage?>, showingCamera: Binding<Bool>, onPhotoCaptured: @escaping (String) -> Void = { _ in }) {
        _image = image
        _showingCamera = showingCamera
        _camera = StateObject(wrappedValue: CameraController(cubeManager: CubeManager.shared))
        self.onPhotoCaptured = onPhotoCaptured
    }
    
    var body: some View {
        GeometryReader { geometry in
            Image("gradient")
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .ignoresSafeArea(.all)
            // 카메라 UI
            VStack(spacing: 0) {
                
                GeometryReader { geometry in
                    let verticalPadding = geometry.size.height * 0.08
                    
                    ZStack(alignment: .trailing) {
                        CameraPreviewView(
                            camera: camera,
                            showingPreview: $showingPreview,
                            capturedImage: $capturedImage
                        )
                        .frame(height: geometry.size.width * (4.0/3.0))
                        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                        .edgesIgnoringSafeArea(.all)
                        .padding(.vertical, verticalPadding)
                        
                        if currentFilter?.name != "normal" && hasUserSelectedFilter {
                            FilterIntensitySlider(
                                value: $filterIntensity,
                                range: 0...1.5
                            ) { editing in
                                if !editing, let filter = currentFilter {
                                    camera.applyFilter(filter, intensity: filterIntensity)
                                }
                            }
                            .frame(width: 280)
                            .padding(.trailing, -120)
                            .onTapGesture(count: 2) {
                                filterIntensity = 0.75
                                if let filter = currentFilter {
                                    camera.applyFilter(filter, intensity: filterIntensity)
                                }
                            } // onTapGesture
                            .transition(.opacity)
                        } // if
                    } // ZStack
                } // GeometryReader
                .padding(.horizontal, 15)
                
                
                
                if isPreviewActive {
                    Spacer()
                    //Spacer(minLength: 20)
                    filterSelectionView.frame(height: 90)
                    Spacer(minLength: 25)
                } // if
                
                CameraControlsView(
                    showingCamera: $showingCamera,
                    onCapture: {
                        camera.capturePhoto { filePath in
                            if let image = UIImage(contentsOfFile: filePath ?? "") {
                                capturedImage = image
                                showingPreview = true
                            }
                            onPhotoCaptured(filePath ?? "")
                        }
                    },
                    onSwitchCamera: {
                        cubeManager.clearThumbnailCache()
                        camera.switchCamera()
                    },
                    customRed: customRed,
                    galleryImage: galleryPreviewImage,
                    onGalleryPhotoSelected: { selectedImage in
                        capturedImage = selectedImage
                        showingPreview = true
                    }
                ) // CameraControlsView
            } // VStack
            .ignoresSafeArea(.keyboard)
            .background(Color.clear)
            
            // PhotoPreviewView를 오버레이로 추가 (capturedImage가 있고 showingPreview가 true일 때)
            if showingPreview, let image = capturedImage {
                PhotoPreviewView(
                    image: image,
                    isPresented: $showingPreview,
                    onSave: { savedImage, uploadSuccess in
                        self.image = savedImage
                        UIImageWriteToSavedPhotosAlbum(savedImage, nil, nil, nil)
                        
                        if uploadSuccess {
                            showCustomToast(message: "기록이 저장되었습니다.")
                        }
                    },
                    showCamera: $showingCamera
                )
                .transition(.opacity)
            } // if
            toastView
        } // ZStack
        
        .overlay(alignment: .topLeading) {
            Button(action: {
                // 사진 데이터 전달 없이 단순히 미리보기와 카메라 화면 종료
                capturedImage = nil
                showingPreview = false
                presentationMode.wrappedValue.dismiss()
                showingCamera = false
            }) {
                Image(systemName: "chevron.left")
                    .frame(width: 15, height: 25)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
            } // Button
            .padding(.leading, 30)
        } // overlay
        
        .onAppear {
            camera.checkPermissions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isPreviewActive = true
                }
            }
            fetchLatestGalleryImage()
        } // onAppear
    }
    
    private var topOverlay: some View {
        ZStack{
            HStack {
                Spacer()
                if isPreviewActive {
                    HStack(spacing: 20) {
                        Button(action: {
                            camera.isGrainApplied.toggle()
                            isGrainApplied.toggle()
                            showGrainSlider = isGrainApplied
                            if !isGrainApplied {
                                grainIntensity = 0.15
                                camera.updateGrainIntensity(0.15)
                            } else {
                                camera.updateGrainIntensity(grainIntensity)
                            }
                        }) {
                            Image(systemName: "circle.dotted")
                                .foregroundColor(isGrainApplied ? .red : .gray)
                                .font(.system(size: 22))
                                .offset(y: -1)
                        } // Button
                        
                        if showGrainSlider {
                            Slider(value: Binding(
                                get: { self.grainIntensity },
                                set: { newValue in
                                    self.grainIntensity = newValue
                                    camera.updateGrainIntensity(newValue)
                                }
                            ), in: 0.0...1.0)
                            .frame(width: 100)
                            .tint(.red)
                        } // showGrainSlider
                        
                        Button(action: {
                            camera.isMistApplied.toggle()
                            isMistApplied.toggle()
                            showMistSlider = isMistApplied
                            if !isMistApplied {
                                mistIntensity = 0.5
                                camera.updateMistIntensity(0.5)
                            } else {
                                camera.updateMistIntensity(mistIntensity)
                            }
                        }) {
                            Image(systemName: "sparkles")
                                .foregroundColor(isMistApplied ? .red : .gray)
                                .font(.system(size: 22))
                                .offset(y: -2)
                        } // Button
                        
                        if showMistSlider {
                            Slider(value: Binding(
                                get: { self.mistIntensity },
                                set: { newValue in
                                    self.mistIntensity = newValue
                                    camera.updateMistIntensity(newValue)
                                }
                            ), in: 0.0...1.0)
                            .frame(width: 100)
                            .tint(.red)
                        } // showMistSlider
                    } // HStack
                    .frame(height: 44)
                    .padding(.horizontal, -12)
                } // isPreviewActive
            } // HStack
            .frame(maxWidth: .infinity, maxHeight: 44)
            .background(Color.clear)
        }
    }
    
    private func onFilterSelected(_ filter: CubeManager.CubeFile) {
        currentFilter = filter
        hasUserSelectedFilter = true
    }
    
    // 필터 종류에 따른 자동 효과 적용 함수
    private func applyAutoEffectsForFilter(_ filter: CubeManager.CubeFile) {
        // 필터 이름에 따라 처리
        if filter.name.contains("film") {
            // film 필터에는 그레인 효과 적용
            camera.isGrainApplied = true
            isGrainApplied = true
            grainIntensity = 0.05  // 그레인 강도 기본값
            camera.updateGrainIntensity(0.05)
            showGrainSlider = true
            
            // film 필터에는 미스트 효과 비활성화
            camera.isMistApplied = false
            isMistApplied = false
            showMistSlider = false
            camera.updateMistIntensity(0.5)  // 기본값으로 초기화
        }
        else if filter.name.contains("mood") {
            // mood 필터에는 미스트 효과 적용
            camera.isMistApplied = true
            isMistApplied = true
            mistIntensity = 0.5  // 미스트 강도 기본값
            camera.updateMistIntensity(0.5)
            showMistSlider = true
            
            // mood 필터에는 그레인 효과 비활성화
            camera.isGrainApplied = false
            isGrainApplied = false
            showGrainSlider = false
            camera.updateGrainIntensity(0.05)  // 기본값으로 초기화
        }
        else if filter.name == "daily1" {
            // daily1 필터에는 약한 그레인 효과 적용
            camera.isGrainApplied = true
            isGrainApplied = true
            grainIntensity = 0.03  // 약한 그레인 강도
            camera.updateGrainIntensity(0.03)
            showGrainSlider = true
            
            // daily1 필터에는 매우 약한 미스트 효과도 적용
            camera.isMistApplied = true
            isMistApplied = true
            mistIntensity = 0.2  // 약한 미스트 강도
            camera.updateMistIntensity(0.2)
            showMistSlider = true
        }
        else if filter.name == "daily2" {
            // daily2 필터에는 미스트만 적용 (그레인 없음)
            camera.isGrainApplied = false
            isGrainApplied = false
            showGrainSlider = false
            camera.updateGrainIntensity(0.05)  // 기본값으로 초기화
            
            // daily2 필터에는 중간 강도의 미스트 효과 적용
            camera.isMistApplied = true
            isMistApplied = true
            mistIntensity = 0.35  // 중간 강도의 미스트
            camera.updateMistIntensity(0.35)
            showMistSlider = true
        }
        else if filter.name == "normal" {
            // normal 필터에는 모든 효과 비활성화
            camera.isGrainApplied = false
            isGrainApplied = false
            showGrainSlider = false
            camera.updateGrainIntensity(0.05)  // 기본값으로 초기화
            
            camera.isMistApplied = false
            isMistApplied = false
            showMistSlider = false
            camera.updateMistIntensity(0.5)  // 기본값으로 초기화
        }
    }
    
    private var filterSelectionView: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollProxy in
                HStack(spacing: 10) {
                    // 모든 필터를 동일한 ForEach로 처리
                    ForEach(cubeManager.getAllFilters()) { filter in
                        FilterButton(
                            filter: filter,
                            previewImage: createPreview(for: filter),
                            action: {
                                if isPreviewActive {
                                    // 필터가 변경되었을 때만 처리
                                    if currentFilter?.id != filter.id {
                                        // normal 필터인 경우 강도 설정
                                        if filter.name == "normal" {
                                            filterIntensity = 1.0
                                        }
                                        
                                        // 필터에 따른 자동 효과 적용
                                        applyAutoEffectsForFilter(filter)
                                    }
                                    camera.applyFilter(filter, intensity: filterIntensity)
                                    onFilterSelected(filter)
                                    currentFilter = filter
                                    withAnimation(.spring(response: 1.8, dampingFraction: 0.7)) {
                                        scrollProxy.scrollTo(filter.name, anchor: .center)
                                    }
                                }
                            },
                            isSelected: currentFilter?.id == filter.id
                        ) // FilterButton
                        .id(filter.name)
                    } // ForEach
                } // HStack
            } // ScrollViewReader
        } // ScrollView
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Color.clear)
    }
    
    
    private func createPreview(for filter: CubeManager.CubeFile) -> UIImage? {
        if let thumbnailName = filter.thumbnailImageName {
            return UIImage(named: thumbnailName)
        }
        return nil
    }
    
    private func fetchLatestGalleryImage() {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized || status == .limited {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            options.fetchLimit = 1
            let result = PHAsset.fetchAssets(with: .image, options: options)
            guard let asset = result.firstObject else { return }
            
            let manager = PHImageManager.default()
            let targetSize = CGSize(width: 100, height: 100)
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            
            manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: requestOptions) { image, _ in
                if let image = image {
                    DispatchQueue.main.async {
                        self.galleryPreviewImage = image
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    fetchLatestGalleryImage()
                }
            }
        }
    }
    
    private var toastView: some View {
        VStack {
            Spacer()
            if showToast {
                Text(toastMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: toastMessage.contains("e") ? 62 : 25)
                    .padding()
                    .background(Color(hex: "212121"))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showToast)
    }

    private func showCustomToast(message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showToast = false
            }
        }
    }
}
