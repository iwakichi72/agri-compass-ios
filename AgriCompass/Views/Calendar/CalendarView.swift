import SwiftUI

struct CalendarView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    @Environment(ToastCenter.self) private var toastCenter

    private enum CalendarMode: String, CaseIterable, Identifiable {
        case week = "週"
        case month = "月"
        var id: String { rawValue }
    }

    @State private var mode: CalendarMode = .week
    @State private var anchorDate = Date()
    @State private var selectedDate = DateUtils.startOfDay(Date())

    var body: some View {
        let weekly = Selectors.weeklyTasks(activeCrops: userStore.activeCrops,
                                           cropResolver: { catalog.crop(id: $0) },
                                           anchor: anchorDate)
        let monthly = Selectors.monthlyTasks(activeCrops: userStore.activeCrops,
                                             cropResolver: { catalog.crop(id: $0) },
                                             anchor: anchorDate)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("表示", selection: $mode) {
                    ForEach(CalendarMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                calendarControls(days: mode == .week ? weekly.days : monthly.days)

                if mode == .week {
                    weekList(weekly)
                } else {
                    monthGrid(monthly)
                    selectedDayTasks(monthly)
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

    private func calendarControls(days: [Date]) -> some View {
        HStack(spacing: 8) {
            Button {
                move(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mode == .week ? "前の週" : "前の月")

            VStack(alignment: .leading, spacing: 2) {
                Text(calendarTitle(days: days))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.appInk)
                Text(mode == .week ? "週の予定" : "月の予定")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)
            }

            Spacer()

            Button("今日") {
                anchorDate = Date()
                selectedDate = DateUtils.startOfDay(Date())
            }
            .buttonStyle(GhostButtonStyle())

            Button {
                move(1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(mode == .week ? "次の週" : "次の月")
        }
    }

    private func calendarTitle(days: [Date]) -> String {
        switch mode {
        case .week:
            guard let first = days.first, let last = days.last else { return "今週" }
            return "\(DateUtils.formatMD(first))〜\(DateUtils.formatMD(last))"
        case .month:
            return DateUtils.formatYM(anchorDate)
        }
    }

    private func move(_ direction: Int) {
        switch mode {
        case .week:
            anchorDate = DateUtils.addDays(anchorDate, direction * 7)
            selectedDate = DateUtils.startOfDay(anchorDate)
        case .month:
            anchorDate = DateUtils.addMonths(anchorDate, direction)
            selectedDate = DateUtils.startOfMonth(anchorDate)
        }
    }

    private func weekList(_ weekly: (days: [Date], map: [Date: [TodayTask]])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(text: "今週の予定")
            ForEach(weekly.days, id: \.self) { day in
                dayCard(day: day, tasks: weekly.map[day] ?? [])
            }
        }
    }

    private func dayCard(day: Date, tasks: [TodayTask]) -> some View {
        CardContainer(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(DateUtils.formatMD(day)) (\(DateUtils.formatWeekday(day)))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Spacer()
                    if DateUtils.isSameDay(day, Date()) {
                        Chip(text: "今日", variant: .leaf)
                    }
                }
                taskList(tasks)
            }
        }
    }

    private func monthGrid(_ monthly: (days: [Date], map: [Date: [TodayTask]])) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return CardContainer(padding: 12) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { label in
                        Text(label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.appInkMute)
                            .frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(monthly.days, id: \.self) { day in
                        monthDayCell(day: day, tasks: monthly.map[day] ?? [])
                    }
                }
            }
        }
    }

    private func monthDayCell(day: Date, tasks: [TodayTask]) -> some View {
        let selected = DateUtils.isSameDay(day, selectedDate)
        let today = DateUtils.isSameDay(day, Date())
        let inMonth = DateUtils.isSameMonth(day, anchorDate)
        let dayNumber = DateUtils.calendar.component(.day, from: day)

        return Button {
            selectedDate = day
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Text("\(dayNumber)")
                        .font(.system(size: 13, weight: selected || today ? .bold : .semibold))
                        .foregroundStyle(inMonth ? Color.appInk : Color.appInkMute.opacity(0.6))
                    Spacer(minLength: 0)
                    if today {
                        Circle()
                            .fill(Color.appForest)
                            .frame(width: 6, height: 6)
                    }
                }
                Spacer(minLength: 0)
                if !tasks.isEmpty {
                    Text("\(tasks.count)件")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.appForestDeep)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.appLeafPale, in: Capsule())
                }
            }
            .padding(7)
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .topLeading)
            .background(selected ? Color.appLeafPale : Color.appCanvas,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? Color.appForest : Color.appLine, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(DateUtils.formatMD(day)) \(tasks.count)件の予定")
    }

    private func selectedDayTasks(_ monthly: (days: [Date], map: [Date: [TodayTask]])) -> some View {
        let tasks = monthly.map[DateUtils.startOfDay(selectedDate)] ?? []
        return CardContainer(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionHeader(text: "\(DateUtils.formatMD(selectedDate)) (\(DateUtils.formatWeekday(selectedDate)))")
                    Spacer()
                }
                taskList(tasks)
            }
        }
    }

    @ViewBuilder
    private func taskList(_ tasks: [TodayTask]) -> some View {
        if tasks.isEmpty {
            Text("予定なし")
                .font(.system(size: 12))
                .foregroundStyle(Color.appInkMute)
        } else {
            ForEach(tasks) { t in
                HStack(spacing: 8) {
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
                    }
                    .buttonStyle(.plain)

                    if case .step = t.kind {
                        Button("完了") {
                            complete(t)
                        }
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .frame(minHeight: 44)
                        .foregroundStyle(Color.appForestDeep)
                        .background(Color.appLeafPale, in: Capsule())
                        .accessibilityLabel("\(t.cropName)の\(t.stepName)を完了")
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func complete(_ task: TodayTask) {
        userStore.completeStep(instanceId: task.instanceId, stepId: task.stepId)
        userStore.runAchievementChecks(catalog: catalog, toast: toastCenter)
        userStore.runChallengeChecks(catalog: catalog, toast: toastCenter)
        toastCenter.push(message: "\(task.stepName)を完了しました")
    }
}
