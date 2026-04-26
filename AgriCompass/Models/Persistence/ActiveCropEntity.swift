import Foundation
import SwiftData

@Model
final class ActiveCropEntity {
    @Attribute(.unique) var instanceId: String
    var cropId: String
    var plantedAt: Date
    var scheduleAdjustmentDays: Int = 0
    var currentStepIndex: Int
    var completedStepIds: [String]
    var nickname: String?
    var statusRaw: String
    var harvestedAt: Date?

    init(instanceId: String = UUID().uuidString,
         cropId: String,
         plantedAt: Date = Date(),
         scheduleAdjustmentDays: Int = 0,
         currentStepIndex: Int = 0,
         completedStepIds: [String] = [],
         nickname: String? = nil,
         status: CropStatus = .growing,
         harvestedAt: Date? = nil) {
        self.instanceId = instanceId
        self.cropId = cropId
        self.plantedAt = plantedAt
        self.scheduleAdjustmentDays = scheduleAdjustmentDays
        self.currentStepIndex = currentStepIndex
        self.completedStepIds = completedStepIds
        self.nickname = nickname
        self.statusRaw = status.rawValue
        self.harvestedAt = harvestedAt
    }

    var status: CropStatus {
        get { CropStatus(rawValue: statusRaw) ?? .growing }
        set { statusRaw = newValue.rawValue }
    }
}
