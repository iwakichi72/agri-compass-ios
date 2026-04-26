import SwiftUI

struct WeatherBannerView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    @Environment(ToastCenter.self) private var toastCenter

    private var forecast: WeatherForecast? {
        guard let region = userStore.profile.selectedRegion else { return nil }
        return WeatherService.mockForecast(region: region)
    }

    private var wateringSummary: WateringSummary? {
        guard let forecast else { return nil }
        let summary = WateringAdvisor.summary(
            activeCrops: userStore.activeCrops,
            forecast: forecast,
            cropResolver: { catalog.crop(id: $0) }
        )
        return summary.hasAnyCrops ? summary : nil
    }

    var body: some View {
        if let forecast {
            let advice = WeatherService.deriveAdvice(forecast: forecast)
            CardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    headerRow(forecast: forecast, tone: advice.tone)
                    Divider()
                    adviceBlock(advice)
                    Divider()
                    forecastStrip(forecast: forecast)
                    if let summary = wateringSummary {
                        Divider()
                        wateringBlock(summary: summary)
                    }
                }
            }
            .onAppear { userStore.incrementWeatherCheck() }
        }
    }

    // MARK: - Header

    private func headerRow(forecast: WeatherForecast, tone: WeatherAdviceData.Tone) -> some View {
        HStack(spacing: 10) {
            Text(forecast.today.condition.icon).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(forecast.today.tempMax)° / \(forecast.today.tempMin)°")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.appInk)
                HStack(spacing: 6) {
                    Text(forecast.region.label)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appInkMute)
                    metricChip(icon: "💧", text: "\(forecast.today.precipitationMm)mm")
                    metricChip(icon: "💨", text: "\(forecast.today.windMps)m/s")
                }
            }
            Spacer()
            toneBadge(tone)
        }
    }

    private func metricChip(icon: String, text: String) -> some View {
        HStack(spacing: 2) {
            Text(icon)
            Text(text)
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(Color.appInkSoft)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.appLeafPale.opacity(0.5), in: Capsule())
    }

    private func toneBadge(_ tone: WeatherAdviceData.Tone) -> some View {
        let label: String
        let variant: ChipVariant
        switch tone {
        case .info: label = "info"; variant = .leaf
        case .warn: label = "注意"; variant = .sun
        case .alert: label = "アラート"; variant = .earth
        }
        return Chip(text: label, variant: variant)
    }

    // MARK: - Advice

    private func adviceBlock(_ advice: WeatherAdviceData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(advice.headline)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.appInk)
            Text(advice.body)
                .font(.system(size: 12))
                .foregroundStyle(Color.appInkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Forecast strip

    private func forecastStrip(forecast: WeatherForecast) -> some View {
        let days: [(label: String, day: WeatherDay)] =
            [("今日", forecast.today)] + forecast.next.prefix(3).map { (DateUtils.formatWeekday($0.date), $0) }
        return HStack(spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, item in
                forecastCell(label: item.label, day: item.day)
            }
        }
    }

    private func forecastCell(label: String, day: WeatherDay) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.appInkMute)
            Text(day.condition.icon).font(.system(size: 22))
            Text("\(day.tempMax)°/\(day.tempMin)°")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.appInk)
            if day.precipitationMm > 0 {
                Text("\(day.precipitationMm)mm")
                    .font(.system(size: 9))
                    .foregroundStyle(Color.appInkMute)
            } else {
                Text(" ").font(.system(size: 9))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.appCanvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Watering rundown

    private func wateringBlock(summary: WateringSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("💧 水やり目安")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.appInkSoft)
                Spacer()
                wateringSummaryChip(summary: summary)
            }
            VStack(spacing: 6) {
                ForEach(summary.dueToday + summary.upcoming + summary.resting) { status in
                    wateringRow(status)
                }
            }
        }
    }

    private func wateringSummaryChip(summary: WateringSummary) -> some View {
        if !summary.dueToday.isEmpty {
            return Chip(text: "今日 \(summary.dueToday.count)株", variant: .leaf)
        } else if !summary.upcoming.isEmpty {
            return Chip(text: "明日以降", variant: .sun)
        } else {
            return Chip(text: "お休み", variant: .mute)
        }
    }

    private func wateringRow(_ status: CropWateringStatus) -> some View {
        HStack(spacing: 8) {
            Text(status.emoji).font(.system(size: 18))
            VStack(alignment: .leading, spacing: 1) {
                Text(status.cropName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appInk)
                    .lineLimit(1)
                Text(wateringDetail(status))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.appInkMute)
            }
            Spacer()
            wateringAction(status)
        }
    }

    private func wateringDetail(_ status: CropWateringStatus) -> String {
        if let last = status.lastWateredAt {
            let days = DateUtils.diffDays(last, Date())
            let lastLabel = days == 0 ? "今日あげた" : "\(days)日前にあげた"
            return "\(status.recommendation.headline) ・ \(lastLabel)"
        }
        return status.recommendation.headline
    }

    @ViewBuilder
    private func wateringAction(_ status: CropWateringStatus) -> some View {
        switch status.recommendation {
        case .dueToday, .neverWatered:
            Button {
                userStore.recordWatering(instanceId: status.instanceId)
                toastCenter.push(message: "\(status.cropName)に水をあげました 💧")
            } label: {
                Text("あげた")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.appForestDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(minHeight: 32)
                    .background(Color.appLeafPale, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(status.cropName)に水やり完了")
        case .dueIn:
            Chip(text: "明日", variant: .sun)
        case .skipRain:
            Chip(text: "雨", variant: .mute, icon: "☔")
        case .skipRecent:
            Chip(text: "湿潤", variant: .mute)
        }
    }
}
