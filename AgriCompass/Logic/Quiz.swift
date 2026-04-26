import Foundation

enum QuizExperience: String, Hashable { case none, some }
enum QuizMotivation: String, Hashable {
    case rewardFast = "reward-fast"
    case rewardCook = "reward-cook"
    case rewardLong = "reward-long"
}
enum QuizSeasonOption: Hashable {
    case any
    case season(Season)
}

struct QuizAnswers {
    var space: RequiredSpace
    var experience: QuizExperience
    var motivation: QuizMotivation
    var season: QuizSeasonOption
}

struct QuizResult: Identifiable, Hashable {
    let crop: Crop
    let score: Int
    let reasons: [String]
    var id: String { crop.id }
}

enum QuizEngine {
    static func score(answers: QuizAnswers, region: Region?, crops: [Crop], now: Date = Date()) -> [QuizResult] {
        let season: Season = {
            switch answers.season {
            case .any: return Season.of(date: now)
            case .season(let s): return s
            }
        }()
        return crops
            .filter { region == nil || $0.regionAvailability.contains(region!) }
            .map { c -> QuizResult in
                var reasons: [String] = []
                var score = 0
                if c.seasons.contains(season) {
                    score += 4
                    reasons.append("いまの季節に合う")
                }
                let spaceMatch: Bool = {
                    if c.requiredSpace == answers.space { return true }
                    if answers.space == .large && [.small, .medium, .large].contains(c.requiredSpace) { return true }
                    if answers.space == .medium && [.pot, .small, .medium].contains(c.requiredSpace) { return true }
                    return false
                }()
                if spaceMatch {
                    score += 2
                    reasons.append("育てられる広さに合う")
                }
                if answers.experience == .none && c.difficulty == .easy {
                    score += 3
                    reasons.append("初心者にやさしい")
                }
                if answers.experience == .some && c.difficulty != .hard {
                    score += 1
                }
                if answers.motivation == .rewardFast && c.harvestGuide.daysFromSowing.ready <= 40 {
                    score += 3
                    reasons.append("早く収穫できる")
                }
                if answers.motivation == .rewardCook && c.category == .fruit {
                    score += 3
                    reasons.append("食卓に並ぶ定番")
                }
                if answers.motivation == .rewardLong && (c.category == .fruit || c.category == .bean) {
                    score += 2
                    reasons.append("長く収穫を楽しめる")
                }
                return QuizResult(crop: c, score: score, reasons: reasons)
            }
            .filter { $0.score > 0 }
            .sorted { $0.score > $1.score }
            .prefix(5)
            .map { $0 }
    }
}
