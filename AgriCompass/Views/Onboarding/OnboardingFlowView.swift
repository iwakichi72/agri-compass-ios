import SwiftUI

struct OnboardingFlowView: View {
    let onChooseFirstCrop: () -> Void
    @State private var step: Step = .welcome

    enum Step { case welcome, region, firstCrop }

    init(onChooseFirstCrop: @escaping () -> Void = {}) {
        self.onChooseFirstCrop = onChooseFirstCrop
    }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                OnboardingWelcomeView(onContinue: { step = .region })
            case .region:
                RegionPickerView(onSelected: { step = .firstCrop })
            case .firstCrop:
                FirstCropPromptView(onChooseFirstCrop: onChooseFirstCrop)
            }
        }
        .background(Color.appCanvas.ignoresSafeArea())
    }
}

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    BrandLogoView(variant: .hero)
                    Text("はじめての野菜づくりを、迷わずたのしく。")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appInkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                CardContainer {
                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(emoji: "📍", title: "地域に合わせた目安",
                                   detail: "あなたの地域の気候に合わせて、種まきや収穫の時期を案内します。")
                        FeatureRow(emoji: "🪜", title: "ステップで迷わない",
                                   detail: "今やることを一つずつ、理由つきでお知らせします。")
                        FeatureRow(emoji: "🏆", title: "実績とチャレンジ",
                                   detail: "コツコツ続けると、季節の達成感が積み重なります。")
                    }
                }

                Button("はじめる", action: onContinue)
                    .buttonStyle(PrimaryButtonStyle(fillWidth: true))
                    .padding(.horizontal, 4)
            }
            .padding(20)
        }
    }
}

private struct FeatureRow: View {
    let emoji: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.appInk)
                Text(detail).font(.system(size: 12)).foregroundStyle(Color.appInkSoft)
            }
        }
    }
}

struct RegionPickerView: View {
    @Environment(UserStore.self) private var userStore
    let onSelected: () -> Void

    private let regions: [Region] = Region.allCases

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("お住まいの地域は？")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Text("地域に合わせた播種・収穫のタイミングをご案内します。あとで変更できます。")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appInkSoft)
                }
                .padding(.top, 12)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(regions, id: \.rawValue) { region in
                        Button {
                            userStore.setRegion(region)
                            onSelected()
                        } label: {
                            VStack(spacing: 6) {
                                Text(regionEmoji(region)).font(.system(size: 32))
                                Text(region.label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.appInk)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.appLine, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private func regionEmoji(_ r: Region) -> String {
        switch r {
        case .hokkaido: "❄️"
        case .tohoku: "🌾"
        case .kanto: "🗼"
        case .chubu: "🏔️"
        case .kansai: "🍡"
        case .chugoku: "⛩️"
        case .shikoku: "🍊"
        case .kyushuOkinawa: "🌺"
        }
    }
}

struct FirstCropPromptView: View {
    @Environment(UserStore.self) private var userStore
    let onChooseFirstCrop: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🪴").font(.system(size: 64))
            Text("最初の作物を選びましょう")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.appInk)
            Text("質問に答えるだけで、あなたに合った作物が見つかります。")
                .font(.system(size: 13))
                .foregroundStyle(Color.appInkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button("作物を選ぶ") {
                onChooseFirstCrop()
            }
            .buttonStyle(PrimaryButtonStyle(fillWidth: true))
            .padding(.horizontal, 20)
            Button("あとで決める") {
                userStore.completeOnboarding()
            }
            .buttonStyle(GhostButtonStyle())
            Spacer()
        }
        .padding()
    }
}
