import SwiftUI

struct TodayTasksSection: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    private var tasks: [TodayTask] {
        Selectors.todayTasks(activeCrops: userStore.activeCrops,
                             cropResolver: { catalog.crop(id: $0) })
    }

    private var hasGrowing: Bool {
        !Selectors.growingCrops(userStore.activeCrops).isEmpty
    }

    var body: some View {
        if tasks.isEmpty {
            if hasGrowing {
                CardContainer {
                    VStack(spacing: 6) {
                        Text("🌿").font(.system(size: 28))
                        Text("今日は見守りの日です")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.appInk)
                        Text("予定された作業はありません。葉の色や土の様子を、ひと目だけ見てみましょう。")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appInkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        } else {
            CardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionHeader(text: "今日やること")
                        Chip(text: "\(tasks.count)件", variant: .leaf)
                    }
                    VStack(spacing: 8) {
                        ForEach(tasks) { task in
                            NavigationLink(value: CropRoute.detail(cropId: task.cropId, instanceId: task.instanceId)) {
                                TaskRow(task: task)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct TaskRow: View {
    let task: TodayTask

    var body: some View {
        HStack(spacing: 12) {
            Text(task.emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(task.cropName) · \(task.stepName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appInk)
                Text(task.overdueDays > 0 ? "\(task.overdueDays)日前から予定" : "今日の予定")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Color.appInkMute)
        }
        .padding(.vertical, 6)
    }
}

enum CropRoute: Hashable {
    case detail(cropId: String, instanceId: String?)
    case harvest(cropId: String, instanceId: String)
    case select
}

struct CropRouteDestination: View {
    let route: CropRoute

    var body: some View {
        switch route {
        case .detail(let cropId, let instanceId):
            CropDetailView(cropId: cropId, instanceId: instanceId)
        case .harvest(let cropId, let instanceId):
            HarvestView(cropId: cropId, instanceId: instanceId)
        case .select:
            CropSelectView()
        }
    }
}
