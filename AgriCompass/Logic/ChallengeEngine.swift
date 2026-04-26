import Foundation

enum ChallengeEngine {
    struct Update: Hashable {
        let id: String
        let goalId: String
        let value: Int
        let completed: Bool
    }

    static func evaluate(allChallenges: [Challenge],
                         activeCrops: [ActiveCropEntity],
                         harvestHistory: [HarvestRecordEntity],
                         stats: StatsData,
                         cropResolver: (String) -> Crop?) -> [Update] {
        var updates: [Update] = []
        let growing = activeCrops.filter { $0.status == .growing }
        for challenge in allChallenges {
            for goal in challenge.goals {
                var value = 0
                switch goal.id {
                case "active3":
                    value = growing.count
                case "tomato-harvest":
                    value = harvestHistory.filter {
                        let id = $0.cropId
                        return id == "tomato" || id == "mini-tomato"
                    }.count
                case "leaf3":
                    value = activeCrops.filter { cropResolver($0.cropId)?.category == .leaf }.count
                case "why10", "why25":
                    value = stats.whyReadCount
                case "fruit-active":
                    value = growing.filter { cropResolver($0.cropId)?.category == .fruit }.count
                case "harvest-total":
                    value = harvestHistory.count
                case "root-or-bean-active":
                    value = growing.filter {
                        let cat = cropResolver($0.cropId)?.category
                        return cat == .root || cat == .bean
                    }.count
                default:
                    break
                }
                let capped = min(value, goal.target)
                updates.append(Update(id: challenge.id, goalId: goal.id, value: capped, completed: capped >= goal.target))
            }
        }
        return updates
    }

    static func overallProgress(challenge: Challenge,
                                userProgress: [String: Int]?) -> (current: Int, target: Int, percent: Int) {
        let current = challenge.goals.reduce(0) { $0 + (userProgress?[$1.id] ?? 0) }
        let target = challenge.goals.reduce(0) { $0 + $1.target }
        let percent = target > 0 ? Int(Double(current) / Double(target) * 100) : 0
        return (current, target, percent)
    }
}
