import SwiftUI

struct MyPageView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RegionSettingRow()
                ChallengesSection()
                ShoppingListView()
                BadgeGridView()
                HarvestShelfView()
                InventoryEditorView()
                NotificationSettingsView()
                resetCard
            }
            .padding(16)
        }
        .background(Color.appCanvas)
        .navigationTitle("マイページ")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CropRoute.self) { route in
            CropRouteDestination(route: route)
        }
        .navigationDestination(for: ChallengeRoute.self) { route in
            switch route {
            case .detail(let id):
                ChallengeDetailView(challengeId: id)
            }
        }
    }

    private var resetCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(text: "データ")
                Button("すべてリセット") {
                    userStore.resetAll()
                }
                .buttonStyle(GhostButtonStyle())
                .foregroundStyle(Color.appEarth)
            }
        }
    }
}

enum ChallengeRoute: Hashable {
    case detail(challengeId: String)
}

struct RegionSettingRow: View {
    @Environment(UserStore.self) private var userStore

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(text: "地域")
                Picker("地域", selection: Binding(
                    get: { userStore.profile.selectedRegion ?? .kanto },
                    set: { userStore.setRegion($0) }
                )) {
                    ForEach(Region.allCases, id: \.rawValue) { r in
                        Text(r.label).tag(r)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.appForestDeep)
            }
        }
    }
}
