import SwiftUI

struct HarvestShelfView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    private var records: [HarvestRecordEntity] {
        userStore.harvestHistory.sorted { $0.harvestedAt > $1.harvestedAt }
    }

    var body: some View {
        if records.isEmpty {
            EmptyView()
        } else {
            CardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(text: "収穫の記録")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(records, id: \.instanceId) { rec in
                                if let crop = catalog.crop(id: rec.cropId) {
                                    VStack(spacing: 4) {
                                        Text(crop.emoji).font(.system(size: 32))
                                        Text(crop.name)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Color.appInk)
                                        Text(DateUtils.formatYMD(rec.harvestedAt))
                                            .font(.system(size: 10))
                                            .foregroundStyle(Color.appInkMute)
                                    }
                                    .padding(8)
                                    .frame(width: 84)
                                    .background(Color.appLeafPale,
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
