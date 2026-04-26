import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var fillWidth: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .background(Color.appForest, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var fillWidth: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.appForestDeep)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .background(Color.appLeafPale, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.appForestDeep)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
