// 필터 강도 슬라이더

import SwiftUI

struct FilterIntensitySlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let onEditingChanged: (Bool) -> Void
    
    init(value: Binding<Float>, range: ClosedRange<Float>, onEditingChanged: @escaping (Bool) -> Void = { _ in }) {
        self._value = value
        self.range = range
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound) * geometry.size.width, height: 4)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat(value - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound) * (geometry.size.width - 20))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                onEditingChanged(true)
                                let newValue = Float(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                            }
                            .onEnded { _ in
                                onEditingChanged(false)
                            }
                    )
            }
        }
        .frame(height: 40)
        .rotationEffect(.degrees(-90))
    }
}

// 필터 컨트롤 뷰
struct FilterControlsView: View {
    @ObservedObject var cubeManager = CubeManager.shared
    @Binding var selectedFilter: CubeManager.CubeFile?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(cubeManager.getAllFilters()) { filter in
                    Button(action: {
                        selectedFilter = filter
                    }) {
                        VStack(spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                if let thumbnail = cubeManager.getCachedThumbnail(for: filter.id) {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else if let name = filter.thumbnailImageName,
                                          let uiImage = UIImage(named: name) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(filter.color)
                                        .frame(width: 60, height: 60)
                                }
                                
                                // 즐겨찾기 아이콘
                                if cubeManager.isFavorite(filter.id) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .padding(5)
                                }
                            }

                            Text(filter.name.capitalized)
                                .font(.caption)
                                .foregroundColor(selectedFilter?.id == filter.id ? .blue : .primary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // 불러오기 (필요시)
            cubeManager.loadCubeFiles()
        }
    }
}
