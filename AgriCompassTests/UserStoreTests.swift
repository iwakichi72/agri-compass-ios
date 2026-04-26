import SwiftData
import XCTest
@testable import AgriCompass

@MainActor
final class UserStoreTests: XCTestCase {
    private func makeFixture() throws -> (container: ModelContainer, store: UserStore) {
        let schema = Schema([
            UserProfile.self,
            ActiveCropEntity.self,
            HarvestRecordEntity.self,
            AchievementProgressEntity.self,
            ChallengeProgressEntity.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        return (container, UserStore(context: container.mainContext))
    }

    func testUndoStepRewindsToUndoneStepIndex() throws {
        let fixture = try makeFixture()
        let store = fixture.store
        let crop = store.addActiveCrop(cropId: "mini-tomato")

        store.completeStep(instanceId: crop.instanceId, stepId: "step-1")
        store.completeStep(instanceId: crop.instanceId, stepId: "step-2")
        store.completeStep(instanceId: crop.instanceId, stepId: "step-3")

        XCTAssertEqual(store.activeCrops.first?.currentStepIndex, 3)

        store.undoStep(instanceId: crop.instanceId, stepId: "step-1", stepIndex: 0)

        let updated = try XCTUnwrap(store.activeCrops.first)
        XCTAssertFalse(updated.completedStepIds.contains("step-1"))
        XCTAssertEqual(updated.currentStepIndex, 0)
    }

    func testRecordWhyReadOnlyCountsNewKeys() throws {
        let fixture = try makeFixture()
        let store = fixture.store

        XCTAssertTrue(store.recordWhyRead(key: "mini-tomato-seed"))
        XCTAssertFalse(store.recordWhyRead(key: "mini-tomato-seed"))

        XCTAssertEqual(store.profile.stats.whyReadCount, 1)
        XCTAssertEqual(store.profile.stats.whyReadIds, ["mini-tomato-seed"])
    }

    func testScheduleShiftCanBeResetByPlantingDateEdit() throws {
        let fixture = try makeFixture()
        let store = fixture.store
        let plantedAt = DateUtils.startOfDay(DateUtils.addDays(Date(), -3))
        let crop = store.addActiveCrop(cropId: "mini-tomato", plantedAt: plantedAt)

        store.shiftSchedule(instanceId: crop.instanceId, byDays: 4)
        XCTAssertEqual(store.activeCrops.first?.scheduleAdjustmentDays, 4)

        let correctedPlantingDate = DateUtils.addDays(Date(), -1)
        store.updatePlantedAt(instanceId: crop.instanceId, plantedAt: correctedPlantingDate)

        let updated = try XCTUnwrap(store.activeCrops.first)
        XCTAssertEqual(updated.scheduleAdjustmentDays, 0)
        XCTAssertEqual(DateUtils.diffDays(updated.plantedAt, DateUtils.startOfDay(correctedPlantingDate)), 0)
    }
}
