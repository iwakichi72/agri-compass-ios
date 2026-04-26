import SwiftUI

struct FarmOverviewSection: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    private var growing: [ActiveCropEntity] {
        Selectors.growingCrops(userStore.activeCrops)
    }

    var body: some View {
        if growing.isEmpty {
            emptyState
        } else {
            CardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionHeader(text: "マイ農園")
                        Spacer()
                        NavigationLink(value: CropRoute.select) {
                            Text("＋作物を追加")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appForestDeep)
                        }
                    }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(growing, id: \.instanceId) { ac in
                            if let crop = catalog.crop(id: ac.cropId) {
                                NavigationLink(value: CropRoute.detail(cropId: ac.cropId, instanceId: ac.instanceId)) {
                                    cell(ac: ac, crop: crop)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(text: "マイ農園")
                VStack(spacing: 12) {
                    Text("🪴").font(.system(size: 40))
                    Text("まずは1つ育ててみましょう")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Text("質問に答えるだけで、あなたに合った作物が見つかります。")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appInkSoft)
                        .multilineTextAlignment(.center)
                    NavigationLink(value: CropRoute.select) {
                        Text("最初の作物を選ぶ")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.appLeafPale.opacity(0.5),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appLeafSoft, style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
            }
        }
    }

    private func cell(ac: ActiveCropEntity, crop: Crop) -> some View {
        let stage = Selectors.growthStage(ac: ac, crop: crop)
        let days = DateUtils.diffDays(ac.plantedAt, Date())
        let untilReady = crop.harvestGuide.daysFromSowing.ready - days
        let countdown: String = stage == .ready
            ? "収穫OK"
            : (untilReady > 0 ? "収穫まで\(untilReady)日" : "収穫期から\(-untilReady)日")
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(crop.emoji).font(.system(size: 26))
                Spacer()
                Text("\(days)日目")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)
            }
            Text(ac.nickname ?? crop.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appInk)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(stage.icon).font(.system(size: 16))
                Text(stage.label).font(.system(size: 12)).foregroundStyle(Color.appInkSoft)
            }
            Text(countdown)
                .font(.system(size: 11))
                .foregroundStyle(Color.appInkMute)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCanvas, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.appLine, lineWidth: 1)
        )
    }
}
