import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label("カレンダー", systemImage: "calendar")
            }

            NavigationStack {
                MyPageView()
            }
            .tabItem {
                Label("マイページ", systemImage: "person.fill")
            }
        }
    }
}
