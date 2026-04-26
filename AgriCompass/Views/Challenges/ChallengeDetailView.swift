import SwiftUI

struct ChallengeDetailView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    @Environment(ToastCenter.self) private var toastCenter

    let challengeId: String

    private var challenge: Challenge? { catalog.challenge(id: challengeId) }
    private var progress: ChallengeProgressEntity? {
        userStore.challenges.first(where: { $0.challengeId == challengeId })
    }

    var body: some View {
        ScrollView {
            if let challenge {
                VStack(alignment: .leading, spacing: 16) {
                    CardContainer {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(challenge.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.appInk)
                                Spacer()
                                Chip(text: challenge.season.label, variant: .sun)
                            }
                            Text(challenge.description)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appInkSoft)
                            if let completed = progress?.completedAt {
                                Text("達成: \(DateUtils.formatYMD(completed))")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.appForestDeep)
                            }
                        }
                    }
                    CardContainer {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(text: "目標")
                            ForEach(challenge.goals) { goal in
                                let value = progress?.goalProgress[goal.id] ?? 0
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(goal.label)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Color.appInk)
                                        Spacer()
                                        Text("\(value) / \(goal.target)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(Color.appInkMute)
                                    }
                                    ProgressView(value: Double(value),
                                                 total: Double(max(goal.target, 1)))
                                        .tint(Color.appForest)
                                }
                            }
                        }
                    }
                    if progress?.joined != true {
                        Button("チャレンジに参加") {
                            userStore.joinChallenge(challenge.id)
                            userStore.runChallengeChecks(catalog: catalog, toast: toastCenter)
                            toastCenter.push(message: "🎯 \(challenge.title) に参加しました")
                        }
                        .buttonStyle(PrimaryButtonStyle(fillWidth: true))
                    }
                }
                .padding(16)
            } else {
                Text("チャレンジが見つかりません")
                    .padding()
            }
        }
        .background(Color.appCanvas)
        .navigationTitle(challenge?.title ?? "チャレンジ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
