import SwiftUI

struct StepListView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    @Environment(ToastCenter.self) private var toastCenter

    let crop: Crop
    let instance: ActiveCropEntity

    private var currentIndex: Int {
        crop.steps.firstIndex(where: { !instance.completedStepIds.contains($0.id) }) ?? crop.steps.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "ステップ")
            ForEach(Array(crop.steps.enumerated()), id: \.element.id) { idx, step in
                stepCard(idx: idx, step: step)
            }
        }
    }

    @ViewBuilder
    private func stepCard(idx: Int, step: CropStep) -> some View {
        let done = instance.completedStepIds.contains(step.id)
        let current = idx == currentIndex
        let targetDate = DateUtils.addDays(instance.plantedAt, step.daysFromStart)
        let daysFromNow = DateUtils.diffDays(Date(), targetDate)
        let isHarvest = step.id == "harvest"

        CardContainer {
            HStack(alignment: .top, spacing: 12) {
                marker(index: idx + 1, done: done, current: current)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(step.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.appInk)
                        Spacer()
                        Text("\(DateUtils.formatMD(targetDate))目安")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appInkMute)
                    }
                    if current {
                        Text(daysFromNow > 0 ? "あと\(daysFromNow)日"
                             : daysFromNow == 0 ? "今日が目安" : "\(-daysFromNow)日経過")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appForestDeep)
                    }
                    Text(step.description)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appInkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    usedItems(step: step)
                    WhyAccordionView(stepKey: "\(crop.id)-\(step.id)", why: step.why)
                    if (current || done) && !isHarvest {
                        if !done {
                            Button("✓ \(step.name)を完了にする") {
                                userStore.completeStep(instanceId: instance.instanceId, stepId: step.id)
                                userStore.runAchievementChecks(catalog: catalog, toast: toastCenter)
                                userStore.runChallengeChecks(catalog: catalog, toast: toastCenter)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        } else {
                            Button("完了を取り消す") {
                                userStore.undoStep(instanceId: instance.instanceId,
                                                   stepId: step.id,
                                                   stepIndex: idx)
                            }
                            .buttonStyle(GhostButtonStyle())
                        }
                    }
                    if isHarvest && current {
                        NavigationLink(value: CropRoute.harvest(cropId: crop.id, instanceId: instance.instanceId)) {
                            Text("収穫ガイドを開く")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
        }
        .opacity(done ? 0.7 : 1)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(current ? Color.appForest : Color.clear, lineWidth: 2)
        )
    }

    private func marker(index: Int, done: Bool, current: Bool) -> some View {
        ZStack {
            Circle()
                .fill(done ? Color.appForest : current ? Color.appSun : Color.appLine)
                .frame(width: 32, height: 32)
            Text(done ? "✓" : "\(index)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(done ? .white : (current ? Color.appEarth : Color.appInkMute))
        }
    }

    @ViewBuilder
    private func usedItems(step: CropStep) -> some View {
        let toolItems: [Tool] = (step.tools ?? []).compactMap { catalog.tool(id: $0) }
        let fertItems: [Fertilizer] = (step.fertilizers ?? []).compactMap { catalog.fertilizer(id: $0.fertilizerId) }
        if !toolItems.isEmpty || !fertItems.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Text("使うもの:").font(.system(size: 11)).foregroundStyle(Color.appInkMute)
                    ForEach(toolItems, id: \.id) { t in
                        Chip(text: t.name, variant: .mute, icon: t.emoji)
                            .opacity(userStore.profile.inventory.owns(toolId: t.id) ? 0.5 : 1)
                    }
                    ForEach(fertItems, id: \.id) { f in
                        Chip(text: f.name, variant: .leaf, icon: f.emoji)
                            .opacity(userStore.profile.inventory.owns(fertilizerId: f.id) ? 0.5 : 1)
                    }
                }
            }
        }
    }
}

struct WhyAccordionView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    @Environment(ToastCenter.self) private var toastCenter
    let stepKey: String
    let why: String
    @State private var open = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                open.toggle()
                if open, userStore.recordWhyRead(key: stepKey) {
                    userStore.runAchievementChecks(catalog: catalog, toast: toastCenter)
                    userStore.runChallengeChecks(catalog: catalog, toast: toastCenter)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(open ? "▾" : "▸")
                    Text("なぜやるの？")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.appForestDeep)
            }
            if open {
                Text(why)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appInkSoft)
                    .padding(10)
                    .background(Color.appLeafPale.opacity(0.5),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}
