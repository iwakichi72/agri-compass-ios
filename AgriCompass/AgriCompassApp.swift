import SwiftUI
import SwiftData

@main
struct AgriCompassApp: App {
    let modelContainer: ModelContainer
    @State private var catalogStore: CatalogStore
    @State private var userStore: UserStore
    @State private var toastCenter = ToastCenter()

    init() {
        let schemaTypes: [any PersistentModel.Type] = [
            UserProfile.self,
            ActiveCropEntity.self,
            HarvestRecordEntity.self,
            AchievementProgressEntity.self,
            ChallengeProgressEntity.self,
        ]
        let schema = Schema(schemaTypes)

        let container: ModelContainer = {
            // Ensure Application Support exists; SwiftData defaults to a SQLite
            // store there but in some sandboxed test hosts the directory is
            // missing on first launch, which causes CoreData to fail.
            if let appSupport = try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ) {
                _ = appSupport
            }
            do {
                return try ModelContainer(for: schema)
            } catch {
                let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: memConfig)
            }
        }()

        self.modelContainer = container
        self.catalogStore = CatalogStore.load()
        self.userStore = UserStore(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(catalogStore)
                .environment(userStore)
                .environment(toastCenter)
                .preferredColorScheme(.light)
                .tint(.appForest)
                .onAppear {
                    userStore.touchOnLaunch(toast: toastCenter)
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
        .modelContainer(modelContainer)
    }
}
