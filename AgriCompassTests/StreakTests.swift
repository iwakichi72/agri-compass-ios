import XCTest
@testable import AgriCompass

final class StreakTests: XCTestCase {
    func testFirstVisitStartsAtOne() {
        let r = StreakCalculator.compute(previous: .init(streakDays: 0, maxStreakDays: 0, lastVisitDate: nil))
        XCTAssertEqual(r.streakDays, 1)
        XCTAssertEqual(r.maxStreakDays, 1)
    }

    func testSameDayDoesNotIncrement() {
        let now = Date()
        let today = DateUtils.dateOnlyISO(now)
        let r = StreakCalculator.compute(
            previous: .init(streakDays: 5, maxStreakDays: 5, lastVisitDate: today),
            now: now
        )
        XCTAssertEqual(r.streakDays, 5)
        XCTAssertNil(r.crossedMilestone)
    }

    func testConsecutiveDayIncrements() {
        let now = Date()
        let yesterday = DateUtils.addDays(now, -1)
        let yISO = DateUtils.dateOnlyISO(yesterday)
        let r = StreakCalculator.compute(
            previous: .init(streakDays: 6, maxStreakDays: 6, lastVisitDate: yISO),
            now: now
        )
        XCTAssertEqual(r.streakDays, 7)
        XCTAssertEqual(r.crossedMilestone, 7)
    }

    func testGapResetsStreak() {
        let now = Date()
        let threeAgo = DateUtils.addDays(now, -3)
        let iso = DateUtils.dateOnlyISO(threeAgo)
        let r = StreakCalculator.compute(
            previous: .init(streakDays: 10, maxStreakDays: 10, lastVisitDate: iso),
            now: now
        )
        XCTAssertEqual(r.streakDays, 1)
        XCTAssertEqual(r.maxStreakDays, 10)
    }
}
