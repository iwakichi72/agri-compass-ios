import Foundation

enum StreakCalculator {
    static let milestones: [Int] = [7, 14, 30, 100]

    struct Previous {
        let streakDays: Int
        let maxStreakDays: Int
        let lastVisitDate: String?
    }

    struct Result {
        let streakDays: Int
        let maxStreakDays: Int
        let lastVisitDate: String
        let crossedMilestone: Int?
    }

    static func compute(previous: Previous, now: Date = Date()) -> Result {
        let today = DateUtils.dateOnlyISO(now)

        guard let last = previous.lastVisitDate else {
            let streak = 1
            return Result(
                streakDays: streak,
                maxStreakDays: max(previous.maxStreakDays, streak),
                lastVisitDate: today,
                crossedMilestone: milestones.contains(streak) ? streak : nil
            )
        }

        if last == today {
            return Result(
                streakDays: previous.streakDays,
                maxStreakDays: previous.maxStreakDays,
                lastVisitDate: today,
                crossedMilestone: nil
            )
        }

        let dayCount: Int = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            f.timeZone = TimeZone.current
            guard let lastDate = f.date(from: last) else { return 1 }
            return DateUtils.diffDays(lastDate, now)
        }()

        let streak = dayCount == 1 ? previous.streakDays + 1 : 1
        let maxStreakDays = max(previous.maxStreakDays, streak)
        let crossed = (streak > previous.streakDays && milestones.contains(streak)) ? streak : nil

        return Result(
            streakDays: streak,
            maxStreakDays: maxStreakDays,
            lastVisitDate: today,
            crossedMilestone: crossed
        )
    }
}
