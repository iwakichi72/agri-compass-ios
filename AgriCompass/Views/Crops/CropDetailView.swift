import SwiftUI

struct CropDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CatalogStore.self) private var catalog
    @Environment(UserStore.self) private var userStore
    @Environment(ToastCenter.self) private var toastCenter

    let cropId: String
    let instanceId: String?

    @State private var plantingDate = Date()
    @State private var showAbandonConfirm = false

    private var crop: Crop? { catalog.crop(id: cropId) }

    private var instance: ActiveCropEntity? {
        if let id = instanceId {
            return userStore.activeCrops.first(where: { $0.instanceId == id })
        }
        return Selectors.instances(of: cropId, in: userStore.activeCrops).first(where: { $0.status == .growing })
    }

    var body: some View {
        ScrollView {
            if let crop {
                VStack(alignment: .leading, spacing: 16) {
                    headerCard(crop: crop)
                    if let instance {
                        StepListView(crop: crop, instance: instance)
                        if instance.status == .growing {
                            growingSettingsCard(instance: instance, crop: crop)
                        }
                    } else {
                        startCard(crop: crop)
                    }
                    PreparationKitView(crop: crop)
                    harvestGuideCard(crop: crop)
                    if instance != nil {
                        NextCropRecommendView(fromCropId: crop.id)
                    }
                }
                .padding(16)
            } else {
                Text("作物が見つかりません")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appInkSoft)
                    .padding()
            }
        }
        .background(Color.appCanvas)
        .navigationTitle(crop?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("この栽培を中止しますか？",
                            isPresented: $showAbandonConfirm,
                            titleVisibility: .visible) {
            Button("中止する", role: .destructive) {
                guard let instance else { return }
                userStore.abandonCrop(instanceId: instance.instanceId)
                toastCenter.push(message: "\(crop?.name ?? "作物") の予定を終了しました")
                dismiss()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この作物は今日の予定やカレンダーから外れます。収穫記録には残りません。")
        }
    }

    private func headerCard(crop: Crop) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(crop.emoji).font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(crop.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.appInk)
                        Text(crop.nameKana)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appInkMute)
                    }
                }
                Text(crop.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appInkSoft)
                HStack(spacing: 6) {
                    Chip(text: crop.difficulty.label, variant: .leaf)
                    Chip(text: crop.requiredSpace.label, variant: .mute)
                    ForEach(crop.seasons, id: \.rawValue) { s in
                        Chip(text: s.label, variant: .sun)
                    }
                }
                if let region = userStore.profile.selectedRegion,
                   let windows = crop.sowingWindows[region], !windows.isEmpty {
                    Text("\(region.label)の植え付け目安: \(windows.map(\.label).joined(separator: " / "))")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appInkMute)
                }
            }
        }
    }

    private func startCard(crop: Crop) -> some View {
        CardContainer {
            VStack(spacing: 12) {
                Text("育て始めますか？")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.appInk)
                Text("「植え付け」を起点に、ステップで進行します。")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appInkSoft)
                    .multilineTextAlignment(.center)
                DatePicker("植え付け日", selection: $plantingDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .font(.system(size: 13))
                    .tint(Color.appForest)
                Button("この作物を育てる") {
                    let entity = userStore.addActiveCrop(cropId: crop.id,
                                                         plantedAt: DateUtils.startOfDay(plantingDate))
                    userStore.runChallengeChecks(catalog: catalog, toast: toastCenter)
                    userStore.runAchievementChecks(catalog: catalog, toast: toastCenter)
                    toastCenter.push(message: "🌱 \(crop.name) を育て始めました")
                    _ = entity
                }
                .buttonStyle(PrimaryButtonStyle(fillWidth: true))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func growingSettingsCard(instance: ActiveCropEntity, crop: Crop) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(text: "栽培設定")
                DatePicker("植え付け日", selection: Binding(
                    get: { instance.plantedAt },
                    set: { userStore.updatePlantedAt(instanceId: instance.instanceId, plantedAt: $0) }
                ), in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.compact)
                .font(.system(size: 13))
                .tint(Color.appForest)

                if instance.scheduleAdjustmentDays != 0 {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(Color.appEarth)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("予定を\(abs(instance.scheduleAdjustmentDays))日\(instance.scheduleAdjustmentDays > 0 ? "後ろ" : "前")に調整中")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.appInk)
                            Text("遅れた作業を延期した分です。不要なら元に戻せます。")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appInkSoft)
                        }
                        Spacer()
                        Button("戻す") {
                            userStore.resetScheduleAdjustment(instanceId: instance.instanceId)
                        }
                        .buttonStyle(GhostButtonStyle())
                    }
                    .padding(10)
                    .background(Color.appSunSoft.opacity(0.45),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Divider()

                Button("この栽培を中止する", role: .destructive) {
                    showAbandonConfirm = true
                }
                .buttonStyle(GhostButtonStyle())
                .foregroundStyle(Color.appEarth)
                .accessibilityHint("この作物を予定とカレンダーから外します")
            }
        }
    }

    private func harvestGuideCard(crop: Crop) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(text: "収穫の目安")
                Text(crop.harvestGuide.sizeHint)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.appInk)
                Text(crop.harvestGuide.colorHint)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appInkSoft)
                Divider()
                stagedRow(label: "まだ早い", body: crop.harvestGuide.earlyCriteria)
                stagedRow(label: "食べごろ", body: crop.harvestGuide.readyCriteria)
                stagedRow(label: "採りどき過ぎ", body: crop.harvestGuide.lateCriteria)
            }
        }
    }

    private func stagedRow(label: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(Color.appInkSoft)
            Text(body).font(.system(size: 12)).foregroundStyle(Color.appInk)
        }
    }
}
