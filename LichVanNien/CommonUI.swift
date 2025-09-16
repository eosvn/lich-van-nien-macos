import SwiftUI
#if os(macOS)
import AppKit
#endif

struct AppColors {
    #if os(macOS)
    private static func dynamicColor(light: NSColor, dark: NSColor) -> Color {
        let dyn = NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return dark
            } else {
                return light
            }
        }
        return Color(nsColor: dyn)
    }

    // Light/Dark palettes
    // Light: subtle light grays; Dark: existing dark palette
    static let background: Color = dynamicColor(
        light: NSColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1.0),   // #F5F5F7
        dark:  NSColor(srgbRed: 0.1176, green: 0.1176, blue: 0.1176, alpha: 1.0) // #1E1E1E
    )

    static let surface: Color = dynamicColor(
        light: NSColor.white,
        dark:  NSColor(srgbRed: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)
    )

    static let divider: Color = dynamicColor(
        light: NSColor(srgbRed: 0.82, green: 0.82, blue: 0.84, alpha: 1.0),   // #D1D1D6
        dark:  NSColor(srgbRed: 0.26, green: 0.26, blue: 0.28, alpha: 1.0)
    )

    static let textPrimary: Color = dynamicColor(
        light: NSColor(srgbRed: 0.11, green: 0.11, blue: 0.12, alpha: 1.0),   // #1C1C1E
        dark:  NSColor(srgbRed: 0.94, green: 0.94, blue: 0.94, alpha: 1.0)    // #F0F0F0
    )

    static let textSecondary: Color = dynamicColor(
        light: NSColor(srgbRed: 0.42, green: 0.42, blue: 0.44, alpha: 1.0),   // #6C6C70
        dark:  NSColor(srgbRed: 0.63, green: 0.63, blue: 0.63, alpha: 1.0)    // #A0A0A0
    )

    static let textTertiary: Color = dynamicColor(
        light: NSColor(srgbRed: 0.56, green: 0.56, blue: 0.58, alpha: 1.0),   // #8E8E93
        dark:  NSColor(srgbRed: 0.48, green: 0.48, blue: 0.48, alpha: 1.0)
    )

    static let weekend: Color = Color(nsColor: .systemOrange)

    static let selectedBackground: Color = dynamicColor(
        light: NSColor(srgbRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),    // iOS/macOS system blue
        dark:  NSColor(srgbRed: 0.0, green: 0.376, blue: 1.0, alpha: 1.0)     // existing #0060FF
    )

    static let eventImportant: Color = Color(nsColor: .systemRed)
    static let eventNormal: Color = dynamicColor(
        light: NSColor(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1.0),
        dark:  NSColor(srgbRed: 0.62, green: 0.62, blue: 0.62, alpha: 1.0)
    )
    #else
    // Fallback (non-macOS) – keep previous constants
    static let background = Color(red: 0.1176, green: 0.1176, blue: 0.1176)
    static let surface = Color(red: 0.16, green: 0.16, blue: 0.18)
    static let divider = Color(red: 0.26, green: 0.26, blue: 0.28)
    static let textPrimary = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let textSecondary = Color(red: 0.63, green: 0.63, blue: 0.63)
    static let textTertiary = Color(red: 0.48, green: 0.48, blue: 0.48)
    static let weekend = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let selectedBackground = Color(red: 0.0, green: 0.376, blue: 1.0)
    static let eventImportant = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let eventNormal = Color(red: 0.62, green: 0.62, blue: 0.62)
    #endif
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
