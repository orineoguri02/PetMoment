// 각 필터 버튼 -> 테두리, 썸네일, 필터 이름 출력

import SwiftUI

struct FilterButton: View {
    let filter: FilterType
    let previewImage: UIImage?
    let action: () -> Void
    let isSelected: Bool
    
    // 환경 변수 활용 (예: horizontalSizeClass)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // 기본 상수 정의
    private let baseThumbnailWidth: CGFloat = 110
    private let baseThumbnailHeight: CGFloat = 80
    private let baseTextSize: CGFloat = 15
    private let selectedBorderColor: Color = Color(hex: "E94A39")
    private let selectedBorderWidth: CGFloat = 2
    
    // 동적 크기 계산 (여기서는 UIDevice 대신 화면 너비 사용)
    private var scale: CGFloat {
        if horizontalSizeClass == .regular {
            return 1.3  // iPad나 큰 디바이스
        } else {
            let screenWidth = UIScreen.main.bounds.width
            return screenWidth >= 430 ? 1.0 : 0.85
        }
    }
    
    private var thumbnailSize: CGSize {
        CGSize(width: baseThumbnailWidth * scale, height: baseThumbnailHeight * scale)
    }
    
    private var textSize: CGFloat {
        horizontalSizeClass == .regular ? baseTextSize * 1.3 : (UIScreen.main.bounds.width >= 430 ? baseTextSize : baseTextSize * 0.85)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // 이미지 또는 기본 색상 영역
                if filter.name == "normal", let preview = previewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                        .clipped()
                } else if let thumbnailName = filter.thumbnailImageName {
                    Image(thumbnailName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(filter.color)
                        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
                        .overlay(
                            Image(systemName: "camera.filters")
                                .foregroundColor(.white)
                        )
                }
                
                // 필터 이름 텍스트
                Text(filter.name)
                    .font(.custom("Pretendard-Light", size: textSize))
                    .fontWeight(.regular)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .frame(height: 21 * (horizontalSizeClass == .regular ? 1.5 : 1.0))
            } // VStack
            .frame(width: thumbnailSize.width)
            .padding(.bottom, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? selectedBorderColor : Color.clear, lineWidth: selectedBorderWidth)
            )
        } // Button
        .accessibilityLabel(Text("\(filter.name)"))
    }
}

// 필터 프로토콜 정의
protocol FilterType {
    var name: String { get }
    var color: Color { get }
    var thumbnailImageName: String? { get }
}
