import SwiftUI

struct WeatherBannerView: View {
    @Environment(UserStore.self) private var userStore

    private var forecast: WeatherForecast? {
        guard let region = userStore.profile.selectedRegion else { return nil }
        return WeatherService.mockForecast(region: region)
    }

    var body: some View {
        if let forecast {
            let advice = WeatherService.deriveAdvice(forecast: forecast)
            CardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(forecast.today.condition.icon).font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(forecast.today.tempMax)° / \(forecast.today.tempMin)°")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.appInk)
                            Text(forecast.region.label)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appInkMute)
                        }
                        Spacer()
                        toneBadge(advice.tone)
                    }
                    Divider()
                    Text(advice.headline)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Text(advice.body)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appInkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .onAppear { userStore.incrementWeatherCheck() }
        }
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
}
