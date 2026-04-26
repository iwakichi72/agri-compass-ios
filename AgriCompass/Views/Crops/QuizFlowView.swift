import SwiftUI

struct QuizFlowView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(UserStore.self) private var userStore

    @State private var space: RequiredSpace?
    @State private var experience: QuizExperience?
    @State private var motivation: QuizMotivation?
    @State private var seasonChoice: QuizSeasonOption?

    var allAnswered: Bool {
        space != nil && experience != nil && motivation != nil && seasonChoice != nil
    }

    private var results: [QuizResult] {
        guard let space, let experience, let motivation, let seasonChoice else { return [] }
        return QuizEngine.score(
            answers: .init(space: space, experience: experience,
                           motivation: motivation, season: seasonChoice),
            region: userStore.profile.selectedRegion,
            crops: catalog.crops
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pickerCard(title: "育てられるスペースは？", selection: $space, options: [
                    (.pot, "ベランダでプランター1つ分", "コンパクトに"),
                    (.small, "小さめの庭・菜園コーナー", "1〜2m²"),
                    (.medium, "家庭菜園サイズ", "数m²あり"),
                    (.large, "広め", "自由に作れる"),
                ])

                pickerCard(title: "野菜づくりの経験は？", selection: $experience, options: [
                    (.none, "はじめて", "やさしい品種から"),
                    (.some, "少しある", "中級にも挑戦OK"),
                ])

                pickerCard(title: "一番うれしいのは？", selection: $motivation, options: [
                    (.rewardFast, "すぐに収穫できる達成感", "短期作物"),
                    (.rewardCook, "食卓に並ぶ定番野菜", "トマト・ナスなど"),
                    (.rewardLong, "長く収穫を楽しみたい", "実物野菜"),
                ])

                pickerCard(title: "いつから始めたい？", selection: $seasonChoice, options: [
                    (.any, "今すぐ", "季節に合うものを"),
                    (.season(.spring), "春から", "3〜5月"),
                    (.season(.summer), "夏から", "6〜8月"),
                    (.season(.autumn), "秋から", "9〜11月"),
                ])

                if allAnswered {
                    SectionHeader(text: "おすすめ作物")
                    VStack(spacing: 8) {
                        if results.isEmpty {
                            CardContainer {
                                Text("条件に合うものが見つかりません。回答を変えてみてください。")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appInkSoft)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                        } else {
                            ForEach(results) { r in
                                NavigationLink(value: CropRoute.detail(cropId: r.crop.id, instanceId: nil)) {
                                    CardContainer(padding: 12) {
                                        HStack(alignment: .top, spacing: 12) {
                                            Text(r.crop.emoji).font(.system(size: 28))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(r.crop.name)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(Color.appInk)
                                                Text(r.crop.summary)
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(Color.appInkSoft)
                                                    .lineLimit(2)
                                                if !r.reasons.isEmpty {
                                                    HStack(spacing: 4) {
                                                        ForEach(r.reasons, id: \.self) { reason in
                                                            Chip(text: reason, variant: .leaf)
                                                        }
                                                    }
                                                }
                                            }
                                            Spacer(minLength: 0)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.appCanvas)
    }

    @ViewBuilder
    private func pickerCard<T: Hashable>(title: String,
                                         selection: Binding<T?>,
                                         options: [(T, String, String)]) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.appInk)
                VStack(spacing: 6) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, item in
                        Button {
                            selection.wrappedValue = item.0
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.1)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color.appInk)
                                    Text(item.2)
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.appInkMute)
                                }
                                Spacer()
                                if selection.wrappedValue == item.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.appForest)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selection.wrappedValue == item.0
                                          ? Color.appLeafPale
                                          : Color.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(selection.wrappedValue == item.0
                                                  ? Color.appForest
                                                  : Color.appLine, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
