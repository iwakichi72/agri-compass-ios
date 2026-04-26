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

    static func mockForecast(region: Region, now: Date = Date()) -> WeatherForecast {
        let m = Calendar.current.component(.month, from: now)
        let d = Calendar.current.component(.day, from: now)
        let base = (m >= 6 && m <= 8) ? 28 : (m >= 12 || m <= 2) ? 5 : 18
        let bias = regionTempBias[region] ?? 0
        let seed = d + m

        func day(offset: Int) -> WeatherDay {
            let dayOfWeek = (seed + offset) % 7
            let condition: WeatherCondition
            if dayOfWeek == 2 {
                condition = .rain
            } else if dayOfWeek == 5 {
                condition = .cloudy
            } else if dayOfWeek == 6 && m <= 2 {
                condition = .snow
            } else {
                condition = .sunny
            }
            let variance = (offset * 3) % 5
            let tempMax = base + bias + variance + (condition == .sunny ? 2 : -1)
            let tempMin = tempMax - ((m >= 12 || m <= 2) ? 5 : 8)
            let precip = condition == .rain ? 8 : condition == .snow ? 3 : 0
            return WeatherDay(
                date: DateUtils.addDays(now, offset),
                tempMin: tempMin,
                tempMax: tempMax,
                condition: condition,
                precipitationMm: precip
            )
        }

        return WeatherForecast(
            region: region,
            fetchedAt: now,
            today: day(offset: 0),
            next: [day(offset: 1), day(offset: 2), day(offset: 3)]
        )
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
