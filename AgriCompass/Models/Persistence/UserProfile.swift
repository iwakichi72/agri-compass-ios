import Foundation
import SwiftData

struct InventoryData: Codable, Hashable, Sendable {
    var tools: [String: Bool] = [:]
    var fertilizers: [String: Bool] = [:]

    func owns(toolId: String) -> Bool { tools[toolId] == true }
    func owns(fertilizerId: String) -> Bool { fertilizers[fertilizerId] == true }
}

struct StatsData: Codable, Hashable, Sendable {
    var weatherChecksCount: Int = 0
    var whyReadCount: Int = 0
    var firstLaunchAt: Date = Date()
    var lastRainyVisit: Date?
    var whyReadIds: [String] = []
    var lastVisitDate: String?
    var streakDays: Int = 0
    var maxStreakDays: Int = 0
}

struct NotificationSettingsData: Codable, Hashable, Sendable {
    var enabled: Bool = false
    var permissionState: String = "default"
    var reminderTime: String = "08:00"
    var frostAlert: Bool = true
    var heatAlert: Bool = true
}

@Model
final class UserProfile {
    var schemaVersion: Int = 3
    var selectedRegionRaw: String?
    var onboardingCompleted: Bool = false
    var inventory: InventoryData = InventoryData()
    var stats: StatsData = StatsData()
    var notificationSettings: NotificationSettingsData = NotificationSettingsData()
    var installPromptDismissedAt: Date?

    init() {}

    var selectedRegion: Region? {
        get { selectedRegionRaw.flatMap(Region.init(rawValue:)) }
        set { selectedRegionRaw = newValue?.rawValue }
    }
}
