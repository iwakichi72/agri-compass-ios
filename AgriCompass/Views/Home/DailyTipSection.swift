import SwiftUI

struct DailyTipSection: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    private var tip: Tip? {
        let activeIds = userStore.activeCrops.map(\.cropId)
        return TipPicker.today(tips: catalog.tips, activeCropIds: activeIds)
    }

    var body: some View {
        if let tip {
            CardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionHeader(text: "今日の豆知識")
                        Spacer()
                        Chip(text: tip.category.label, variant: .leaf, icon: tip.category.emoji)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        Text(tip.category.emoji).font(.system(size: 32))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.appInk)
                            Text(tip.body)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appInkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    HStack {
                        Spacer()
                        NavigationLink(value: HomeRoute.tipsList) {
                            HStack(spacing: 4) {
                                Text("もっと見る")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.appForestDeep)
                        }
                    }
                }
            }
        }
    }
}
