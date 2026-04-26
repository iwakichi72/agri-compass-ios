import XCTest
@testable import AgriCompass

final class WateringAdvisorTests: XCTestCase {
    private var catalog: CatalogStore!

    override func setUp() {
        super.setUp()
        catalog = CatalogStore.load()
    }

    private func sunnyDay(temp: Int = 25) -> WeatherDay {
        WeatherDay(date: Date(), tempMin: temp - 8, tempMax: temp,
                   condition: .sunny, precipitationMm: 0, windMps: 3)
    }

    private func rainyDay() -> WeatherDay {
        WeatherDay(date: Date(), tempMin: 18, tempMax: 22,
                   condition: .rain, precipitationMm: 12, windMps: 4)
    }

    private func forecast(today: WeatherDay) -> WeatherForecast {
        WeatherForecast(region: .kanto, fetchedAt: Date(),
                        today: today, next: [today, today, today])
    }

    func testNeverWateredIsDueToday() throws {
        let crop = try XCTUnwrap(catalog.crop(id: "mini-tomato"))
        let ac = ActiveCropEntity(cropId: crop.id, plantedAt: Date(), lastWateredAt: nil)
        let s = WateringAdvisor.status(activeCrop: ac, crop: crop, forecast: forecast(today: sunnyDay()))
        XCTAssertEqual(s.recommendation, .neverWatered)
        XCTAssertTrue(s.recommendation.isDue)
    }

    func testRainSkipsEvenIfDue() throws {
        let crop = try XCTUnwrap(catalog.crop(id: "mini-tomato"))
        let ac = ActiveCropEntity(cropId: crop.id, plantedAt: Date(),
                                  lastWateredAt: DateUtils.addDays(Date(), -10))
        let s = WateringAdvisor.status(activeCrop: ac, crop: crop, forecast: forecast(today: rainyDay()))
        XCTAssertEqual(s.recommendation, .skipRain)
        XCTAssertFalse(s.recommendation.isDue)
    }

    func testRecentWateringIsResting() throws {
        let crop = try XCTUnwrap(catalog.crop(id: "mini-tomato"))
        let ac = ActiveCropEntity(cropId: crop.id, plantedAt: Date(), lastWateredAt: Date())
        let s = WateringAdvisor.status(activeCrop: ac, crop: crop, forecast: forecast(today: sunnyDay()))
        XCTAssertEqual(s.recommendation, .skipRecent)
    }

    func testColdDayLengthensInterval() throws {
        let crop = try XCTUnwrap(catalog.crop(id: "mini-tomato"))
        let mild = WateringAdvisor.intervalDays(crop: crop, today: sunnyDay(temp: 22))
        let cold = WateringAdvisor.intervalDays(crop: crop, today: sunnyDay(temp: 8))
        XCTAssertGreaterThan(cold, mild)
    }

    func testSummaryBucketsCrops() throws {
        let crop = try XCTUnwrap(catalog.crop(id: "mini-tomato"))
        let dueAC = ActiveCropEntity(cropId: crop.id, plantedAt: Date(),
                                     lastWateredAt: DateUtils.addDays(Date(), -10))
        let restingAC = ActiveCropEntity(cropId: crop.id, plantedAt: Date(),
                                         lastWateredAt: Date())
        let summary = WateringAdvisor.summary(
            activeCrops: [dueAC, restingAC],
            forecast: forecast(today: sunnyDay()),
            cropResolver: { catalog.crop(id: $0) }
        )
        XCTAssertEqual(summary.dueToday.count, 1)
        XCTAssertEqual(summary.resting.count, 1)
    }
}
