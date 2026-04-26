import SwiftUI

struct BadgeGridView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    private var unlockedIds: Set<String> {
        Set(userStore.achievements.map(\.achievementId))
    }

    var body: some View {
        let visible = catalog.achievements.filter { !($0.hidden && !unlockedIds.contains($0.id)) }
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(text: "実績")
                    Spacer()
                    Text("\(unlockedIds.count) / \(catalog.achievements.count)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appInkMute)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                    ForEach(visible) { ach in
                        let unlocked = unlockedIds.contains(ach.id)
                        VStack(spacing: 4) {
                            Text(ach.icon)
                                .font(.system(size: 28))
                                .opacity(unlocked ? 1 : 0.3)
                            Text(ach.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(unlocked ? Color.appInk : Color.appInkMute)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .padding(8)
                        .background(unlocked ? Color.appLeafPale : Color.appCanvas,
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.appLine, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}
