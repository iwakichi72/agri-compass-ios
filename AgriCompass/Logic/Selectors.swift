import Foundation

struct TodayTask: Hashable, Identifiable {
    enum Kind: String { case step, harvestCheck = "harvest-check" }
    let instanceId: String
    let cropId: String
    let cropName: String
    let emoji: String
    let stepId: String
    let stepName: String
    let why: String
    let overdueDays: Int
    let kind: Kind

    var id: String { "\(instanceId)-\(stepId)" }
}

enum GrowthStage: String {
    case sprout, growing, ready, harvested

    var icon: String {
        switch self {
        case .sprout: "🌱"
        case .growing: "🌿"
        case .ready: "🌾"
        case .harvested: "🥬"
        }
    }
    var label: String {
        switch self {
        case .sprout: "芽"
        case .growing: "育成中"
        case .ready: "収穫期"
        case .harvested: "収穫済み"
        }
    }
}

enum Selectors {
    static func growingCrops(_ activeCrops: [ActiveCropEntity]) -> [ActiveCropEntity] {
        activeCrops.filter { $0.status == .growing }
    }

    static func todayTasks(activeCrops: [ActiveCropEntity],
                           cropResolver: (String) -> Crop?,
                           now: Date = Date()) -> [TodayTask] {
        let todayStart = DateUtils.startOfDay(now)
        var tasks: [TodayTask] = []
        for ac in growingCrops(activeCrops) {
            guard let crop = cropResolver(ac.cropId) else { continue }
            // first incomplete step >= currentStepIndex
            let nextStep = crop.steps.enumerated().first { (i, s) in
                i >= ac.currentStepIndex && !ac.completedStepIds.contains(s.id)
            }?.element
            guard let step = nextStep else { continue }
            let target = DateUtils.startOfDay(DateUtils.addDays(ac.plantedAt, step.daysFromStart))
            let daysUntil = DateUtils.diffDays(todayStart, target)
            if daysUntil <= 0 {
                tasks.append(TodayTask(
                    instanceId: ac.instanceId,
                    cropId: ac.cropId,
                    cropName: ac.nickname ?? crop.name,
                    emoji: crop.emoji,
                    stepId: step.id,
                    stepName: step.name,
                    why: step.why,
                    overdueDays: max(0, -daysUntil),
                    kind: step.id == "harvest" ? .harvestCheck : .step
                ))
            }
        }
        return tasks
    }

    static func weeklyTasks(activeCrops: [ActiveCropEntity],
                            cropResolver: (String) -> Crop?,
                            anchor: Date = Date()) -> (days: [Date], map: [Date: [TodayTask]]) {
        let days = DateUtils.weekDates(anchor)
        var map: [Date: [TodayTask]] = [:]
        for d in days { map[d] = [] }

        let firstDay = days[0]
        let lastDay = days[6]
        let earliestOverdueAnchor = DateUtils.addDays(firstDay, -14)

        for ac in growingCrops(activeCrops) {
            guard let crop = cropResolver(ac.cropId) else { continue }
            for i in ac.currentStepIndex..<crop.steps.count {
                let step = crop.steps[i]
                if ac.completedStepIds.contains(step.id) { continue }
                let target = DateUtils.startOfDay(DateUtils.addDays(ac.plantedAt, step.daysFromStart))
                if let matched = days.first(where: { DateUtils.isSameDay($0, target) }) {
                    map[matched]?.append(makeTask(ac: ac, crop: crop, step: step, overdueDays: 0))
                    break
                }
                if target < firstDay && target >= earliestOverdueAnchor {
                    let overdueDays = DateUtils.diffDays(target, firstDay)
                    map[firstDay]?.append(makeTask(ac: ac, crop: crop, step: step, overdueDays: overdueDays))
                    break
                }
                if target > lastDay { break }
            }
        }
        return (days, map)
    }

    private static func makeTask(ac: ActiveCropEntity, crop: Crop, step: CropStep, overdueDays: Int) -> TodayTask {
        TodayTask(
            instanceId: ac.instanceId,
            cropId: ac.cropId,
            cropName: ac.nickname ?? crop.name,
            emoji: crop.emoji,
            stepId: step.id,
            stepName: step.name,
            why: step.why,
            overdueDays: overdueDays,
            kind: step.id == "harvest" ? .harvestCheck : .step
        )
    }

    static func growthStage(ac: ActiveCropEntity, crop: Crop, now: Date = Date()) -> GrowthStage {
        if ac.status == .harvested { return .harvested }
        let readyDays = Double(crop.harvestGuide.daysFromSowing.ready)
        let daysSince = Double(DateUtils.diffDays(ac.plantedAt, now))
        if daysSince < readyDays * 0.25 { return .sprout }
        if daysSince < readyDays * 0.85 { return .growing }
        return .ready
    }

    static func instances(of cropId: String, in activeCrops: [ActiveCropEntity]) -> [ActiveCropEntity] {
        activeCrops.filter { $0.cropId == cropId }
    }
}
