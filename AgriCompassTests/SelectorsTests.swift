import XCTest
@testable import AgriCompass

final class SelectorsTests: XCTestCase {
    private var catalog: CatalogStore!

    override func setUp() {
        super.setUp()
        catalog = CatalogStore.load()
    }

    func testGrowthStageProgressesByDaysSincePlanting() {
        guard let crop = catalog.crops.first(where: { $0.id == "mini-tomato" }) else {
            return XCTFail("mini-tomato missing")
        }
        let readyDays = crop.harvestGuide.daysFromSowing.ready
        let now = Date()

        let sproutPlanted = DateUtils.addDays(now, -Int(Double(readyDays) * 0.1))
        let sproutAC = ActiveCropEntity(cropId: crop.id, plantedAt: sproutPlanted)
        XCTAssertEqual(Selectors.growthStage(ac: sproutAC, crop: crop, now: now), .sprout)

        let growingPlanted = DateUtils.addDays(now, -Int(Double(readyDays) * 0.5))
        let growingAC = ActiveCropEntity(cropId: crop.id, plantedAt: growingPlanted)
        XCTAssertEqual(Selectors.growthStage(ac: growingAC, crop: crop, now: now), .growing)

        let readyPlanted = DateUtils.addDays(now, -readyDays)
        let readyAC = ActiveCropEntity(cropId: crop.id, plantedAt: readyPlanted)
        XCTAssertEqual(Selectors.growthStage(ac: readyAC, crop: crop, now: now), .ready)
    }

    func testTodayTasksOnlySurfacesDueOrOverdueSteps() {
        guard let crop = catalog.crops.first(where: { $0.id == "mini-tomato" }) else {
            return XCTFail("mini-tomato missing")
        }
        // Plant today; step 0 has daysFromStart=0 → due today.
        let ac = ActiveCropEntity(cropId: crop.id, plantedAt: Date())
        let tasks = Selectors.todayTasks(activeCrops: [ac],
                                         cropResolver: { catalog.crop(id: $0) })
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.cropId, crop.id)
    }

    func testScheduleAdjustmentMovesTaskOutOfToday() {
        guard let crop = catalog.crops.first(where: { $0.id == "mini-tomato" }) else {
            return XCTFail("mini-tomato missing")
        }
        let now = DateUtils.startOfDay(Date())
        let ac = ActiveCropEntity(cropId: crop.id, plantedAt: now, scheduleAdjustmentDays: 2)

        let today = Selectors.todayTasks(activeCrops: [ac],
                                         cropResolver: { catalog.crop(id: $0) },
                                         now: now)
        XCTAssertTrue(today.isEmpty)

        let adjustedTarget = DateUtils.addDays(now, 2)
        let weekly = Selectors.weeklyTasks(activeCrops: [ac],
                                           cropResolver: { catalog.crop(id: $0) },
                                           anchor: adjustedTarget)
        XCTAssertEqual(weekly.map[adjustedTarget]?.first?.cropId, crop.id)
    }
}
