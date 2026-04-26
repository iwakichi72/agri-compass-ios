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
        let targetDate = Selectors.targetDate(ac: instance, step: step)
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
                    if current && !done && daysFromNow < 0 && !isHarvest {
                        RecoverySuggestionView(
                            overdueDays: -daysFromNow,
                            onComplete: { complete(stepId: step.id) },
                            onPostpone: { postponeToTomorrow(targetDate: targetDate) }
                        )
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
                                complete(stepId: step.id)
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

    private func complete(stepId: String) {
        userStore.completeStep(instanceId: instance.instanceId, stepId: stepId)
        userStore.runAchievementChecks(catalog: catalog, toast: toastCenter)
        userStore.runChallengeChecks(catalog: catalog, toast: toastCenter)
    }

    private func postponeToTomorrow(targetDate: Date) {
        let tomorrow = DateUtils.startOfDay(DateUtils.addDays(Date(), 1))
        let daysToShift = max(1, DateUtils.diffDays(targetDate, tomorrow))
        userStore.shiftSchedule(instanceId: instance.instanceId, byDays: daysToShift)
        toastCenter.push(message: "予定を明日にずらしました")
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

private struct RecoverySuggestionView: View {
    let overdueDays: Int
    let onComplete: () -> Void
    let onPostpone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.appEarth)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 3) {
                    Text("作業予定から\(overdueDays)日過ぎています")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appInkSoft)
                }
            }
            HStack(spacing: 8) {
                Button("今日やった") {
                    onComplete()
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("明日に延期") {
                    onPostpone()
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
        .padding(10)
        .background(Color.appSunSoft.opacity(0.55),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.appSun.opacity(0.45), lineWidth: 1)
        )
    }

    private var message: String {
        if overdueDays <= 2 {
            return "今日できれば、そのまま進めて大丈夫です。難しければ明日にずらせます。"
        }
        if overdueDays <= 7 {
            return "次の予定も少し後ろへずらすと、無理なく立て直せます。"
        }
        return "まず状態を見て、できそうなら今日実施。迷う時は明日にずらしましょう。"
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
