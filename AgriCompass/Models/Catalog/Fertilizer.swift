import Foundation

struct Fertilizer: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let emoji: String
    let kind: FertilizerKind
    let nutrients: FertilizerNutrients
    let description: String
    let applyHint: String
    let buyHint: String?
}
