import Foundation

enum WateringRecommendation: Hashable {
    case skipRain
    case skipRecent
    case dueToday
    case dueIn(days: Int)
    case neverWatered

    var headline: String {
        switch self {
        case .skipRain: "今日は雨でお休み"
        case .skipRecent: "まだ土が湿っています"
        case .dueToday: "今日あげましょう"
        case .dueIn(let d): "あと\(d)日が目安"
        case .neverWatered: "まずは1回あげましょう"
        }
    }

    var isDue: Bool {
        switch self {
        case .dueToday, .neverWatered: true
        default: false
        }
    }
}

struct CropWateringStatus: Hashable, Identifiable {
    let instanceId: String
    let cropId: String
    let cropName: String
    let emoji: String
    let recommendation: WateringRecommendation
    let lastWateredAt: Date?
    let intervalDays: Int

    var id: String { instanceId }
}

struct WateringSummary: Hashable {
    let dueToday: [CropWateringStatus]
    let upcoming: [CropWateringStatus]
    let resting: [CropWateringStatus]

    var hasAnyCrops: Bool {
        !(dueToday.isEmpty && upcoming.isEmpty && resting.isEmpty)
    }
}

enum WateringAdvisor {
    /// Suggested days between waterings, derived from crop traits and today's weather.
    static func intervalDays(crop: Crop, today: WeatherDay) -> Int {
        var days = 2
        if crop.weatherNotes.heatSensitive { days = 1 }
        if crop.requiredSpace == .pot { days = max(1, days - 1) }
        if today.tempMax >= 30 { days = max(1, days - 1) }
        if today.tempMax <= 12 { days += 2 } else if today.tempMax <= 18 { days += 1 }
        return days
    }

    static func status(activeCrop: ActiveCropEntity,
                       crop: Crop,
                       forecast: WeatherForecast,
                       now: Date = Date()) -> CropWateringStatus {
        let interval = intervalDays(crop: crop, today: forecast.today)
        let last = activeCrop.lastWateredAt
        let recommendation: WateringRecommendation = {
            if forecast.today.condition == .rain && forecast.today.precipitationMm >= 5 {
                return .skipRain
            }
            guard let last else {
                return .neverWatered
            }
            let elapsed = DateUtils.diffDays(last, now)
            if elapsed <= 0 { return .skipRecent }
            if elapsed >= interval { return .dueToday }
            if interval >= 2 && elapsed == interval - 1 { return .dueIn(days: 1) }
            return .skipRecent
        }()
        return CropWateringStatus(
            instanceId: activeCrop.instanceId,
            cropId: activeCrop.cropId,
            cropName: activeCrop.nickname ?? crop.name,
            emoji: crop.emoji,
            recommendation: recommendation,
            lastWateredAt: last,
            intervalDays: interval
        )
    }

    static func summary(activeCrops: [ActiveCropEntity],
                       forecast: WeatherForecast,
                       cropResolver: (String) -> Crop?,
                       now: Date = Date()) -> WateringSummary {
        var due: [CropWateringStatus] = []
        var upcoming: [CropWateringStatus] = []
        var resting: [CropWateringStatus] = []
        for ac in Selectors.growingCrops(activeCrops) {
            guard let crop = cropResolver(ac.cropId) else { continue }
            let s = status(activeCrop: ac, crop: crop, forecast: forecast, now: now)
            switch s.recommendation {
            case .dueToday, .neverWatered: due.append(s)
            case .dueIn: upcoming.append(s)
            case .skipRain, .skipRecent: resting.append(s)
            }
        }
        return WateringSummary(dueToday: due, upcoming: upcoming, resting: resting)
    }
}
