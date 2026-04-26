import Foundation

enum TipCategory: String, Codable, Hashable, Sendable, CaseIterable {
    case watering, soil, disaster, harvest, beginner, season, pest

    var label: String {
        switch self {
        case .watering: "水やり"
        case .soil: "土づくり"
        case .disaster: "天災対策"
        case .harvest: "収穫"
        case .beginner: "はじめて"
        case .season: "季節"
        case .pest: "虫・病気"
        }
    }

    var emoji: String {
        switch self {
        case .watering: "💧"
        case .soil: "🪴"
        case .disaster: "🌀"
        case .harvest: "🥕"
        case .beginner: "🌱"
        case .season: "📅"
        case .pest: "🐛"
        }
    }
}

struct Tip: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let category: TipCategory
    let title: String
    let body: String
    let seasons: [Season]?
    let cropTags: [String]?
}
