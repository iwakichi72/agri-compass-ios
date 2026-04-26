import XCTest
@testable import AgriCompass

final class TipPickerTests: XCTestCase {
    private var catalog: CatalogStore!

    override func setUp() {
        super.setUp()
        catalog = CatalogStore.load()
    }

    func testTipsCatalogLoaded() {
        XCTAssertGreaterThan(catalog.tips.count, 20)
    }

    func testPickerReturnsStableTipForSameDay() {
        let now = Date()
        let a = TipPicker.today(tips: catalog.tips, activeCropIds: [], now: now)
        let b = TipPicker.today(tips: catalog.tips, activeCropIds: [], now: now)
        XCTAssertEqual(a, b)
    }

    func testDayIndexUsesStableSalt() throws {
        var comps = DateComponents()
        comps.calendar = DateUtils.calendar
        comps.year = 2026
        comps.month = 1
        comps.day = 15
        let now = try XCTUnwrap(comps.date)

        XCTAssertEqual(TipPicker.dayIndex(now: now, salt: "mini-tomato,radish"), 34)
    }

    func testActiveCropPreferredWhenMatchingTipExists() throws {
        let tomatoTip = try XCTUnwrap(
            catalog.tips.first(where: { $0.cropTags?.contains("mini-tomato") == true })
        )
        let pool = TipPicker.candidatePool(
            tips: catalog.tips,
            activeCropIds: ["mini-tomato"],
            now: Date()
        )
        let head = Array(pool.prefix(5))
        XCTAssertTrue(head.contains(tomatoTip),
                      "Crop-tagged tips should appear early when that crop is active.")
    }

    func testFallsBackWhenNoMatches() {
        // Bogus crop id with no tags → still returns something.
        let tip = TipPicker.today(tips: catalog.tips, activeCropIds: ["__not-real__"])
        XCTAssertNotNil(tip)
    }
}
