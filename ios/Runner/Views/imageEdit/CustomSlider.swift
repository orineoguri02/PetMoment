import SwiftUI

struct CustomSlider: View {
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
                    .frame(height: 2)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 2)
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * (geometry.size.width - 20))
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                onEditingChanged(true)
                                let newValue = Float(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                            }
                            .onEnded { _ in onEditingChanged(false) }
                    )
            }
        }
        .frame(height: 20)
    }
}
