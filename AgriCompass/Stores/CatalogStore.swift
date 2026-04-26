import Foundation
import Observation

@Observable
final class CatalogStore {
    let crops: [Crop]
    let tools: [Tool]
    let fertilizers: [Fertilizer]
    let achievements: [Achievement]
    let challenges: [Challenge]
    let tips: [Tip]

    private let cropById: [String: Crop]
    private let toolById: [String: Tool]
    private let fertById: [String: Fertilizer]
    private let achievementById: [String: Achievement]
    private let challengeById: [String: Challenge]
    private let tipById: [String: Tip]

    init(crops: [Crop], tools: [Tool], fertilizers: [Fertilizer],
         achievements: [Achievement], challenges: [Challenge], tips: [Tip]) {
        self.crops = crops
        self.tools = tools
        self.fertilizers = fertilizers
        self.achievements = achievements
        self.challenges = challenges
        self.tips = tips
        self.cropById = Dictionary(uniqueKeysWithValues: crops.map { ($0.id, $0) })
        self.toolById = Dictionary(uniqueKeysWithValues: tools.map { ($0.id, $0) })
        self.fertById = Dictionary(uniqueKeysWithValues: fertilizers.map { ($0.id, $0) })
        self.achievementById = Dictionary(uniqueKeysWithValues: achievements.map { ($0.id, $0) })
        self.challengeById = Dictionary(uniqueKeysWithValues: challenges.map { ($0.id, $0) })
        self.tipById = Dictionary(uniqueKeysWithValues: tips.map { ($0.id, $0) })
    }

    static func load(bundle: Bundle = .main) -> CatalogStore {
        let crops: [Crop] = decodeBundled("crops", bundle: bundle)
        let tools: [Tool] = decodeBundled("tools", bundle: bundle)
        let fertilizers: [Fertilizer] = decodeBundled("fertilizers", bundle: bundle)
        let achievements: [Achievement] = decodeBundled("achievements", bundle: bundle)
        let challenges: [Challenge] = decodeBundled("challenges", bundle: bundle)
        let tips: [Tip] = decodeBundled("tips", bundle: bundle)
        return CatalogStore(crops: crops, tools: tools, fertilizers: fertilizers,
                            achievements: achievements, challenges: challenges, tips: tips)
    }

    func crop(id: String) -> Crop? { cropById[id] }
    func tool(id: String) -> Tool? { toolById[id] }
    func fertilizer(id: String) -> Fertilizer? { fertById[id] }
    func achievement(id: String) -> Achievement? { achievementById[id] }
    func challenge(id: String) -> Challenge? { challengeById[id] }
    func tip(id: String) -> Tip? { tipById[id] }

    struct CropFilters {
        var region: Region?
        var season: Season?
        var difficulty: Difficulty?
        var requiredSpace: RequiredSpace?
        var search: String?
    }

    func filterCrops(_ f: CropFilters) -> [Crop] {
        let q = f.search?.trimmingCharacters(in: .whitespaces).lowercased()
        return crops.filter { c in
            if let r = f.region, !c.regionAvailability.contains(r) { return false }
            if let s = f.season, !c.seasons.contains(s) { return false }
            if let d = f.difficulty, c.difficulty != d { return false }
            if let sp = f.requiredSpace, c.requiredSpace != sp { return false }
            if let q, !q.isEmpty {
                let hay = "\(c.name) \(c.nameKana) \(c.summary)".lowercased()
                if !hay.contains(q) { return false }
            }
            return true
        }
    }

    func featuredChallenges(now: Date = Date()) -> [Challenge] {
        let m = Calendar.current.component(.month, from: now)
        return challenges.filter { $0.featuredMonths?.contains(m) == true }
    }

    func isFeatured(_ challenge: Challenge, now: Date = Date()) -> Bool {
        let m = Calendar.current.component(.month, from: now)
        return challenge.featuredMonths?.contains(m) == true
    }
}

private func decodeBundled<T: Decodable>(_ name: String, bundle: Bundle) -> T {
    guard let url = bundle.url(forResource: name, withExtension: "json") else {
        fatalError("Missing bundled resource \(name).json")
    }
    do {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        fatalError("Failed to decode \(name).json: \(error)")
    }
}
