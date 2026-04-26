import SwiftUI

struct InventoryEditorView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(CatalogStore.self) private var catalog

    @State private var open = false

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionHeader(text: "持ち物")
                    Spacer()
                    Button(open ? "閉じる" : "編集") { open.toggle() }
                        .buttonStyle(GhostButtonStyle())
                }
                if open {
                    Text("道具").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.appInkMute)
                    let toolGroups = Dictionary(grouping: catalog.tools) { $0.category }
                    ForEach(ToolCategory.allCases, id: \.self) { cat in
                        if let list = toolGroups[cat], !list.isEmpty {
                            Text(cat.label)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appInkMute)
                            VStack(spacing: 4) {
                                ForEach(list) { tool in
                                    inventoryRow(emoji: tool.emoji, name: tool.name,
                                                 owned: userStore.profile.inventory.owns(toolId: tool.id)) {
                                        userStore.toggleOwned(kind: .tool, id: tool.id)
                                    }
                                }
                            }
                        }
                    }
                    Divider()
                    Text("肥料").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.appInkMute)
                    VStack(spacing: 4) {
                        ForEach(catalog.fertilizers) { fert in
                            inventoryRow(emoji: fert.emoji, name: fert.name,
                                         owned: userStore.profile.inventory.owns(fertilizerId: fert.id)) {
                                userStore.toggleOwned(kind: .fertilizer, id: fert.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private func inventoryRow(emoji: String, name: String, owned: Bool, toggle: @escaping () -> Void) -> some View {
        HStack {
            OwnedToggle(owned: owned, onToggle: toggle)
            Text(emoji)
            Text(name).font(.system(size: 13)).foregroundStyle(Color.appInk)
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

extension ToolCategory: CaseIterable {
    public static var allCases: [ToolCategory] {
        [.container, .support, .cutting, .watering, .soil, .cover, .other]
    }
}
