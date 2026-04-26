import SwiftUI

struct ShoppingListView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    @State private var optionalOpen = false

    private struct MissingItem: Identifiable, Hashable {
        enum Kind: String { case tool, fertilizer }
        let kind: Kind
        let id: String
        let name: String
        let emoji: String
        let required: Bool
        let cropNames: [String]
    }

    private var missing: [MissingItem] {
        var toolAgg: [String: (required: Bool, crops: Set<String>)] = [:]
        var fertAgg: [String: (required: Bool, crops: Set<String>)] = [:]

        for ac in userStore.activeCrops where ac.status == .growing {
            guard let crop = catalog.crop(id: ac.cropId) else { continue }
            let cropLabel = ac.nickname ?? crop.name

            var toolReq: [String: Bool] = [:]
            for u in crop.starterTools ?? [] {
                toolReq[u.toolId] = (toolReq[u.toolId] ?? false) || u.required
            }
            for s in crop.steps {
                for t in s.tools ?? [] { toolReq[t] = true }
            }
            var fertReq: [String: Bool] = [:]
            for u in crop.starterFertilizers ?? [] {
                fertReq[u.fertilizerId] = (fertReq[u.fertilizerId] ?? false) || u.required
            }
            for s in crop.steps {
                for f in s.fertilizers ?? [] {
                    fertReq[f.fertilizerId] = (fertReq[f.fertilizerId] ?? false) || f.required
                }
            }

            for (id, isReq) in toolReq {
                if userStore.profile.inventory.owns(toolId: id) { continue }
                var entry = toolAgg[id] ?? (false, Set<String>())
                entry.required = entry.required || isReq
                entry.crops.insert(cropLabel)
                toolAgg[id] = entry
            }
            for (id, isReq) in fertReq {
                if userStore.profile.inventory.owns(fertilizerId: id) { continue }
                var entry = fertAgg[id] ?? (false, Set<String>())
                entry.required = entry.required || isReq
                entry.crops.insert(cropLabel)
                fertAgg[id] = entry
            }
        }

        var result: [MissingItem] = []
        for (id, info) in toolAgg {
            if let tool = catalog.tool(id: id) {
                result.append(.init(kind: .tool, id: id, name: tool.name, emoji: tool.emoji,
                                    required: info.required, cropNames: Array(info.crops)))
            }
        }
        for (id, info) in fertAgg {
            if let fert = catalog.fertilizer(id: id) {
                result.append(.init(kind: .fertilizer, id: id, name: fert.name, emoji: fert.emoji,
                                    required: info.required, cropNames: Array(info.crops)))
            }
        }
        return result
    }

    private var hasGrowing: Bool {
        userStore.activeCrops.contains(where: { $0.status == .growing })
    }

    var body: some View {
        if !hasGrowing {
            EmptyView()
        } else {
            let items = missing
            let required = items.filter(\.required)
            let optional = items.filter { !$0.required }
            CardContainer {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        SectionHeader(text: "買い物リスト")
                        Spacer()
                        Text(items.isEmpty ? "揃っています" : "\(items.count)件")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appInkMute)
                    }
                    if items.isEmpty {
                        Text("🎉 育成中の作物のおすすめは、ひと通り揃っています。")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appForestDeep)
                    } else {
                        if !required.isEmpty {
                            VStack(spacing: 6) {
                                ForEach(required) { row($0) }
                            }
                        }
                        if !optional.isEmpty {
                            DisclosureGroup(isExpanded: $optionalOpen) {
                                VStack(spacing: 6) {
                                    ForEach(optional) { row($0) }
                                }
                                .padding(.top, 6)
                            } label: {
                                Text("あると便利(\(optional.count)件)")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appInkSoft)
                            }
                            .tint(Color.appInkSoft)
                            .padding(8)
                            .background(Color.appCanvas.opacity(0.5),
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.appLine, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    private func row(_ item: MissingItem) -> some View {
        HStack(spacing: 8) {
            Text(item.emoji).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.appInk)
                Text("\(item.cropNames.joined(separator: "・")) で使う")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)
            }
            Spacer()
            Button("✓ 持ってる") {
                switch item.kind {
                case .tool: userStore.toggleOwned(kind: .tool, id: item.id)
                case .fertilizer: userStore.toggleOwned(kind: .fertilizer, id: item.id)
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
        .padding(8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.appLine, lineWidth: 1)
        )
    }
}
