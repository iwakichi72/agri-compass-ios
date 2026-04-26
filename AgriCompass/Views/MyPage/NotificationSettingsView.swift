import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(UserStore.self) private var userStore

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(text: "通知設定")
                Text(permissionMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)

                Toggle("毎日のリマインダー", isOn: Binding(
                    get: { userStore.profile.notificationSettings.enabled },
                    set: {
                        userStore.profile.notificationSettings.enabled = $0
                        userStore.saveProfile()
                        syncNotifications()
                    }
                ))
                if userStore.profile.notificationSettings.enabled {
                    DatePicker("通知時刻", selection: reminderTimeBinding, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .font(.system(size: 13))
                }
                Toggle("霜アラート", isOn: Binding(
                    get: { userStore.profile.notificationSettings.frostAlert },
                    set: {
                        userStore.profile.notificationSettings.frostAlert = $0
                        userStore.saveProfile()
                        syncNotifications()
                    }
                ))
                .disabled(!userStore.profile.notificationSettings.enabled)
                Toggle("猛暑アラート", isOn: Binding(
                    get: { userStore.profile.notificationSettings.heatAlert },
                    set: {
                        userStore.profile.notificationSettings.heatAlert = $0
                        userStore.saveProfile()
                        syncNotifications()
                    }
                ))
                .disabled(!userStore.profile.notificationSettings.enabled)
            }
            .tint(Color.appForest)
        }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { NotificationScheduler.date(from: userStore.profile.notificationSettings.reminderTime) },
            set: {
                userStore.profile.notificationSettings.reminderTime = NotificationScheduler.timeString(from: $0)
                userStore.saveProfile()
                syncNotifications()
            }
        )
    }

    private var permissionMessage: String {
        switch userStore.profile.notificationSettings.permissionState {
        case "authorized":
            return "作業リマインダーと天候アラートを配信できます。"
        case "denied":
            return "通知が許可されていません。iOSの設定から許可してください。"
        default:
            return "オンにすると、作業予定と天候注意を通知します。"
        }
    }

    private func syncNotifications() {
        let settings = userStore.profile.notificationSettings
        let region = userStore.profile.selectedRegion
        Task {
            let state = await NotificationScheduler.sync(settings: settings, region: region)
            await MainActor.run {
                userStore.profile.notificationSettings.permissionState = state
                userStore.saveProfile()
            }
        }
    }
}

enum NotificationScheduler {
    private static let dailyReminderId = "agri-compass.daily-reminder"
    private static let frostAlertId = "agri-compass.weather.frost"
    private static let heatAlertId = "agri-compass.weather.heat"

    static func sync(settings: NotificationSettingsData, region: Region?) async -> String {
        let center = UNUserNotificationCenter.current()
        let identifiers = [dailyReminderId, frostAlertId, heatAlertId]

        guard settings.enabled else {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            return "default"
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                center.removePendingNotificationRequests(withIdentifiers: identifiers)
                return "denied"
            }

            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            scheduleDailyReminder(settings: settings, center: center)
            if let region {
                scheduleWeatherAlerts(settings: settings, region: region, center: center)
            }
            return "authorized"
        } catch {
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
            return "denied"
        }
    }

    static func date(from timeString: String) -> Date {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        let hour = parts.first ?? 8
        let minute = parts.dropFirst().first ?? 0
        var comps = DateUtils.calendar.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour
        comps.minute = minute
        return DateUtils.calendar.date(from: comps) ?? Date()
    }

    static func timeString(from date: Date) -> String {
        let hour = DateUtils.calendar.component(.hour, from: date)
        let minute = DateUtils.calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }

    private static func scheduleDailyReminder(settings: NotificationSettingsData,
                                              center: UNUserNotificationCenter) {
        let parts = settings.reminderTime.split(separator: ":").compactMap { Int($0) }
        var comps = DateComponents()
        comps.hour = parts.first ?? 8
        comps.minute = parts.dropFirst().first ?? 0

        let content = UNMutableNotificationContent()
        content.title = "今日の野菜チェック"
        content.body = "作業予定と天気の注意を確認しましょう。"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderId, content: content, trigger: trigger)
        center.add(request)
    }

    private static func scheduleWeatherAlerts(settings: NotificationSettingsData,
                                              region: Region,
                                              center: UNUserNotificationCenter) {
        let forecast = WeatherService.mockForecast(region: region)
        let days = [forecast.today] + forecast.next

        if settings.frostAlert,
           let risk = days.first(where: { $0.tempMin <= 3 }) {
            scheduleOneTime(
                id: frostAlertId,
                title: "霜に注意",
                body: "朝の冷え込みが予想されます。寒さに弱い作物は覆いを確認しましょう。",
                date: nextTriggerDate(on: risk.date, hour: 18, minute: 0),
                center: center
            )
        }

        if settings.heatAlert,
           let risk = days.first(where: { $0.tempMax >= 33 }) {
            scheduleOneTime(
                id: heatAlertId,
                title: "猛暑に注意",
                body: "土が乾きやすい日です。朝の水やりと日よけを確認しましょう。",
                date: nextTriggerDate(on: risk.date, hour: 7, minute: 0),
                center: center
            )
        }
    }

    private static func scheduleOneTime(id: String,
                                        title: String,
                                        body: String,
                                        date: Date,
                                        center: UNUserNotificationCenter) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let comps = DateUtils.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private static func nextTriggerDate(on day: Date, hour: Int, minute: Int) -> Date {
        var comps = DateUtils.calendar.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour
        comps.minute = minute
        let candidate = DateUtils.calendar.date(from: comps) ?? DateUtils.addDays(Date(), 1)
        return candidate > Date() ? candidate : DateUtils.addDays(candidate, 1)
    }
}
