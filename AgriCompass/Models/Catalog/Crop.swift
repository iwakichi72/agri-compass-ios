import Foundation

struct SowingWindow: Codable, Hashable, Sendable {
    let startMonth: Int
    let startDay: Int
    let endMonth: Int
    let endDay: Int

    var label: String { "\(startMonth)/\(startDay)〜\(endMonth)/\(endDay)" }

    func contains(_ d: Date, calendar: Calendar = .current) -> Bool {
        let y = calendar.component(.year, from: d)
        let startComps = DateComponents(year: y, month: startMonth, day: startDay)
        let endComps = DateComponents(year: y, month: endMonth, day: endDay, hour: 23, minute: 59, second: 59)
        guard let start = calendar.date(from: startComps),
              let end = calendar.date(from: endComps) else { return false }
        if start <= end {
            return d >= start && d <= end
        } else {
            return d >= start || d <= end
        }
    }
}

struct ToolUsage: Codable, Hashable, Sendable {
    let toolId: String
    let required: Bool
    let note: String?

    enum CodingKeys: String, CodingKey { case toolId, required, note }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.toolId = try c.decode(String.self, forKey: .toolId)
        self.required = try c.decodeIfPresent(Bool.self, forKey: .required) ?? false
        self.note = try c.decodeIfPresent(String.self, forKey: .note)
    }
}

struct FertilizerUsage: Codable, Hashable, Sendable {
    let fertilizerId: String
    let required: Bool
    let amount: String?
    let note: String?

    enum CodingKeys: String, CodingKey { case fertilizerId, required, amount, note }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.fertilizerId = try c.decode(String.self, forKey: .fertilizerId)
        self.required = try c.decodeIfPresent(Bool.self, forKey: .required) ?? false
        self.amount = try c.decodeIfPresent(String.self, forKey: .amount)
        self.note = try c.decodeIfPresent(String.self, forKey: .note)
    }
}

struct CropStep: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let why: String
    let daysFromStart: Int
    let durationDays: Int?
    let tools: [String]?
    let fertilizers: [FertilizerUsage]?
}

struct HarvestGuideDays: Codable, Hashable, Sendable {
    let early: Int
    let ready: Int
    let late: Int
}

struct HarvestGuide: Codable, Hashable, Sendable {
    let sizeHint: String
    let colorHint: String
    let daysFromSowing: HarvestGuideDays
    let earlyCriteria: String
    let readyCriteria: String
    let lateCriteria: String
    let imagePlaceholder: String?
}

struct WeatherNotes: Codable, Hashable, Sendable {
    let wateringRule: String
    let frostSensitive: Bool
    let heatSensitive: Bool
    let note: String?
}

struct Crop: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let nameKana: String
    let emoji: String
    let summary: String
    let regionAvailability: [Region]
    let seasons: [Season]
    let difficulty: Difficulty
    let requiredSpace: RequiredSpace
    let sowingWindows: [Region: [SowingWindow]]
    let steps: [CropStep]
    let harvestGuide: HarvestGuide
    let rotationFamily: String
    let avoidAfter: [String]
    let recommendedNext: [String]
    let weatherNotes: WeatherNotes
    let category: CropCategory
    let starterTools: [ToolUsage]?
    let starterFertilizers: [FertilizerUsage]?

    enum CodingKeys: String, CodingKey {
        case id, name, nameKana, emoji, summary, regionAvailability, seasons,
             difficulty, requiredSpace, sowingWindows, steps, harvestGuide,
             rotationFamily, avoidAfter, recommendedNext, weatherNotes, category,
             starterTools, starterFertilizers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.nameKana = try c.decode(String.self, forKey: .nameKana)
        self.emoji = try c.decode(String.self, forKey: .emoji)
        self.summary = try c.decode(String.self, forKey: .summary)
        self.regionAvailability = try c.decode([Region].self, forKey: .regionAvailability)
        self.seasons = try c.decode([Season].self, forKey: .seasons)
        self.difficulty = try c.decode(Difficulty.self, forKey: .difficulty)
        self.requiredSpace = try c.decode(RequiredSpace.self, forKey: .requiredSpace)
        self.steps = try c.decode([CropStep].self, forKey: .steps)
        self.harvestGuide = try c.decode(HarvestGuide.self, forKey: .harvestGuide)
        self.rotationFamily = try c.decode(String.self, forKey: .rotationFamily)
        self.avoidAfter = try c.decode([String].self, forKey: .avoidAfter)
        self.recommendedNext = try c.decode([String].self, forKey: .recommendedNext)
        self.weatherNotes = try c.decode(WeatherNotes.self, forKey: .weatherNotes)
        self.category = try c.decode(CropCategory.self, forKey: .category)
        self.starterTools = try c.decodeIfPresent([ToolUsage].self, forKey: .starterTools)
        self.starterFertilizers = try c.decodeIfPresent([FertilizerUsage].self, forKey: .starterFertilizers)

        // sowingWindows is keyed by region rawValue (e.g. "kanto", "kyushu_okinawa").
        let windowsRaw = try c.decode([String: [SowingWindow]].self, forKey: .sowingWindows)
        var windows: [Region: [SowingWindow]] = [:]
        for (key, value) in windowsRaw {
            if let region = Region(rawValue: key) {
                windows[region] = value
            }
        }
        self.sowingWindows = windows
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(nameKana, forKey: .nameKana)
        try c.encode(emoji, forKey: .emoji)
        try c.encode(summary, forKey: .summary)
        try c.encode(regionAvailability, forKey: .regionAvailability)
        try c.encode(seasons, forKey: .seasons)
        try c.encode(difficulty, forKey: .difficulty)
        try c.encode(requiredSpace, forKey: .requiredSpace)
        try c.encode(steps, forKey: .steps)
        try c.encode(harvestGuide, forKey: .harvestGuide)
        try c.encode(rotationFamily, forKey: .rotationFamily)
        try c.encode(avoidAfter, forKey: .avoidAfter)
        try c.encode(recommendedNext, forKey: .recommendedNext)
        try c.encode(weatherNotes, forKey: .weatherNotes)
        try c.encode(category, forKey: .category)
        try c.encodeIfPresent(starterTools, forKey: .starterTools)
        try c.encodeIfPresent(starterFertilizers, forKey: .starterFertilizers)
        var windowsRaw: [String: [SowingWindow]] = [:]
        for (region, ws) in sowingWindows { windowsRaw[region.rawValue] = ws }
        try c.encode(windowsRaw, forKey: .sowingWindows)
    }
}
