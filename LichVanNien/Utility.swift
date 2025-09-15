import SwiftUI

// 1) PreferenceKey lấy MAX height từ các card con
struct CardHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// 2) View đo chiều cao và đẩy lên Preference
struct HeightReader: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: CardHeightKey.self, value: geo.size.height)
        }
    }
}
