import Foundation
import SwiftData

@Model
final class ChallengeProgressEntity {
    @Attribute(.unique) var challengeId: String
    var joined: Bool
    var goalProgress: [String: Int]
    var completedAt: Date?

    init(challengeId: String,
         joined: Bool = false,
         goalProgress: [String: Int] = [:],
         completedAt: Date? = nil) {
        self.challengeId = challengeId
        self.joined = joined
        self.goalProgress = goalProgress
        self.completedAt = completedAt
    }
}
