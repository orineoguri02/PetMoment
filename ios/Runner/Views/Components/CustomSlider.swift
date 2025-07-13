// 필터 강도 슬라이더 기능, 커스텀

import SwiftUI
import UIKit

// UISlider의 터치 영역을 확장하는 커스텀 서브클래스
class ExtendedTouchSlider: UISlider {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 터치 영역을 확장 (상하좌우 각각 20포인트)
        let bounds = self.bounds.insetBy(dx: -20.0, dy: -20.0)
        if bounds.contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
    
    // 더 큰 Thumb 이미지 생성하지만 시각적으로는 작게 보이도록
    func setupThumb() {
        let thumbSize = CGSize(width: 30, height: 30) // 더 큰 크기로 변경
        let renderer = UIGraphicsImageRenderer(size: thumbSize)
        let thumbImage = renderer.image { context in
            // 원의 중앙에 위치하도록 계산
            let circleRect = CGRect(x: 5, y: 5, width: 20, height: 20)
            
            // 흰색 원 그리기
            UIColor.white.setFill()
            let circlePath = UIBezierPath(ovalIn: circleRect)
            circlePath.fill()
            
            // 테두리 그리기 (#98CAFF)
            UIColor(red: 152/255, green: 202/255, blue: 255/255, alpha: 1.0).setStroke()
            context.cgContext.setLineWidth(1)
            circlePath.stroke()
        }
        
        setThumbImage(thumbImage, for: .normal)
    }
}

struct CustomSlider: UIViewRepresentable {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let onEditingChanged: (Bool) -> Void
    let defaultValue: Float
    let onReset: (() -> Void)?  // 리셋 콜백 추가
    
    init(value: Binding<Float>, range: ClosedRange<Float>, defaultValue: Float = 0.75, onReset: (() -> Void)? = nil, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self._value = value
        self.range = range
        self.defaultValue = defaultValue
        self.onReset = onReset
        self.onEditingChanged = onEditingChanged
    }
    
    func makeUIView(context: Context) -> ExtendedTouchSlider {
        let slider = ExtendedTouchSlider()
        slider.minimumValue = range.lowerBound
        slider.maximumValue = range.upperBound
        slider.value = value
        
        // 배경 투명하게 설정
        slider.backgroundColor = .clear
        
        // 트랙 설정
        slider.minimumTrackTintColor = .systemBlue
        slider.maximumTrackTintColor = .white  // 흰색으로 변경
        
        // 슬라이더의 모든 서브뷰도 투명 배경으로 설정
        slider.subviews.forEach { subview in
            subview.backgroundColor = .clear
            // UISlider의 트랙 뷰 찾아서 배경 투명하게 설정
            if subview is UIImageView {
                subview.backgroundColor = .clear
                subview.tintColor = .clear
            }
        }
        
        // Thumb 이미지 설정
        slider.setupThumb()
        
        // 더블 탭 제스처 추가
        let doubleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delaysTouchesBegan = true
        slider.addGestureRecognizer(doubleTapGesture)
        
        // 슬라이더 이벤트 설정
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        
        return slider
    }
    
    func updateUIView(_ uiView: ExtendedTouchSlider, context: Context) {
        // 반올림 코드 제거
        uiView.value = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, defaultValue: defaultValue, onReset: onReset, onEditingChanged: onEditingChanged)
    }
    
    class Coordinator: NSObject {
        let onEditingChanged: (Bool) -> Void
        let defaultValue: Float
        let onReset: (() -> Void)?
        @Binding var value: Float
        
        init(value: Binding<Float>, defaultValue: Float, onReset: (() -> Void)?, onEditingChanged: @escaping (Bool) -> Void) {
            self._value = value
            self.defaultValue = defaultValue
            self.onReset = onReset
            self.onEditingChanged = onEditingChanged
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            // 반올림 코드 제거
            value = sender.value
            onEditingChanged(sender.isTracking)
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let slider = gesture.view as? UISlider else { return }
            
            let location = gesture.location(in: slider)
            let thumbRect = slider.thumbRect(forBounds: slider.bounds, trackRect: slider.trackRect(forBounds: slider.bounds), value: slider.value)
            
            // thumb 영역을 더 크게 확장
            let expandedThumbRect = CGRect(
                x: thumbRect.origin.x - 40,  // 30에서 40으로 확장
                y: thumbRect.origin.y - 40,  // 30에서 40으로 확장
                width: thumbRect.width + 80, // 60에서 80으로 확장
                height: thumbRect.height + 80 // 60에서 80으로 확장
            )
            
            if expandedThumbRect.contains(location) {
                value = defaultValue
                slider.setValue(defaultValue, animated: true)
                onEditingChanged(true)
                onEditingChanged(false)
                onReset?()
            }
        }
    }
}
