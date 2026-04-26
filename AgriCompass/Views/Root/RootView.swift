import SwiftUI

struct RootView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(ToastCenter.self) private var toastCenter

    var body: some View {
        ZStack {
            Color.appCanvas.ignoresSafeArea()
            if !userStore.profile.onboardingCompleted {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
            ToastOverlay(toasts: toastCenter.items)
        }
    }
}
