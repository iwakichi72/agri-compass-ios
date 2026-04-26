import SwiftUI

struct CardContainer<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.appLine, lineWidth: 1)
            )
            .shadow(color: Color.appForestDeep.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

struct SectionHeader: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.appInkSoft)
                .textCase(.uppercase)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appInkMute)
            }
        }
    }
}
