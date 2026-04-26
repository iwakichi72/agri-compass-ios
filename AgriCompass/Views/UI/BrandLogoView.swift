import SwiftUI

struct BrandLogoView: View {
    enum Variant {
        case hero
        case navigation
    }

    let variant: Variant

    var body: some View {
        Group {
            switch variant {
            case .hero:
                VStack(spacing: 10) {
                    BrandMark(size: 104)
                    VStack(spacing: 0) {
                        Text("Agri")
                            .foregroundStyle(Color.appForest)
                        Text("Compass")
                            .foregroundStyle(Color.appEarth)
                    }
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .lineLimit(1)
                }
            case .navigation:
                HStack(spacing: 7) {
                    BrandMark(size: 24)
                    (
                        Text("Agri ")
                            .foregroundStyle(Color.appForest)
                        + Text("Compass")
                            .foregroundStyle(Color.appEarth)
                    )
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                }
                .fixedSize()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("アグリコンパス")
    }
}

private struct BrandMark: View {
    let size: CGFloat

    var body: some View {
        Image("BrandMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
