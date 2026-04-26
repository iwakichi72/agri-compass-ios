import Foundation

enum WeatherCondition: String, Codable, Hashable {
    case sunny, cloudy, rain, snow

    var icon: String {
        switch self {
        case .sunny: "☀️"
        case .cloudy: "☁️"
        case .rain: "🌧️"
        case .snow: "❄️"
        }
    }
}

struct WeatherDay: Hashable {
    let date: Date
    let tempMin: Int
    let tempMax: Int
    let condition: WeatherCondition
    let precipitationMm: Int
    let windMps: Int

    init(date: Date,
         tempMin: Int,
         tempMax: Int,
         condition: WeatherCondition,
         precipitationMm: Int,
         windMps: Int = 3) {
        self.date = date
        self.tempMin = tempMin
        self.tempMax = tempMax
        self.condition = condition
        self.precipitationMm = precipitationMm
        self.windMps = windMps
    }
}

struct WeatherForecast: Hashable {
    let region: Region
    let fetchedAt: Date
    let today: WeatherDay
    let next: [WeatherDay]
}

struct WeatherAdviceData: Hashable {
    enum Kind: String { case watering, frost, heat, calm }
    enum Tone: String { case info, warn, alert }
    let kind: Kind
    let tone: Tone
    let headline: String
    let body: String
}

enum WeatherService {
    private static let regionTempBias: [Region: Int] = [
        .hokkaido: -6, .tohoku: -3, .kanto: 0, .chubu: 0,
        .kansai: 1, .chugoku: 1, .shikoku: 2, .kyushuOkinawa: 3
    ]

    /// Deterministic mock weather for a single date. Same date always
    /// produces the same `WeatherDay`, which lets us paint weather chips on
    /// arbitrary days (e.g. the weekly calendar) consistently.
    static func mockDay(region: Region, date: Date) -> WeatherDay {
        let cal = DateUtils.calendar
        let m = cal.component(.month, from: date)
        let d = cal.component(.day, from: date)
        let base = (m >= 6 && m <= 8) ? 28 : (m >= 12 || m <= 2) ? 5 : 18
        let bias = regionTempBias[region] ?? 0
        let weekdaySeed = (d + m) % 7

        var condition: WeatherCondition
        switch weekdaySeed {
        case 2: condition = .rain
        case 5: condition = .cloudy
        case 6 where m <= 2: condition = .snow
        default: condition = .sunny
        }
        var precip = condition == .rain ? 8 : condition == .snow ? 3 : 0
        var wind = condition == .rain ? 5 : 3

        // Occasional typhoon-like burst (late summer / early autumn).
        let typhoonSeason = (m == 8 || m == 9 || m == 10)
        if typhoonSeason && (d % 11 == 1 || d % 11 == 2) {
            condition = .rain
            precip = 60
            wind = 18
        } else if (m == 6 || m == 7) && (d % 9 == 0) {
            condition = .rain
            precip = 35
            wind = 8
        }

        let variance = (d % 5)
        let tempMax = base + bias + variance + (condition == .sunny ? 2 : -1)
        let tempMin = tempMax - ((m >= 12 || m <= 2) ? 5 : 8)
        return WeatherDay(
            date: DateUtils.startOfDay(date),
            tempMin: tempMin,
            tempMax: tempMax,
            condition: condition,
            precipitationMm: precip,
            windMps: wind
        )
    }

    static func mockForecast(region: Region, now: Date = Date()) -> WeatherForecast {
        let today = mockDay(region: region, date: now)
        let next = (1...3).map { mockDay(region: region, date: DateUtils.addDays(now, $0)) }
        return WeatherForecast(region: region, fetchedAt: now, today: today, next: next)
    }

    static func deriveAdvice(forecast: WeatherForecast) -> WeatherAdviceData {
        let today = forecast.today
        let tomorrow = forecast.next.first

        let frostDays = [today, tomorrow].compactMap { $0 }.filter { $0.tempMin <= 3 }
        if !frostDays.isEmpty {
            return WeatherAdviceData(
                kind: .frost, tone: .alert,
                headline: "霜に注意する日です",
                body: "朝の気温が下がりそうです。寒さに弱い作物は不織布や段ボールで一時的に覆うと安心です。"
            )
        }
        if today.tempMax >= 33 {
            return WeatherAdviceData(
                kind: .heat, tone: .alert,
                headline: "猛暑の日です",
                body: "直射日光で土が乾きやすい日です。朝のうちにたっぷり水をやり、必要なら日よけを確認しましょう。"
            )
        }
        if today.condition == .rain || today.precipitationMm >= 3 {
            return WeatherAdviceData(
                kind: .watering, tone: .info,
                headline: "今日は水やりはお休みの日です",
                body: "雨が予想されます。土の湿り具合を見ながら、明日あらためて確認しましょう。"
            )
        }
        if today.tempMax >= 20 && today.precipitationMm < 1 {
            return WeatherAdviceData(
                kind: .watering, tone: .info,
                headline: "水やり向きの日です",
                body: "朝のうちに、土の表面が乾いている作物にたっぷり水をあげましょう。"
            )
        }
        return WeatherAdviceData(
            kind: .calm, tone: .info,
            headline: "今日は見守りの日です",
            body: "特別な作業はありません。葉の様子や土の色を眺めて、小さな変化を見つけてみましょう。"
        )
    }
}

enum HarvestStage: String, Hashable {
    case early, ready, late

    var label: String {
        switch self {
        case .early: "まだ早い"
        case .ready: "そろそろ〜食べごろ"
        case .late: "採りどき過ぎ"
        }
    }

    static func resolve(daysSincePlanting: Int, guide: HarvestGuide) -> HarvestStage {
        if daysSincePlanting < guide.daysFromSowing.ready { return .early }
        if daysSincePlanting >= guide.daysFromSowing.late { return .late }
        return .ready
    }
}
