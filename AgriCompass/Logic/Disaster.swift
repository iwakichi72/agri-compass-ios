import Foundation

struct DisasterAlert: Hashable, Identifiable {
    enum Kind: String, Hashable {
        case typhoon, heavyRain, strongWind, snow, heatwave, frost
    }

    enum Severity: Hashable {
        case watch
        case warning

        var label: String {
            switch self {
            case .watch: "注意"
            case .warning: "警戒"
            }
        }
    }

    let kind: Kind
    let severity: Severity
    let title: String
    let leadDays: Int
    let summary: String
    let actions: [String]
    let affectedCropNames: [String]

    var id: String { "\(kind.rawValue)-\(leadDays)" }

    var emoji: String {
        switch kind {
        case .typhoon: "🌀"
        case .heavyRain: "🌧️"
        case .strongWind: "💨"
        case .snow: "❄️"
        case .heatwave: "🥵"
        case .frost: "🧊"
        }
    }

    var leadLabel: String {
        switch leadDays {
        case 0: "今日"
        case 1: "明日"
        default: "\(leadDays)日後"
        }
    }
}

enum DisasterAdvisor {
    /// Inspect today + the next 3 days and return any disaster alerts that
    /// warrant a heads-up to the gardener.
    static func alerts(forecast: WeatherForecast,
                       activeCrops: [ActiveCropEntity],
                       cropResolver: (String) -> Crop?,
                       now: Date = Date()) -> [DisasterAlert] {
        let days: [(offset: Int, day: WeatherDay)] =
            [(0, forecast.today)] + forecast.next.enumerated().map { ($0.offset + 1, $0.element) }

        var seen = Set<DisasterAlert.Kind>()
        var alerts: [DisasterAlert] = []

        let growing = Selectors.growingCrops(activeCrops).compactMap { ac -> (ActiveCropEntity, Crop)? in
            guard let c = cropResolver(ac.cropId) else { return nil }
            return (ac, c)
        }

        for (offset, day) in days where offset <= 3 {
            for kind in detectKinds(day: day) where !seen.contains(kind) {
                seen.insert(kind)
                alerts.append(buildAlert(kind: kind, leadDays: offset, day: day, growing: growing))
            }
        }
        return alerts.sorted { $0.leadDays < $1.leadDays }
    }

    private static func detectKinds(day: WeatherDay) -> [DisasterAlert.Kind] {
        var kinds: [DisasterAlert.Kind] = []
        if day.windMps >= 15 && day.precipitationMm >= 30 {
            kinds.append(.typhoon)
        } else {
            if day.precipitationMm >= 30 { kinds.append(.heavyRain) }
            if day.windMps >= 12 { kinds.append(.strongWind) }
        }
        if day.condition == .snow || day.precipitationMm >= 20 && day.tempMax <= 2 {
            kinds.append(.snow)
        }
        if day.tempMax >= 35 { kinds.append(.heatwave) }
        if day.tempMin <= 1 { kinds.append(.frost) }
        return kinds
    }

    private static func buildAlert(kind: DisasterAlert.Kind,
                                   leadDays: Int,
                                   day: WeatherDay,
                                   growing: [(ActiveCropEntity, Crop)]) -> DisasterAlert {
        let affected = affectedNames(kind: kind, growing: growing)
        switch kind {
        case .typhoon:
            return DisasterAlert(
                kind: .typhoon,
                severity: .warning,
                title: "台風が近づいています",
                leadDays: leadDays,
                summary: "風\(day.windMps)m/s・雨\(day.precipitationMm)mmの予報。畑の上を強い風雨が通過しそうです。",
                actions: [
                    "支柱と誘引ひもを増し締めする",
                    "鉢・プランターは壁ぎわや屋内に避難する",
                    "収穫できる果実は早めに収穫する",
                    "排水口まわりの落ち葉を片づける"
                ],
                affectedCropNames: affected
            )
        case .heavyRain:
            return DisasterAlert(
                kind: .heavyRain,
                severity: .warning,
                title: "大雨の予報です",
                leadDays: leadDays,
                summary: "1日に\(day.precipitationMm)mm前後の雨が降りそうです。根が浸かると弱ってしまいます。",
                actions: [
                    "畝の周りに排水の溝を切る",
                    "鉢は雨の当たりにくい場所へ移す",
                    "肥料袋・支柱などを片づけ風で飛ばないようにする"
                ],
                affectedCropNames: affected
            )
        case .strongWind:
            return DisasterAlert(
                kind: .strongWind,
                severity: .watch,
                title: "強い風が吹きそうです",
                leadDays: leadDays,
                summary: "風速\(day.windMps)m/sの予報。茎折れや葉ずれが起きやすい日です。",
                actions: [
                    "背の高い株に支柱を追加する",
                    "防風ネットや不織布で軽く覆う",
                    "ベランダの鉢は床に下ろしておく"
                ],
                affectedCropNames: affected
            )
        case .snow:
            return DisasterAlert(
                kind: .snow,
                severity: .watch,
                title: "雪に注意",
                leadDays: leadDays,
                summary: "気温が下がり積雪・凍結のおそれがあります。",
                actions: [
                    "寒さに弱い苗は不織布や段ボールで覆う",
                    "鉢は壁際や軒下に寄せる",
                    "通路にビニールを敷いて踏み固めを防ぐ"
                ],
                affectedCropNames: affected
            )
        case .heatwave:
            return DisasterAlert(
                kind: .heatwave,
                severity: .warning,
                title: "猛暑の予報",
                leadDays: leadDays,
                summary: "最高気温\(day.tempMax)℃。土が一気に乾き、葉焼けも起きやすい日です。",
                actions: [
                    "朝のうちにたっぷり水やりをする",
                    "寒冷紗や葦簀で日中の直射を遮る",
                    "敷きわらやマルチで地温の上昇を抑える",
                    "作業は午前7時前か日没後にする"
                ],
                affectedCropNames: affected
            )
        case .frost:
            return DisasterAlert(
                kind: .frost,
                severity: .warning,
                title: "霜のおそれ",
                leadDays: leadDays,
                summary: "明け方の最低気温\(day.tempMin)℃。霜で葉が傷むおそれがあります。",
                actions: [
                    "夕方に不織布やビニールで覆う",
                    "鉢は屋内・軒下に取り込む",
                    "朝、霜が付いていたら太陽が当たる前に水で軽く流す"
                ],
                affectedCropNames: affected
            )
        }
    }

    private static func affectedNames(kind: DisasterAlert.Kind,
                                      growing: [(ActiveCropEntity, Crop)]) -> [String] {
        let filtered: [(ActiveCropEntity, Crop)]
        switch kind {
        case .frost, .snow:
            filtered = growing.filter { $0.1.weatherNotes.frostSensitive }
        case .heatwave:
            filtered = growing.filter { $0.1.weatherNotes.heatSensitive }
        case .typhoon, .strongWind, .heavyRain:
            filtered = growing
        }
        return filtered.map { $0.0.nickname ?? $0.1.name }
    }
}
