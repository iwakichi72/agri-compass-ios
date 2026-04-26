import SwiftUI

struct NextCropRecommendView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(UserStore.self) private var userStore

    let fromCropId: String

    private var recs: [CropRecommendation] {
        let region = userStore.profile.selectedRegion ?? .kanto
        return RecommendEngine.recommendNext(
            allCrops: catalog.crops,
            cropResolver: { catalog.crop(id: $0) },
            region: region,
            fromCropId: fromCropId,
            recentHarvests: userStore.harvestHistory
        )
    }

    var body: some View {
        if recs.isEmpty {
            EmptyView()
        } else {
            CardContainer {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(text: "次のおすすめ")
                    VStack(spacing: 8) {
                        ForEach(recs) { rec in
                            NavigationLink(value: CropRoute.detail(cropId: rec.crop.id, instanceId: nil)) {
                                HStack(spacing: 12) {
                                    Text(rec.crop.emoji).font(.system(size: 24))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(rec.crop.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(Color.appInk)
                                        if !rec.reasons.isEmpty {
                                            Text(rec.reasons.joined(separator: " · "))
                                                .font(.system(size: 11))
                                                .foregroundStyle(Color.appInkMute)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(Color.appInkMute)
                                }
                                .padding(8)
                                .background(Color.appCanvas,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
