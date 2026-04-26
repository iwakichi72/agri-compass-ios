import SwiftUI

struct ChallengesSection: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    var body: some View {
        let featured = catalog.featuredChallenges()
        let others = catalog.challenges.filter { c in !featured.contains(where: { $0.id == c.id }) }

        VStack(alignment: .leading, spacing: 12) {
            if !featured.isEmpty {
                CardContainer {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(text: "今月のおすすめチャレンジ")
                        VStack(spacing: 8) {
                            ForEach(featured) { ch in
                                ChallengeCardView(challenge: ch, featured: true)
                            }
                        }
                    }
                }
            }
            CardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(text: "シーズンチャレンジ")
                    VStack(spacing: 8) {
                        ForEach(others) { ch in
                            ChallengeCardView(challenge: ch, featured: false)
                        }
                    }
                }
            }
        }
    }
}

struct ChallengeCardView: View {
    @Environment(UserStore.self) private var userStore
    let challenge: Challenge
    let featured: Bool

    private var progress: ChallengeProgressEntity? {
        userStore.challenges.first(where: { $0.challengeId == challenge.id })
    }

    private var totals: (Int, Int, Int) {
        ChallengeEngine.overallProgress(challenge: challenge,
                                        userProgress: progress?.goalProgress)
    }

    var body: some View {
        NavigationLink(value: ChallengeRoute.detail(challengeId: challenge.id)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(challenge.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Spacer()
                    if featured {
                        Chip(text: "今月", variant: .sun)
                    }
                    if progress?.completedAt != nil {
                        Chip(text: "達成", variant: .leaf, icon: "🏆")
                    }
                }
                Text(challenge.description)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appInkSoft)
                    .lineLimit(2)
                let (current, target, percent) = totals
                ProgressView(value: Double(current), total: Double(max(target, 1)))
                    .tint(Color.appForest)
                Text("進捗 \(current) / \(target)（\(percent)%）")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appCanvas,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.appLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
