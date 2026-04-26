import SwiftUI

enum ChipVariant {
    case leaf, sun, earth, mute

    var background: Color {
        switch self {
        case .leaf: .appLeafPale
        case .sun: .appSunSoft
        case .earth: .appEarthSoft
        case .mute: .appLine.opacity(0.5)
        }
    }
    var foreground: Color {
        switch self {
        case .leaf: .appForestDeep
        case .sun: .appEarth
        case .earth: .appEarth
        case .mute: .appInkSoft
        }
    }
}

struct Chip: View {
    let text: String
    var variant: ChipVariant = .leaf
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon { Text(icon) }
            Text(text)
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(variant.foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(variant.background, in: Capsule())
    }
}
