// 카메라 기능 제어

import SwiftUI
import AVFoundation
import CoreImage

class CameraController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    // MARK: - 프로퍼티
    let previewView = UIView()
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput!
    var displayLayer: CALayer?
    
    @Published private(set) var isFilterApplied = false
    private var currentFilter: CubeManager.CubeFile?
    private var currentIntensity: Float = 1.0
    private var currentPosition: AVCaptureDevice.Position = .back
    private var completionHandler: ((String?) -> Void)?
    private var cubeManager: CubeManager
    private let filterProcessor = FilterProcessor()
    
    @Published private var currentFrame: UIImage?
    private var focusView: UIView?
    
    private let ciContext: CIContext
    private var colorCubeFilter: CIFilter?
    
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private let filterQueue = DispatchQueue(label: "com.heedam.filterQueue")
    
    var isGrainApplied = false
    var isMistApplied = false
    var grainIntensity: Float = 0.15
    var mistIntensity: Float = 0.5
    
    private var zoomFactor: CGFloat = 1.0
    // 기존 5.0에서 최대 줌 제한을 3배로 변경
    private var maxZoomFactor: CGFloat = 3.0
    private var pinchGestureRecognizer: UIPinchGestureRecognizer?
    
    // 프리뷰 초기화 여부 플래그 (실시간 프리뷰가 먼저 나오도록)
    @Published private(set) var isPreviewInitialized: Bool = false
    
    // MARK: - 초기화
    init(cubeManager: CubeManager) {
        self.cubeManager = cubeManager
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: metalDevice)
        } else {
            self.ciContext = CIContext(options: nil)
        }
        super.init()
        self.isFilterApplied = false
        self.colorCubeFilter = nil
        DispatchQueue.main.async { self.checkPermissions() }
    }
    
    // MARK: - 권한 확인 및 카메라 설정
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { self?.setupCamera() }
                }
            }
        default:
            break
        }
    }
    
    private func setupCamera() {
        if let existingSession = captureSession {
            existingSession.stopRunning()
            self.captureSession = nil
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else {
            print("카메라 디바이스를 찾을 수 없습니다.")
            session.commitConfiguration()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                print("카메라 입력을 추가할 수 없습니다.")
                session.commitConfiguration()
                return
            }
            session.addInput(input)
            
            photoOutput = AVCapturePhotoOutput()
            guard session.canAddOutput(photoOutput) else {
                print("사진 출력을 추가할 수 없습니다.")
                session.commitConfiguration()
                return
            }
            session.addOutput(photoOutput)
            
            if let connection = photoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }
                if connection.isVideoMirroringSupported { connection.isVideoMirrored = (currentPosition == .front) }
                if connection.isVideoStabilizationSupported { connection.preferredVideoStabilizationMode = .auto }
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            videoOutput.setSampleBufferDelegate(self, queue: filterQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            guard session.canAddOutput(videoOutput) else {
                print("비디오 출력을 추가할 수 없습니다.")
                session.commitConfiguration()
                return
            }
            session.addOutput(videoOutput)
            self.videoDataOutput = videoOutput
            
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }
                if connection.isVideoMirroringSupported { connection.isVideoMirrored = (currentPosition == .front) }
            }
            
            session.commitConfiguration()
            self.captureSession = session
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let layer = CALayer()
                layer.contentsGravity = .resizeAspectFill
                self.previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                self.previewView.layer.addSublayer(layer)
                layer.frame = self.previewView.bounds
                self.displayLayer = layer
                self.setupPinchGesture()
                DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
            }
        } catch {
            print("카메라 설정 중 에러 발생: \(error.localizedDescription)")
            session.commitConfiguration()
        }
    }
    
    // MARK: - 필터 적용 관련 메서드
    func applyFilter(_ filter: CubeManager.CubeFile, intensity: Float) {
        if filter.name.lowercased() == "normal" {
            currentFilter = nil
            currentIntensity = 1.0
            isFilterApplied = false
            colorCubeFilter = nil
            
            // 👉 실시간 프리뷰를 필터 없이 다시 그리기 위해 리셋 트리거
            DispatchQueue.main.async {
                self.previewView.setNeedsDisplay()
            }
            
            return
        }
        
        currentFilter = filter
        currentIntensity = intensity
        isFilterApplied = true
        
        if let cachedData = cubeManager.getCubeData(for: filter) {
            let size = cachedData.size
            let cubeDataSize = size * size * size * 4
            var rgbaData = [Float](repeating: 0, count: cubeDataSize)
            
            for i in 0..<(size * size * size) {
                let dataIndex = i * 3
                let rgbaIndex = i * 4
                let originalR = Float(i % size) / Float(size - 1)
                let originalG = Float((i / size) % size) / Float(size - 1)
                let originalB = Float(i / (size * size)) / Float(size - 1)
                
                rgbaData[rgbaIndex]     = cachedData.data[dataIndex] * intensity + originalR * (1 - intensity)
                rgbaData[rgbaIndex + 1] = cachedData.data[dataIndex + 1] * intensity + originalG * (1 - intensity)
                rgbaData[rgbaIndex + 2] = cachedData.data[dataIndex + 2] * intensity + originalB * (1 - intensity)
                rgbaData[rgbaIndex + 3] = 1.0
            }
            
            let colorCube = CIFilter(name: "CIColorCube")
            let data = Data(bytes: rgbaData, count: rgbaData.count * MemoryLayout<Float>.size)
            colorCube?.setValue(size, forKey: "inputCubeDimension")
            colorCube?.setValue(data, forKey: "inputCubeData")
            self.colorCubeFilter = colorCube
        } else {
            self.colorCubeFilter = nil
        }
    }
    
    private func applyColorCubeFilter(to inputImage: CIImage) -> CIImage {
        if isFilterApplied, let colorCubeFilter = colorCubeFilter {
            colorCubeFilter.setValue(inputImage, forKey: kCIInputImageKey)
            return colorCubeFilter.outputImage ?? inputImage
        }
        return inputImage
    }
    
    // MARK: - 카메라 제어 (전환, 초점, 줌)
    
    func updateZoomFactor(_ factor: CGFloat) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else { return }
        do {
            try device.lockForConfiguration()
            // 1.0 ~ maxZoomFactor(3.0) 사이로 줌 값 제한
            let clampedFactor = max(1.0, min(factor, self.maxZoomFactor))
            device.videoZoomFactor = clampedFactor
            zoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            print("Zoom 설정 에러: \(error)")
        }
    }
    
    func switchCamera() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.focusView?.removeFromSuperview()
            self.focusView = nil
            self.currentPosition = (self.currentPosition == .back) ? .front : .back
            self.setupCamera()
            // 카메라 전환 후 줌을 1.0으로 초기화
            self.updateZoomFactor(1.0)
        }
    }
    
    func focus(at point: CGPoint) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else { return }
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                let focusPoint = CGPoint(
                    x: point.y / previewView.bounds.height,
                    y: 1.0 - point.x / previewView.bounds.width
                )
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = .autoExpose
                }
                showFocusView(at: point)
            }
            device.unlockForConfiguration()
        } catch {
            print("초점 설정 에러: \(error)")
        }
    }
    
    private func showFocusView(at point: CGPoint) {
        focusView?.removeFromSuperview()
        let focusView = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        focusView.layer.borderWidth = 1.5
        focusView.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.8).cgColor
        focusView.backgroundColor = .clear
        let adjustedPoint = CGPoint(x: point.x, y: min(point.y + 30, previewView.bounds.height - 30))
        focusView.center = adjustedPoint
        //focusView.center = point
        focusView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        focusView.alpha = 1.0
        previewView.addSubview(focusView)
        self.focusView = focusView
        
        UIView.animate(withDuration: 0.3, animations: {
            focusView.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.5, options: [], animations: {
                focusView.alpha = 0.0
            }) { [weak self] _ in
                focusView.removeFromSuperview()
                if self?.focusView == focusView {
                    self?.focusView = nil
                }
            }
        }
    }
    
    private func setupPinchGesture() {
        if pinchGestureRecognizer == nil {
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
            previewView.addGestureRecognizer(pinch)
            pinchGestureRecognizer = pinch
        }
    }
    
    @objc private func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        // 핀치 제스처에서도 self.maxZoomFactor를 사용하여 최대 3배까지만 줌되도록 제한
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else { return }
        do {
            try device.lockForConfiguration()
            let newZoom = device.videoZoomFactor * pinch.scale
            let clampedZoom = max(1.0, min(newZoom, self.maxZoomFactor))
            device.videoZoomFactor = clampedZoom
            zoomFactor = clampedZoom
            device.unlockForConfiguration()
        } catch {
            print("Zoom 업데이트 에러: \(error)")
        }
        pinch.scale = 1.0
    }
    
    // MARK: - 필터 효과 (미스트, 그레인)
    private func applyMistEffect(to inputImage: CIImage) -> CIImage {
        var outputImage = inputImage
        if isMistApplied && mistIntensity > 0 {
            let mistFilter = CIFilter(name: "CIMotionBlur")!
            mistFilter.setValue(inputImage, forKey: kCIInputImageKey)
            mistFilter.setValue(22.5 * mistIntensity, forKey: kCIInputRadiusKey)
            mistFilter.setValue(45.0, forKey: "inputAngle")
            
            if let mistImage = mistFilter.outputImage?.cropped(to: inputImage.extent) {
                let alphaFilter = CIFilter(name: "CIColorMatrix")!
                alphaFilter.setValue(mistImage, forKey: kCIInputImageKey)
                alphaFilter.setDefaults()
                alphaFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
                alphaFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
                alphaFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
                alphaFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(mistIntensity) * 0.525), forKey: "inputAVector")
                
                if let transparentMist = alphaFilter.outputImage {
                    let blendFilter = CIFilter(name: "CISourceOverCompositing")!
                    blendFilter.setValue(transparentMist, forKey: kCIInputImageKey)
                    blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
                    
                    if let blendedImage = blendFilter.outputImage {
                        outputImage = blendedImage
                    }
                }
            }
        }
        return outputImage
    }
    
    private func applyGrainEffect(to inputImage: CIImage) -> CIImage {
        var outputImage = inputImage
        if isGrainApplied && grainIntensity > 0 {
            let noiseFilter = CIFilter(name: "CIRandomGenerator")!
            var noiseImage = noiseFilter.outputImage!.cropped(to: inputImage.extent)
            
            let scale = CGFloat(1.0 + (grainIntensity * 2.0))
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            noiseImage = noiseImage.transformed(by: scaleTransform).cropped(to: inputImage.extent)
            
            let monochromeFilter = CIFilter(name: "CIColorMonochrome")!
            monochromeFilter.setValue(noiseImage, forKey: kCIInputImageKey)
            monochromeFilter.setValue(CIColor.white, forKey: kCIInputColorKey)
            monochromeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
            
            if let monochromeNoise = monochromeFilter.outputImage {
                let brightnessFilter = CIFilter(name: "CIColorControls")!
                brightnessFilter.setValue(monochromeNoise, forKey: kCIInputImageKey)
                brightnessFilter.setValue(-0.01, forKey: kCIInputBrightnessKey)
                brightnessFilter.setValue(1.0, forKey: kCIInputContrastKey)
                
                if let adjustedNoise = brightnessFilter.outputImage {
                    let blendFilter = CIFilter(name: "CISoftLightBlendMode")!
                    blendFilter.setValue(adjustedNoise, forKey: kCIInputImageKey)
                    blendFilter.setValue(inputImage, forKey: kCIInputBackgroundImageKey)
                    
                    if let blendedImage = blendFilter.outputImage {
                        outputImage = blendedImage
                    }
                }
            }
        }
        return outputImage
    }
    
    // MARK: - 사진 촬영 및 저장
    func capturePhoto(completion: @escaping (String?) -> Void) {
        self.completionHandler = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func saveImageToTemporaryDirectory(image: UIImage) -> String? {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = "captured_photo_\(Date().timeIntervalSince1970).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try jpegData.write(to: fileURL, options: .atomic)
            return fileURL.path
        } catch {
            print("임시 디렉토리에 이미지 저장 실패: \(error)")
            return nil
        }
    }
    
    // MARK: - Intensity 업데이트
    func updateGrainIntensity(_ intensity: Float) {
        grainIntensity = intensity
    }
    
    func updateMistIntensity(_ intensity: Float) {
        mistIntensity = intensity
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate 구현
extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        autoreleasepool {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            
            // 전면 카메라인 경우 좌우 반전
            if currentPosition == .front {
                ciImage = ciImage.transformed(by: CGAffineTransform(scaleX: -1, y: 1))
            }
            
            // 원본 이미지(언필터) 생성: 빠른 프리뷰 업데이트용
            guard let rawCGImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
            let rawImage = UIImage(cgImage: rawCGImage)
            DispatchQueue.main.async { [weak self] in
                self?.currentFrame = rawImage
            }
            
            // 첫 프레임인 경우엔 필터 없이 즉시 화면에 표시
            if !isPreviewInitialized {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.displayLayer?.transform = (self.currentPosition == .front)
                    ? CATransform3DMakeScale(-1, 1, 1)
                    : CATransform3DIdentity
                    self.displayLayer?.contents = rawCGImage
                    CATransaction.commit()
                }
                // 프리뷰 초기화 완료 표시
                DispatchQueue.main.async { self.isPreviewInitialized = true }
                return
            }
            
            // 프리뷰가 이미 초기화된 이후엔 필터를 적용 (필요한 경우에만)
            var outputImage = ciImage
            if isFilterApplied, let _ = colorCubeFilter {
                outputImage = applyColorCubeFilter(to: outputImage)
            }
            if isMistApplied {
                outputImage = applyMistEffect(to: outputImage)
            }
            if isGrainApplied {
                outputImage = applyGrainEffect(to: outputImage)
            }
            
            // 최종 필터 처리 결과 생성 및 업데이트
            if let finalCGImage = ciContext.createCGImage(outputImage, from: outputImage.extent) {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.displayLayer?.transform = (self.currentPosition == .front)
                    ? CATransform3DMakeScale(-1, 1, 1)
                    : CATransform3DIdentity
                    self.displayLayer?.contents = finalCGImage
                    CATransaction.commit()
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate 구현
// UIImage extension 추가

extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}


// CameraController 내부의 photoOutput 수정
extension CameraController {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        autoreleasepool {
            if let error = error {
                print("사진 처리 중 에러 발생: \(error)")
                completionHandler?(nil)
                return
            }
            
            guard let imageData = photo.fileDataRepresentation() else {
                print("이미지 데이터 생성 실패")
                completionHandler?(nil)
                return
            }
            
            // 원래의 UIImage 생성 후 orientation 보정
            guard let uiImage = UIImage(data: imageData) else {
                print("UIImage 생성 실패")
                completionHandler?(nil)
                return
            }
            let fixedImage = uiImage.fixedOrientation()
            
            guard let ciImage = CIImage(image: fixedImage) else {
                print("CIImage 생성 실패")
                completionHandler?(nil)
                return
            }
            
            var outputImage: CIImage = ciImage
            outputImage = applyColorCubeFilter(to: outputImage)
            if isMistApplied { outputImage = applyMistEffect(to: outputImage) }
            outputImage = applyGrainEffect(to: outputImage)
            
            guard let finalCGImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
                print("CGImage 생성 실패")
                completionHandler?(nil)
                return
            }
            
            // 보정된 이미지를 기반으로 최종 이미지 생성 (한 번 더 보정)
            let processedImage = UIImage(cgImage: finalCGImage,
                                         scale: fixedImage.scale,
                                         orientation: fixedImage.imageOrientation)
                .fixedOrientation()
            
            if let filePath = saveImageToTemporaryDirectory(image: processedImage) {
                completionHandler?(filePath)
            } else {
                print("임시 디렉토리에 이미지 저장 실패")
                completionHandler?(nil)
            }
        }
    }
}
