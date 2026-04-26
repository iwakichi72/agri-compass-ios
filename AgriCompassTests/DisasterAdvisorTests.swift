import XCTest
@testable import AgriCompass

final class DisasterAdvisorTests: XCTestCase {
    private var catalog: CatalogStore!

    override func setUp() {
        super.setUp()
        catalog = CatalogStore.load()
    }

    private func mkDay(_ offsetDays: Int = 0,
                       tempMin: Int = 18,
                       tempMax: Int = 26,
                       condition: WeatherCondition = .sunny,
                       precipitationMm: Int = 0,
                       windMps: Int = 3) -> WeatherDay {
        WeatherDay(date: DateUtils.addDays(Date(), offsetDays),
                   tempMin: tempMin, tempMax: tempMax,
                   condition: condition, precipitationMm: precipitationMm, windMps: windMps)
    }

    private func forecast(today: WeatherDay, next: [WeatherDay] = []) -> WeatherForecast {
        WeatherForecast(region: .kanto, fetchedAt: Date(), today: today, next: next)
    }

    func testCalmWeatherProducesNoAlerts() {
        let alerts = DisasterAdvisor.alerts(
            forecast: forecast(today: mkDay()),
            activeCrops: [], cropResolver: { catalog.crop(id: $0) }
        )
        XCTAssertEqual(alerts.count, 0)
    }

    func testTyphoonDetected() {
        let day = mkDay(condition: .rain, precipitationMm: 80, windMps: 18)
        let alerts = DisasterAdvisor.alerts(
            forecast: forecast(today: day),
            activeCrops: [], cropResolver: { catalog.crop(id: $0) }
        )
        XCTAssertEqual(alerts.first?.kind, .typhoon)
        XCTAssertEqual(alerts.first?.severity, .warning)
        XCTAssertFalse(alerts.first?.actions.isEmpty ?? true)
    }

    func testHeatwaveLimitedToHeatSensitiveCrops() throws {
        let crop = try XCTUnwrap(catalog.crops.first(where: { $0.weatherNotes.heatSensitive }))
        let other = try XCTUnwrap(catalog.crops.first(where: { !$0.weatherNotes.heatSensitive }))
        let acs = [
            ActiveCropEntity(cropId: crop.id, plantedAt: Date()),
            ActiveCropEntity(cropId: other.id, plantedAt: Date())
        ]
        let day = mkDay(tempMax: 36)
        let alerts = DisasterAdvisor.alerts(
            forecast: forecast(today: day),
            activeCrops: acs, cropResolver: { catalog.crop(id: $0) }
        )
        let heat = try XCTUnwrap(alerts.first(where: { $0.kind == .heatwave }))
        XCTAssertEqual(heat.affectedCropNames.count, 1)
        XCTAssertEqual(heat.affectedCropNames.first, crop.name)
    }

    func testFutureDayAlertCarriesLeadDays() {
        let alerts = DisasterAdvisor.alerts(
            forecast: forecast(today: mkDay(),
                               next: [mkDay(1), mkDay(2, tempMin: 0)]),
            activeCrops: [], cropResolver: { catalog.crop(id: $0) }
        )
        let frost = alerts.first(where: { $0.kind == .frost })
        XCTAssertEqual(frost?.leadDays, 2)
        XCTAssertEqual(frost?.leadLabel, "2日後")
    }

    func testEachKindReportedOnce() {
        let alerts = DisasterAdvisor.alerts(
            forecast: forecast(
                today: mkDay(tempMax: 36),
                next: [mkDay(1, tempMax: 37), mkDay(2, tempMax: 38)]
            ),
            activeCrops: [], cropResolver: { catalog.crop(id: $0) }
        )
        XCTAssertEqual(alerts.filter { $0.kind == .heatwave }.count, 1)
    }
}
