import Foundation

struct ChallengeGoal: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let label: String
    let target: Int
}

struct Challenge: Codable, Hashable, Sendable, Identifiable {
    let id: String
    let season: Season
    let title: String
    let description: String
    let goals: [ChallengeGoal]
    let featuredMonths: [Int]?
}
