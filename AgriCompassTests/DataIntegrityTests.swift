import XCTest
@testable import AgriCompass

final class DataIntegrityTests: XCTestCase {
    func testCatalogLoads() throws {
        let bundle = Bundle(for: type(of: self))
            .url(forResource: "crops", withExtension: "json") != nil
            ? Bundle(for: type(of: self))
            : Bundle.main
        let store = CatalogStore.load(bundle: bundle)
        XCTAssertGreaterThan(store.crops.count, 0)
        XCTAssertGreaterThan(store.tools.count, 0)
        XCTAssertGreaterThan(store.fertilizers.count, 0)
        XCTAssertGreaterThan(store.achievements.count, 0)
        XCTAssertGreaterThan(store.challenges.count, 0)
        // mini-tomato is the canonical first sample
        XCTAssertNotNil(store.crop(id: "mini-tomato"))
    }
}
