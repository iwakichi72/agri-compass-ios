import SwiftUI

struct CalendarView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    var body: some View {
        let weekly = Selectors.weeklyTasks(activeCrops: userStore.activeCrops,
                                           cropResolver: { catalog.crop(id: $0) })
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(text: "今週の予定")
                ForEach(Array(weekly.days.enumerated()), id: \.offset) { _, day in
                    let tasks = weekly.map[day] ?? []
                    CardContainer(padding: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(DateUtils.formatMD(day)) (\(DateUtils.formatWeekday(day)))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.appInk)
                                Spacer()
                                Text(DateUtils.isSameDay(day, Date()) ? "今日" : "")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.appForestDeep)
                            }
                            if tasks.isEmpty {
                                Text("予定なし")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appInkMute)
                            } else {
                                ForEach(tasks) { t in
                                    NavigationLink(value: CropRoute.detail(cropId: t.cropId, instanceId: t.instanceId)) {
                                        HStack(spacing: 8) {
                                            Text(t.emoji).font(.system(size: 22))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(t.cropName) · \(t.stepName)")
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(Color.appInk)
                                                if t.overdueDays > 0 {
                                                    Text("\(t.overdueDays)日前から予定")
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(Color.appEarth)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right").foregroundStyle(Color.appInkMute)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.appCanvas)
        .navigationTitle("カレンダー")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CropRoute.self) { route in
            CropRouteDestination(route: route)
        }
    }
}
