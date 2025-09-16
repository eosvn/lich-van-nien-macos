import SwiftUI

struct AppColors {
    static let background = Color(red: 0.1176, green: 0.1176, blue: 0.1176) // #1e1e1e
    static let surface = Color(red: 0.16, green: 0.16, blue: 0.18)
    static let divider = Color(red: 0.26, green: 0.26, blue: 0.28)
    static let textPrimary = Color(red: 0.94, green: 0.94, blue: 0.94) // #f0f0f0
    static let textSecondary = Color(red: 0.63, green: 0.63, blue: 0.63) // #a0a0a0
    static let textTertiary = Color(red: 0.48, green: 0.48, blue: 0.48)
    static let weekend = Color(red: 1.0, green: 0.58, blue: 0.0) // #ff9500
    static let selectedBackground = Color(red: 0.0, green: 0.376, blue: 1.0) // #0060ff
    static let eventImportant = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let eventNormal = Color(red: 0.62, green: 0.62, blue: 0.62)
}

// Simple wrap grid for chips
struct WrapGrid<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(items: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0

            ZStack(alignment: .topLeading) {
                ForEach(Array(items), id: \.self) { item in
                    content(item)
                        .alignmentGuide(.leading) { d in
                            if (abs(currentX - d.width) > width) {
                                currentX = 0
                                currentY -= d.height + spacing
                            }
                            let result = currentX
                            if item == items.last { currentX = 0 } else { currentX -= d.width + spacing }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = currentY
                            if item == items.last { currentY = 0 }
                            return result
                        }
                }
            }
        }
        .frame(minHeight: 20)
    }
}
