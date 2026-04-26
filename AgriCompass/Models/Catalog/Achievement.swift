import Foundation

struct Achievement: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let hidden: Bool

    enum CodingKeys: String, CodingKey { case id, name, description, icon, category, hidden }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.name = try c.decode(String.self, forKey: .name)
        self.description = try c.decode(String.self, forKey: .description)
        self.icon = try c.decode(String.self, forKey: .icon)
        self.category = try c.decode(AchievementCategory.self, forKey: .category)
        self.hidden = try c.decodeIfPresent(Bool.self, forKey: .hidden) ?? false
    }
}
