import SwiftUI

struct CatalogListView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    @State private var seasonFilter: Season? = Season.of()
    @State private var difficultyFilter: Difficulty? = nil
    @State private var spaceFilter: RequiredSpace? = nil

    private var results: [Crop] {
        catalog.filterCrops(.init(
            region: userStore.profile.selectedRegion,
            season: seasonFilter,
            difficulty: difficultyFilter,
            requiredSpace: spaceFilter,
            search: nil
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                filterRow(label: "季節",
                          options: [(nil, "すべて")] + Season.allCases.map { (Optional($0), $0.label) },
                          selection: $seasonFilter)
                filterRow(label: "難易度",
                          options: [(nil, "すべて")] + Difficulty.allCases.map { (Optional($0), $0.label) },
                          selection: $difficultyFilter)
                filterRow(label: "スペース",
                          options: [(nil, "すべて")] + RequiredSpace.allCases.map { (Optional($0), $0.label) },
                          selection: $spaceFilter)

                Text("\(results.count)件")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)

                if results.isEmpty {
                    CardContainer {
                        Text("条件に合うものがありません。絞り込みを変えてみてください。")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appInkSoft)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(results) { crop in
                            CropCardRow(crop: crop)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.appCanvas)
    }

    @ViewBuilder
    private func filterRow<T: Hashable>(label: String,
                                        options: [(T?, String)],
                                        selection: Binding<T?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.appInkMute)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(options.enumerated()), id: \.offset) { _, item in
                        Button {
                            selection.wrappedValue = item.0
                        } label: {
                            Text(item.1)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .foregroundStyle(selection.wrappedValue == item.0 ? Color.white : Color.appInkSoft)
                                .background(
                                    Capsule().fill(selection.wrappedValue == item.0
                                                   ? Color.appForest
                                                   : Color.white)
                                )
                                .overlay(
                                    Capsule().strokeBorder(Color.appLine, lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }
}

struct CropCardRow: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ToastCenter.self) private var toastCenter
    @Environment(CatalogStore.self) private var catalog
    let crop: Crop

    var body: some View {
        NavigationLink(value: CropRoute.detail(cropId: crop.id, instanceId: nil)) {
            CardContainer(padding: 12) {
                HStack(spacing: 12) {
                    Text(crop.emoji).font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(crop.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.appInk)
                        Text(crop.summary)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appInkSoft)
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            Chip(text: crop.difficulty.label, variant: .leaf)
                            Chip(text: crop.requiredSpace.label, variant: .mute)
                            ForEach(crop.seasons, id: \.rawValue) { s in
                                Chip(text: s.label, variant: .sun)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
