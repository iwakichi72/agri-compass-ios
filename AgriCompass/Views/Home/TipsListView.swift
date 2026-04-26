import SwiftUI

enum HomeRoute: Hashable {
    case tipsList
}

struct TipsListView: View {
    @Environment(CatalogStore.self) private var catalog
    @State private var selectedCategory: TipCategory? = nil

    private var filteredTips: [Tip] {
        guard let selectedCategory else { return catalog.tips }
        return catalog.tips.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(label: "すべて",
                                   icon: nil,
                                   isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(TipCategory.allCases, id: \.self) { cat in
                            FilterPill(label: cat.label,
                                       icon: cat.emoji,
                                       isSelected: selectedCategory == cat) {
                                selectedCategory = (selectedCategory == cat) ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                VStack(spacing: 12) {
                    ForEach(filteredTips) { tip in
                        TipCard(tip: tip)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 12)
        }
        .background(Color.appCanvas)
        .navigationTitle("農業豆知識")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FilterPill: View {
    let label: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Text(icon) }
                Text(label)
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : Color.appInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appForestDeep : Color.white, in: Capsule())
            .overlay(
                Capsule().strokeBorder(Color.appLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TipCard: View {
    let tip: Tip

    var body: some View {
        CardContainer {
            HStack(alignment: .top, spacing: 12) {
                Text(tip.category.emoji).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.appInk)
                    Text(tip.body)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appInkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Chip(text: tip.category.label, variant: .leaf)
                        if let seasons = tip.seasons, !seasons.isEmpty {
                            Chip(text: seasons.map(\.label).joined(separator: "・"), variant: .sun)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}
