import SwiftUI

struct NotificationSettingsView: View {
    @Environment(UserStore.self) private var userStore

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(text: "通知設定")
                Text("※ 現バージョンでは通知の実配信は行いません。設定値の保存のみ可能です。")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)

                Toggle("毎日のリマインダー", isOn: Binding(
                    get: { userStore.profile.notificationSettings.enabled },
                    set: {
                        userStore.profile.notificationSettings.enabled = $0
                        userStore.saveProfile()
                    }
                ))
                Toggle("霜アラート", isOn: Binding(
                    get: { userStore.profile.notificationSettings.frostAlert },
                    set: {
                        userStore.profile.notificationSettings.frostAlert = $0
                        userStore.saveProfile()
                    }
                ))
                Toggle("猛暑アラート", isOn: Binding(
                    get: { userStore.profile.notificationSettings.heatAlert },
                    set: {
                        userStore.profile.notificationSettings.heatAlert = $0
                        userStore.saveProfile()
                    }
                ))
            }
            .tint(Color.appForest)
        }
    }
}
