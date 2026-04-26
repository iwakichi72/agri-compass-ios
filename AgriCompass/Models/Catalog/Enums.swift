import Foundation

enum Region: String, Codable, CaseIterable, Hashable, Sendable {
    case hokkaido
    case tohoku
    case kanto
    case chubu
    case kansai
    case chugoku
    case shikoku
    case kyushuOkinawa = "kyushu_okinawa"

    var label: String {
        switch self {
        case .hokkaido: "北海道"
        case .tohoku: "東北"
        case .kanto: "関東"
        case .chubu: "中部"
        case .kansai: "関西"
        case .chugoku: "中国"
        case .shikoku: "四国"
        case .kyushuOkinawa: "九州・沖縄"
        }
    }
}

enum Season: String, Codable, CaseIterable, Hashable, Sendable {
    case spring, summer, autumn, winter

    var label: String {
        switch self {
        case .spring: "春"
        case .summer: "夏"
        case .autumn: "秋"
        case .winter: "冬"
        }
    }

    static func of(date: Date = Date()) -> Season {
        let m = Calendar.current.component(.month, from: date)
        switch m {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Hashable, Sendable {
    case easy, medium, hard
    var label: String {
        switch self {
        case .easy: "やさしい"
        case .medium: "ふつう"
        case .hard: "むずかしい"
        }
    }
}

enum RequiredSpace: String, Codable, CaseIterable, Hashable, Sendable {
    case pot, small, medium, large
    var label: String {
        switch self {
        case .pot: "プランター"
        case .small: "小さめ"
        case .medium: "普通"
        case .large: "広め"
        }
    }
}

enum CropCategory: String, Codable, Hashable, Sendable {
    case leaf, fruit, root, bean, other
}

enum ToolCategory: String, Codable, Hashable, Sendable {
    case container, support, cutting, watering, soil, cover, other
    var label: String {
        switch self {
        case .container: "容器"
        case .support: "支柱・誘引"
        case .cutting: "切る道具"
        case .watering: "水やり"
        case .soil: "土・植え付け"
        case .cover: "被せもの"
        case .other: "その他"
        }
    }
}

enum FertilizerKind: String, Codable, Hashable, Sendable {
    case basal
    case topDress = "top-dress"
    case liquid
    case organic
}

enum FertilizerNutrients: String, Codable, Hashable, Sendable {
    case n = "N"
    case p = "P"
    case k = "K"
    case mixed
}

enum AchievementCategory: String, Codable, Hashable, Sendable {
    case growing, knowledge, season, hidden
}

enum CropStatus: String, Codable, Hashable, Sendable {
    case growing, harvested, abandoned
}
