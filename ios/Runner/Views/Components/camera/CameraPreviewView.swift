// 카메라 사진 캡쳐 기능들

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let camera: CameraController
    @Binding var showingPreview: Bool
    @Binding var capturedImage: UIImage?
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.systemBackground
        
        camera.previewView.backgroundColor = .black
        camera.previewView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(camera.previewView)
        
        NSLayoutConstraint.activate([
            camera.previewView.topAnchor.constraint(equalTo: containerView.topAnchor),
            camera.previewView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            camera.previewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            camera.previewView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // 탭 제스처 추가
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
        
        // 사진 캡처 완료 콜백 설정
        camera.photoCaptureCompletion = { image in
            DispatchQueue.main.async {
                capturedImage = image
                showingPreview = true
            }
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            self.camera.displayLayer?.frame = self.camera.previewView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: CameraPreviewView
        
        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: parent.camera.previewView)
            parent.camera.focus(at: location)
        }
    }
}

// CameraController extension to handle photo capture
extension CameraController {
    var photoCaptureCompletion: ((UIImage?) -> Void)? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.photoCaptureCompletion) as? (UIImage?) -> Void }
        set { objc_setAssociatedObject(self, &AssociatedKeys.photoCaptureCompletion, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    private struct AssociatedKeys {
        static var photoCaptureCompletion = "photoCaptureCompletion"
    }
}
