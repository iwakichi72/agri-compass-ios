import SwiftUI

struct PreparationKitView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    let crop: Crop

    @State private var optionalToolsOpen = false
    @State private var optionalFertsOpen = false

    private var tools: [ToolUsage] { crop.starterTools ?? [] }
    private var ferts: [FertilizerUsage] { crop.starterFertilizers ?? [] }

    private var recommendedTools: [ToolUsage] { tools.filter(\.required) }
    private var optionalTools: [ToolUsage] { tools.filter { !$0.required } }
    private var recommendedFerts: [FertilizerUsage] { ferts.filter(\.required) }
    private var optionalFerts: [FertilizerUsage] { ferts.filter { !$0.required } }

    private var ownedRecommended: Int {
        recommendedTools.filter { userStore.profile.inventory.owns(toolId: $0.toolId) }.count
        + recommendedFerts.filter { userStore.profile.inventory.owns(fertilizerId: $0.fertilizerId) }.count
    }
    private var totalRecommended: Int { recommendedTools.count + recommendedFerts.count }

    var body: some View {
        if tools.isEmpty && ferts.isEmpty {
            EmptyView()
        } else {
            CardContainer {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("用意するもの", systemImage: "wrench.and.screwdriver.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.appInk)
                        Spacer()
                        if totalRecommended > 0 {
                            if ownedRecommended == totalRecommended {
                                Text("✓ ひと通り揃いました")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.appForestDeep)
                            } else {
                                Text("\(ownedRecommended) / \(totalRecommended)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.appInkMute)
                            }
                        }
                    }
                    if !tools.isEmpty {
                        VStack(spacing: 6) {
                            ForEach(recommendedTools, id: \.toolId) { ToolRow(usage: $0) }
                            if !optionalTools.isEmpty {
                                disclosureBlock(label: "あると便利(\(optionalTools.count)件)",
                                                isOpen: $optionalToolsOpen) {
                                    VStack(spacing: 6) {
                                        ForEach(optionalTools, id: \.toolId) { ToolRow(usage: $0) }
                                    }
                                }
                            }
                        }
                    }
                    if !ferts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("使う肥料")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.appInkMute)
                            ForEach(recommendedFerts, id: \.fertilizerId) { FertilizerRow(usage: $0) }
                            if !optionalFerts.isEmpty {
                                disclosureBlock(label: "あると便利な肥料(\(optionalFerts.count)件)",
                                                isOpen: $optionalFertsOpen) {
                                    VStack(spacing: 6) {
                                        ForEach(optionalFerts, id: \.fertilizerId) { FertilizerRow(usage: $0) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func disclosureBlock<Content: View>(label: String, isOpen: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            Button {
                isOpen.wrappedValue.toggle()
            } label: {
                HStack {
                    Text(label).font(.system(size: 12)).foregroundStyle(Color.appInkSoft)
                    Spacer()
                    Text(isOpen.wrappedValue ? "▾" : "▸").foregroundStyle(Color.appInkSoft)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            if isOpen.wrappedValue {
                content().padding(.horizontal, 8).padding(.bottom, 8)
            }
        }
        .background(Color.appCanvas.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.appLine, lineWidth: 1)
        )
    }
}

private struct ToolRow: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    let usage: ToolUsage
    @State private var open = false

    var body: some View {
        if let tool = catalog.tool(id: usage.toolId) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    OwnedToggle(owned: userStore.profile.inventory.owns(toolId: tool.id)) {
                        userStore.toggleOwned(kind: .tool, id: tool.id)
                    }
                    Text(tool.emoji).font(.system(size: 22))
                    Button {
                        open.toggle()
                    } label: {
                        Text(tool.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                if open {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tool.description).font(.system(size: 12)).foregroundStyle(Color.appInkSoft)
                        if let buyHint = tool.buyHint {
                            Text("💡 \(buyHint)").font(.system(size: 11)).foregroundStyle(Color.appInkMute)
                        }
                        if let note = usage.note {
                            Text("📝 \(note)").font(.system(size: 11)).foregroundStyle(Color.appForestDeep)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.appLine, lineWidth: 1)
            )
        }
    }
}

private struct FertilizerRow: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog
    let usage: FertilizerUsage
    @State private var open = false

    var body: some View {
        if let fert = catalog.fertilizer(id: usage.fertilizerId) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    OwnedToggle(owned: userStore.profile.inventory.owns(fertilizerId: fert.id)) {
                        userStore.toggleOwned(kind: .fertilizer, id: fert.id)
                    }
                    Text(fert.emoji).font(.system(size: 22))
                    Button {
                        open.toggle()
                    } label: {
                        Text(fert.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appInk)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                if open {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fert.description).font(.system(size: 12)).foregroundStyle(Color.appInkSoft)
                        Text("🌿 \(fert.applyHint)").font(.system(size: 11)).foregroundStyle(Color.appForestDeep)
                        if let buyHint = fert.buyHint {
                            Text("💡 \(buyHint)").font(.system(size: 11)).foregroundStyle(Color.appInkMute)
                        }
                        if let amount = usage.amount {
                            Text("📝 \(amount)").font(.system(size: 11)).foregroundStyle(Color.appForestDeep)
                        }
                        if let note = usage.note {
                            Text("📝 \(note)").font(.system(size: 11)).foregroundStyle(Color.appForestDeep)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.appLine, lineWidth: 1)
            )
        }
    }
}

struct OwnedToggle: View {
    let owned: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                Circle()
                    .fill(owned ? Color.appForest : Color.white)
                    .frame(width: 24, height: 24)
                Circle()
                    .strokeBorder(owned ? Color.appForest : Color.appLine, lineWidth: 2)
                    .frame(width: 24, height: 24)
                if owned {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
