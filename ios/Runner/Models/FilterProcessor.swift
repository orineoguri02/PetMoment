import CoreImage
import UIKit

class FilterProcessor {
    private let context: CIContext
    
    init() {
        // Metal 가속을 사용하도록 설정
        let options: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ]
        context = CIContext(options: options)
    }
    
    func apply(to image: UIImage, with cubeData: [Float], size: Int, intensity: Float = 1.0) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            return nil
        }
        
        // RGBA 데이터로 변환 - 단순화된 버전
        let cubeDataSize = size * size * size * 4
        var rgbaData = [Float](repeating: 0, count: cubeDataSize)
        
        for i in 0..<(size * size * size) {
            let dataIndex = i * 3
            let rgbaIndex = i * 4
            
            // 원본 색상 계산
            let originalR = Float(i % size) / Float(size - 1)
            let originalG = Float((i / size) % size) / Float(size - 1)
            let originalB = Float(i / (size * size)) / Float(size - 1)
            
            // 보간된 색상 계산
            let r = cubeData[dataIndex] * intensity + originalR * (1 - intensity)
            let g = cubeData[dataIndex + 1] * intensity + originalG * (1 - intensity)
            let b = cubeData[dataIndex + 2] * intensity + originalB * (1 - intensity)
            
            rgbaData[rgbaIndex] = r
            rgbaData[rgbaIndex + 1] = g
            rgbaData[rgbaIndex + 2] = b
            rgbaData[rgbaIndex + 3] = 1.0
        }
        
        let data = Data(bytes: rgbaData, count: rgbaData.count * MemoryLayout<Float>.size)
        
        guard let cubeFilter = CIFilter(name: "CIColorCube") else {
            return nil
        }
        
        cubeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        cubeFilter.setValue(size, forKey: "inputCubeDimension")
        cubeFilter.setValue(data, forKey: "inputCubeData")
        
        guard let outputImage = cubeFilter.outputImage else {
            return nil
        }
        
        let outputRect = outputImage.extent
        let scale = UIScreen.main.scale
        
        guard let cgImage = context.createCGImage(outputImage, from: outputRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
    }
    
    func applyGrain(to image: UIImage, intensity: Float = 0.15) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // 노이즈 필터 생성
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else { return nil }
        guard var noiseImage = noiseFilter.outputImage else { return nil }
        
        // 노이즈 크기 조절을 위한 스케일 변환
        let scale = CGFloat(1.0 + (intensity * 2.0)) // intensity가 0일 때 1.0(작은 노이즈), 1일 때 3.0(큰 노이즈)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        noiseImage = noiseImage.transformed(by: scaleTransform)
        
        // 노이즈 이미지를 원본 이미지 크기로 크롭
        noiseImage = noiseImage.cropped(to: ciImage.extent)
        
        // 노이즈를 흑백으로 변환
        guard let monochromeFilter = CIFilter(name: "CIColorMonochrome") else { return nil }
        monochromeFilter.setValue(noiseImage, forKey: kCIInputImageKey)
        monochromeFilter.setValue(CIColor.white, forKey: kCIInputColorKey)
        monochromeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        guard let monochromeNoise = monochromeFilter.outputImage else { return nil }
        
        // 노이즈 강도 조절을 위한 필터 (고정된 값 사용)
        guard let colorControl = CIFilter(name: "CIColorControls") else { return nil }
        colorControl.setValue(monochromeNoise, forKey: kCIInputImageKey)
        colorControl.setValue(0.0, forKey: kCIInputBrightnessKey)
        colorControl.setValue(0.8, forKey: kCIInputContrastKey)
        guard let adjustedNoise = colorControl.outputImage else { return nil }
        
        // 블렌드 필터로 원본 이미지와 노이즈를 합성
        guard let blendFilter = CIFilter(name: "CISoftLightBlendMode") else { return nil }
        blendFilter.setValue(adjustedNoise, forKey: kCIInputImageKey)
        blendFilter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        
        guard let outputImage = blendFilter.outputImage else { return nil }
        
        // 최종 밝기 조절 (고정된 값 사용)
        guard let brightnessFilter = CIFilter(name: "CIColorControls") else { return nil }
        brightnessFilter.setValue(outputImage, forKey: kCIInputImageKey)
        brightnessFilter.setValue(-0.01, forKey: kCIInputBrightnessKey)  // 밝기 고정
        brightnessFilter.setValue(1.0, forKey: kCIInputContrastKey)      // 대비 고정
        
        guard let finalImage = brightnessFilter.outputImage else { return nil }
        
        // 최종 이미지 생성
        let outputRect = finalImage.extent
        guard let cgImage = context.createCGImage(finalImage, from: outputRect) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    func applyMist(to image: UIImage, intensity: Float = 0.5) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let originalExtent = ciImage.extent
        
        // 이미지 크기에 따른 블러 강도 조정
        let baseRadius: Float = 10.0
        let sizeFactor = Float(max(originalExtent.width, originalExtent.height) / 1000.0)
        let adjustedRadius = baseRadius * max(1.0, sizeFactor)
        
        // 방향성 블러를 위한 설정
        let directions: [(angle: Float, weight: Float)] = [
            (45.0, 0.6),   // 동남
            (135.0, 0.6),  // 남서
            (225.0, 0.6),  // 북서
            (315.0, 0.6)   // 북동
        ]
        
        var accumulator = ciImage
        
        // 각 방향으로 모션 블러 적용 (강도에 따라 조절)
        for (angle, weight) in directions {
            guard let motionBlur = CIFilter(name: "CIMotionBlur") else { continue }
            motionBlur.setValue(accumulator, forKey: kCIInputImageKey)
            motionBlur.setValue(intensity * adjustedRadius * weight, forKey: kCIInputRadiusKey)
            motionBlur.setValue(angle, forKey: "inputAngle")
            
            guard let blurredImage = motionBlur.outputImage?.cropped(to: originalExtent) else { continue }
            
            // 블러 이미지를 더 투명하게 블렌드
            guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else { continue }
            
            // 블러 이미지의 불투명도를 낮춤 (강도에 따라 조절)
            let alphaFilter = CIFilter(name: "CIColorMatrix")
            alphaFilter?.setValue(blurredImage, forKey: kCIInputImageKey)
            alphaFilter?.setDefaults()
            alphaFilter?.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
            alphaFilter?.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
            alphaFilter?.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
            alphaFilter?.setValue(CIVector(x: 0, y: 0, z: 0, w: CGFloat(intensity) * 0.35), forKey: "inputAVector")
            
            guard let transparentBlur = alphaFilter?.outputImage?.cropped(to: originalExtent) else { continue }
            
            blendFilter.setValue(transparentBlur, forKey: kCIInputImageKey)
            blendFilter.setValue(accumulator, forKey: kCIInputBackgroundImageKey)
            
            if let blended = blendFilter.outputImage?.cropped(to: originalExtent) {
                accumulator = blended
            }
        }
        
        // 최종 블렌드 조정
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        blendFilter.setValue(accumulator, forKey: kCIInputImageKey)
        blendFilter.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        
        guard let outputImage = blendFilter.outputImage?.cropped(to: originalExtent) else { return nil }
        
        // 밝기와 대비 조정 (강도에 따라 조절)
        guard let brightnessFilter = CIFilter(name: "CIColorControls") else { return nil }
        brightnessFilter.setValue(outputImage, forKey: kCIInputImageKey)
        brightnessFilter.setValue(0.03 * intensity, forKey: kCIInputBrightnessKey)
        brightnessFilter.setValue(1.0 + (intensity * 0.05), forKey: kCIInputContrastKey)
        
        guard let finalImage = brightnessFilter.outputImage?.cropped(to: originalExtent) else { return nil }
        
        // 최종 이미지 생성
        guard let cgImage = context.createCGImage(finalImage, from: originalExtent) else { return nil }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    func apply(to ciImage: CIImage, with filter: CubeManager.CubeFile, intensity: Float) -> CIImage? {
        guard let cachedData = filter.getCubeData() else { return nil }
        
        // CIColorCube 필터 설정
        guard let colorCube = CIFilter(name: "CIColorCube") else { return nil }
        colorCube.setValue(ciImage, forKey: kCIInputImageKey)
        colorCube.setValue(cachedData.size, forKey: "inputCubeDimension")
        
        // RGBA 데이터 생성 - intensity 적용
        let size = cachedData.size
        let cubeDataSize = size * size * size * 4
        var rgbaData = [Float](repeating: 0, count: cubeDataSize)
        
        let totalSize = Int(size * size * size)
        
        for i in 0..<totalSize {
            let dataIndex = i * 3
            let rgbaIndex = i * 4
            
            // 원본 색상 계산
            let originalR = Float(i % size) / Float(size - 1)
            let originalG = Float((i / size) % size) / Float(size - 1)
            let originalB = Float(i / (size * size)) / Float(size - 1)
            
            // 보간된 색상 계산 - intensity 적용
            rgbaData[rgbaIndex] = cachedData.data[dataIndex] * intensity + originalR * (1 - intensity)
            rgbaData[rgbaIndex + 1] = cachedData.data[dataIndex + 1] * intensity + originalG * (1 - intensity)
            rgbaData[rgbaIndex + 2] = cachedData.data[dataIndex + 2] * intensity + originalB * (1 - intensity)
            rgbaData[rgbaIndex + 3] = 1.0
        }
        
        let data = Data(bytes: rgbaData, count: rgbaData.count * MemoryLayout<Float>.size)
        colorCube.setValue(data, forKey: "inputCubeData")
        
        return colorCube.outputImage
    }
} 
