import SwiftUI

struct HarvestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    @Environment(ToastCenter.self) private var toastCenter

    let cropId: String
    let instanceId: String

    @State private var note: String = ""
    @State private var confirmed = false

    private var crop: Crop? { catalog.crop(id: cropId) }
    private var instance: ActiveCropEntity? {
        userStore.activeCrops.first(where: { $0.instanceId == instanceId })
    }

    private var stage: HarvestStage? {
        guard let crop, let instance else { return nil }
        let days = DateUtils.diffDays(instance.plantedAt, Date())
        return HarvestStage.resolve(daysSincePlanting: days, guide: crop.harvestGuide)
    }

    var body: some View {
        ScrollView {
            if let crop, let instance, let stage {
                VStack(alignment: .leading, spacing: 16) {
                    CardContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(crop.emoji).font(.system(size: 36))
                                VStack(alignment: .leading) {
                                    Text(crop.name).font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color.appInk)
                                    Text("植え付けから\(DateUtils.diffDays(instance.plantedAt, Date()))日")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color.appInkMute)
                                }
                                Spacer()
                            }
                            HarvestStageBarView(stage: stage)
                            Divider()
                            stageDescription(crop: crop, stage: stage)
                        }
                    }
                    CardContainer {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeader(text: "メモ（任意）")
                            TextEditor(text: $note)
                                .font(.system(size: 13))
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color.appCanvas,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.appLine, lineWidth: 1)
                                )
                        }
                    }

                    Button("収穫を記録する") {
                        userStore.markHarvested(instanceId: instance.instanceId,
                                                note: note.isEmpty ? nil : note)
                        userStore.runAchievementChecks(catalog: catalog, toast: toastCenter)
                        userStore.runChallengeChecks(catalog: catalog, toast: toastCenter)
                        toastCenter.push(message: "🥬 \(crop.name) を収穫しました")
                        confirmed = true
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle(fillWidth: true))
                }
                .padding(16)
            } else {
                Text("対象が見つかりません")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appInkSoft)
                    .padding()
            }
        }
        .background(Color.appCanvas)
        .navigationTitle("収穫")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stageDescription(crop: Crop, stage: HarvestStage) -> some View {
        let body: String
        switch stage {
        case .early: body = crop.harvestGuide.earlyCriteria
        case .ready: body = crop.harvestGuide.readyCriteria
        case .late: body = crop.harvestGuide.lateCriteria
        }
        return VStack(alignment: .leading, spacing: 4) {
            Text(stage.label).font(.system(size: 14, weight: .bold)).foregroundStyle(Color.appInk)
            Text(body).font(.system(size: 13)).foregroundStyle(Color.appInkSoft)
        }
    }
}

struct HarvestStageBarView: View {
    let stage: HarvestStage
    private let stages: [HarvestStage] = [.early, .ready, .late]

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(stages, id: \.self) { s in
                    Rectangle()
                        .fill(color(for: s, isActive: s == stage))
                        .frame(maxWidth: .infinity)
                        .frame(height: 10)
                }
            }
            .clipShape(Capsule())
            HStack(spacing: 0) {
                ForEach(stages, id: \.self) { s in
                    Text(s.label)
                        .font(.system(size: 11, weight: stage == s ? .bold : .regular))
                        .foregroundStyle(stage == s ? Color.appInk : Color.appInkMute)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func color(for s: HarvestStage, isActive: Bool) -> Color {
        guard isActive else { return .appLine }
        switch s {
        case .early: return .appLeaf
        case .ready: return .appForest
        case .late: return .appEarth
        }
    }
}
