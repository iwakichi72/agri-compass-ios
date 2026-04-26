import Foundation

enum AchievementEngine {
    /// Returns achievement IDs that are NEWLY unlocked (not already in `existing`).
    static func evaluate(existing: Set<String>,
                         activeCrops: [ActiveCropEntity],
                         harvestHistory: [HarvestRecordEntity],
                         stats: StatsData,
                         cropResolver: (String) -> Crop?,
                         now: Date = Date()) -> [String] {
        var newlyUnlocked: [String] = []
        func consider(_ id: String, _ cond: Bool) {
            if cond && !existing.contains(id) && !newlyUnlocked.contains(id) {
                newlyUnlocked.append(id)
            }
        }

        // first-step
        consider("first-step", activeCrops.contains(where: { !$0.completedStepIds.isEmpty }))

        // first-harvest
        consider("first-harvest", harvestHistory.count >= 1)

        // leaf-master: 3 leaf crops harvested
        let leafHarvestCount = harvestHistory.filter { cropResolver($0.cropId)?.category == .leaf }.count
        consider("leaf-master", leafHarvestCount >= 3)

        // root-expert: any root crop harvested
        consider("root-expert", harvestHistory.contains { cropResolver($0.cropId)?.category == .root })

        // three-together: 3+ currently growing
        let currentlyGrowing = activeCrops.filter { $0.status == .growing }.count
        consider("three-together", currentlyGrowing >= 3)

        // weather-reader
        consider("weather-reader", stats.weatherChecksCount >= 5)

        // why-curious
        consider("why-curious", stats.whyReadCount >= 10)

        // spring-pioneer
        let springStart = activeCrops.contains { Season.of(date: $0.plantedAt) == .spring }
        consider("spring-pioneer", springStart)

        // summer-harvester
        let summerHarvest = harvestHistory.contains { Season.of(date: $0.harvestedAt) == .summer }
        consider("summer-harvester", summerHarvest)

        // rainy-walker
        consider("rainy-walker", stats.lastRainyVisit != nil)

        // streak achievements
        consider("streak-7", stats.maxStreakDays >= 7)
        consider("streak-30", stats.maxStreakDays >= 30)
        consider("streak-100", stats.maxStreakDays >= 100)

        // autumn-sower
        let autumnStart = activeCrops.contains { Season.of(date: $0.plantedAt) == .autumn }
        consider("autumn-sower", autumnStart)

        // winter-keeper
        let winterNow = Season.of(date: now) == .winter && stats.streakDays >= 1
        consider("winter-keeper", winterNow)

        // fruit-grower: 3 fruit harvests
        let fruitHarvests = harvestHistory.filter { cropResolver($0.cropId)?.category == .fruit }.count
        consider("fruit-grower", fruitHarvests >= 3)

        // bean-friend
        consider("bean-friend", harvestHistory.contains { cropResolver($0.cropId)?.category == .bean })

        // five-species: distinct crop ids across active + harvested
        var distinctIds = Set<String>()
        for c in activeCrops { distinctIds.insert(c.cropId) }
        for h in harvestHistory { distinctIds.insert(h.cropId) }
        consider("five-species", distinctIds.count >= 5)

        return newlyUnlocked
    }
}
