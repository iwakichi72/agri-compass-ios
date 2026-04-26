import Foundation

struct CropRecommendation: Identifiable, Hashable {
    let crop: Crop
    let reasons: [String]
    let score: Int
    var id: String { crop.id }
}

enum RecommendEngine {
    static func recommendNext(allCrops: [Crop],
                              cropResolver: (String) -> Crop?,
                              region: Region,
                              fromCropId: String,
                              recentHarvests: [HarvestRecordEntity],
                              limit: Int = 3,
                              now: Date = Date()) -> [CropRecommendation] {
        let current = cropResolver(fromCropId)
        let season = Season.of(date: now)
        var recentFamilies = Set<String>()
        for h in recentHarvests.suffix(3) {
            if let f = cropResolver(h.cropId)?.rotationFamily { recentFamilies.insert(f) }
        }
        if let current { recentFamilies.insert(current.rotationFamily) }
        let harvestedIds = Set(recentHarvests.map(\.cropId))

        let scored: [CropRecommendation] = allCrops
            .filter { $0.id != fromCropId }
            .filter { $0.regionAvailability.contains(region) }
            .map { c in
                var reasons: [String] = []
                var score = 0
                if c.seasons.contains(season) {
                    score += 3
                    reasons.append("\(season.label)向き")
                }
                if !harvestedIds.contains(c.id) {
                    score += 2
                    reasons.append("まだ育てたことがない")
                }
                let avoidConflict = recentFamilies.contains(c.rotationFamily)
                    || c.avoidAfter.contains(where: { recentFamilies.contains($0) })
                if avoidConflict {
                    score -= 3
                    reasons.append("連作を避けるため要注意")
                } else {
                    score += 1
                    reasons.append("連作障害の心配が少ない")
                }
                if current?.recommendedNext.contains(c.id) == true {
                    score += 2
                    reasons.append("この作物のあとに相性が良い")
                }
                if c.difficulty == .easy { score += 1 }
                return CropRecommendation(crop: c, reasons: reasons, score: score)
            }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }

        return Array(scored.prefix(limit))
    }
}
