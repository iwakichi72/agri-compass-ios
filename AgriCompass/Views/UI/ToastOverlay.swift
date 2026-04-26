import SwiftUI

struct ToastOverlay: View {
    let toasts: [ToastCenter.ToastItem]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(toasts) { item in
                Text(item.message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.appForestDeep.opacity(0.92), in: Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: toasts)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }
}
