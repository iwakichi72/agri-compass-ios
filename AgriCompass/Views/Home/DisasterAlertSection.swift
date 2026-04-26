import SwiftUI

struct DisasterAlertSection: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    @State private var expanded: Set<String> = []

    private var alerts: [DisasterAlert] {
        guard let region = userStore.profile.selectedRegion else { return [] }
        let forecast = WeatherService.mockForecast(region: region)
        return DisasterAdvisor.alerts(
            forecast: forecast,
            activeCrops: userStore.activeCrops,
            cropResolver: { catalog.crop(id: $0) }
        )
    }

    var body: some View {
        if !alerts.isEmpty {
            VStack(spacing: 12) {
                ForEach(alerts) { alert in
                    AlertCard(alert: alert,
                              isExpanded: expanded.contains(alert.id),
                              toggle: { toggle(alert.id) })
                }
            }
        }
    }

    private func toggle(_ id: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expanded.contains(id) { expanded.remove(id) } else { expanded.insert(id) }
        }
    }
}

private struct AlertCard: View {
    let alert: DisasterAlert
    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Button(action: toggle) {
                    HStack(spacing: 12) {
                        Text(alert.emoji).font(.system(size: 30))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Chip(text: "\(alert.leadLabel) ・ \(alert.severity.label)",
                                     variant: alert.severity == .warning ? .earth : .sun)
                            }
                            Text(alert.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.appInk)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Color.appInkMute)
                    }
                }
                .buttonStyle(.plain)

                Text(alert.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appInkSoft)
                    .fixedSize(horizontal: false, vertical: true)

                if isExpanded {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("おすすめ対策")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.appInkSoft)
                        ForEach(Array(alert.actions.enumerated()), id: \.offset) { _, action in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.square")
                                    .foregroundStyle(Color.appForestDeep)
                                Text(action)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if !alert.affectedCropNames.isEmpty {
                            Divider()
                            Text("特に気をつけたい作物")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.appInkSoft)
                            FlowingChips(items: alert.affectedCropNames)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(alert.severity == .warning
                      ? Color.appEarthSoft.opacity(0.35)
                      : Color.appSunSoft.opacity(0.35))
        )
    }
}

private struct FlowingChips: View {
    let items: [String]

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 80), spacing: 6)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { name in
                Chip(text: name, variant: .leaf)
            }
        }
    }
}
