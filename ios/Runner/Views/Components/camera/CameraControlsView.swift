// 갤러리, 촬영하기, 카메라 전환

import SwiftUI
import PhotosUI

struct CameraControlsView: View {
    @Binding var showingCamera: Bool
    let onCapture: () -> Void
    let onSwitchCamera: () -> Void
    let customRed: Color
    let galleryImage: UIImage?
    /// 갤러리에서 사진을 선택했을 때 호출되는 클로저
    let onGalleryPhotoSelected: (UIImage) -> Void
    
    @State private var selectedPhoto: PhotosPickerItem? = nil
    
    private let buttonSpacing: CGFloat = 70
    private let captureOuterSize: CGFloat = 70
    private let captureInnerSize: CGFloat = 60
    private let bottomPadding: CGFloat = 15
    
    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: buttonSpacing) {
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    if let galleryImage = galleryImage {
                        Image(uiImage: galleryImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipped()
                            .cornerRadius(4)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                }
                .onChange(of: selectedPhoto) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            onGalleryPhotoSelected(uiImage)
                        }
                    }
                }
                
                Button(action: onCapture) {
                    Circle()
                        .stroke(Color(hex: "E94A39"), lineWidth: 3) // 외곽선 색상
                        .frame(width: captureOuterSize, height: captureOuterSize)
                        .overlay(
                            Circle()
                                .fill(Color(hex: "FFF4F4")) // 내부 채우기 색상
                                .frame(width: captureInnerSize, height: captureInnerSize)
                        )
                        .accessibilityLabel("촬영")
                }
                
                Button(action: onSwitchCamera) {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.largeTitle)
                        .foregroundColor(.black)
                        .accessibilityLabel("카메라 전환")
                }
            } // HStack
            .padding(.bottom, bottomPadding)
            .background(Color.clear)
        } // ZStack
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
