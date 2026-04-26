import Foundation
import SwiftData

@Model
final class HarvestRecordEntity {
    @Attribute(.unique) var instanceId: String
    var cropId: String
    var plantedAt: Date
    var harvestedAt: Date
    var note: String?

    init(instanceId: String,
         cropId: String,
         plantedAt: Date,
         harvestedAt: Date,
         note: String? = nil) {
        self.instanceId = instanceId
        self.cropId = cropId
        self.plantedAt = plantedAt
        self.harvestedAt = harvestedAt
        self.note = note
    }
}
