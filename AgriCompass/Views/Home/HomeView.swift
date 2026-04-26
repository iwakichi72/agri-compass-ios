import SwiftUI

struct HomeView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WeatherBannerView()
                DisasterAlertSection()
                TodayTasksSection()
                FarmOverviewSection()
                DailyTipSection()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.appCanvas)
        .navigationTitle("アグリコンパス")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CropRoute.self) { route in
            CropRouteDestination(route: route)
        }
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .tipsList:
                TipsListView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                BrandLogoView(variant: .navigation)
            }
            if let region = userStore.profile.selectedRegion {
                ToolbarItem(placement: .topBarTrailing) {
                    Chip(text: region.label, variant: .leaf, icon: "📍")
                }
            }
        }
    }
}
