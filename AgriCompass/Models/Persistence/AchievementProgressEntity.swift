import Foundation
import SwiftData

@Model
final class AchievementProgressEntity {
    @Attribute(.unique) var achievementId: String
    var unlockedAt: Date

    init(achievementId: String, unlockedAt: Date = Date()) {
        self.achievementId = achievementId
        self.unlockedAt = unlockedAt
    }
}
